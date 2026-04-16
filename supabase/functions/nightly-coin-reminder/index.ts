import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';

serve(async (req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Get all FCM tokens with their timezone
    const { data: fcmTokens, error: fcmError } = await supabase
      .from('fcm_tokens')
      .select('user_id, token, timezone');

    if (fcmError) throw new Error(`FCM load error: ${fcmError.message}`);

    const now = new Date();
    const targetedUsers: string[] = [];
    const targetedTokensMap = new Map<string, string>();

    // Step 1: Filter users where their local timezone hour is 21 (9:00 PM)
    for (const row of fcmTokens || []) {
      const tz = row.timezone || 'UTC';
      let hourStr;
      
      try {
        const parts = new Intl.DateTimeFormat('en-US', {
          timeZone: tz,
          hour: 'numeric',
          hour12: false,
        }).formatToParts(now);
        hourStr = parts.find(p => p.type === 'hour')?.value;
      } catch (e) {
        // Fallback to UTC if timezone is invalid
        const parts = new Intl.DateTimeFormat('en-US', {
          timeZone: 'UTC',
          hour: 'numeric',
          hour12: false,
        }).formatToParts(now);
        hourStr = parts.find(p => p.type === 'hour')?.value;
      }

      if (hourStr && parseInt(hourStr, 10) === 21) {
        targetedUsers.push(row.user_id);
        targetedTokensMap.set(row.user_id, row.token);
      }
    }

    if (targetedUsers.length === 0) {
      return new Response(JSON.stringify({ message: 'No users at 21:00 in their timezone right now.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Step 2: Check if these users have a "validate" record in `user_activities` within the last 3 hours
    const threeHoursAgo = new Date(now.getTime() - 3 * 60 * 60 * 1000).toISOString();
    
    const { data: recentValidates, error: validateError } = await supabase
      .from('user_activities')
      .select('user_id')
      .in('user_id', targetedUsers)
      .eq('activity_type', 'validate')
      .gte('created_at', threeHoursAgo);

    if (validateError) throw new Error(`Validate activities load error: ${validateError.message}`);

    const usersWhoValidated = new Set((recentValidates || []).map(r => r.user_id));

    // Gather final list of tokens to message
    const tokensToSend: string[] = [];
    for (const userId of targetedUsers) {
      if (!usersWhoValidated.has(userId)) {
        tokensToSend.push(targetedTokensMap.get(userId)!);
      }
    }

    if (tokensToSend.length === 0) {
      return new Response(JSON.stringify({ message: 'All targeted users have already validated their coins.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Step 3: Build Google OAuth2 Token utilizing Service Account Secrets
    const projectId = Deno.env.get('FCM_PROJECT_ID');
    const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL');
    const privateKeyStr = Deno.env.get('FCM_PRIVATE_KEY');

    if (!projectId || !clientEmail || !privateKeyStr) {
      throw new Error('FCM configs missing (FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY)');
    }

    const privateKey = privateKeyStr.replace(/\\n/g, '\n');
    const privateKeyObj = await importPKCS8(privateKey, 'RS256');
    
    const jwt = await new SignJWT({
      iss: clientEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
    })
      .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
      .setIssuedAt()
      .setExpirationTime('1h')
      .sign(privateKeyObj);

    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    });

    const tokenDataRes = await tokenResponse.json();
    if (!tokenResponse.ok) {
      throw new Error(`Google Auth error: ${tokenDataRes.error_description || tokenDataRes.error}`);
    }

    const accessToken = tokenDataRes.access_token;

    // Step 4: Send Firebase Notifications in bulk loop
    const results = [];
    for (const token of tokensToSend) {
      const fcmPayload = {
        message: {
          token: token,
          notification: {
            title: '🌙 Nightly Check-in',
            body: "Don't forget to validate today's coins! Claim them now before they expire at midnight."
          },
          android: {
            priority: 'high',
            notification: { sound: 'default' }
          }
        }
      };

      const fcmResponse = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(fcmPayload),
        }
      );

      const resJson = await fcmResponse.json();
      results.push({ token, success: fcmResponse.ok, result: resJson });
    }

    return new Response(JSON.stringify({ 
      success: true, 
      sent_count: tokensToSend.length, 
      results 
    }), {
      headers: { 'Content-Type': 'application/json' },
    });

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
