import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';

serve(async (req: Request) => {
  try {
    // 1. Initialize Supabase Admin Client
    // We use the SERVICE_ROLE_KEY because cron jobs are entirely backend processes 
    // and we need to bypass row-level security (RLS) to read all user activity logs.
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 2. Identify Users who have NOT logged in today
    const startOfToday = new Date();
    startOfToday.setUTCHours(0, 0, 0, 0);

    // Get all FCM tokens
    const { data: fcmTokens, error: fcmError } = await supabase
      .from('fcm_tokens')
      .select('user_id, token');

    if (fcmError) throw new Error(`FCM load error: ${fcmError.message}`);

    // Get all user analytics (for last_active_at)
    const { data: analytics, error: analyticsError } = await supabase
      .from('user_analytics')
      .select('user_id, last_active_at');

    if (analyticsError) throw new Error(`Analytics load error: ${analyticsError.message}`);

    const lastActiveMap = new Map<string, string>();
    for (const a of analytics || []) {
      lastActiveMap.set(a.user_id, a.last_active_at);
    }

    // Filter tokens for users who haven't opened the app today
    const tokensToSend: string[] = [];
    for (const row of fcmTokens || []) {
      const lastActiveStr = lastActiveMap.get(row.user_id);
      
      if (!lastActiveStr) {
        // No analytics record implies they haven't been active, send reminder
        tokensToSend.push(row.token);
      } else {
        const lastActiveDate = new Date(lastActiveStr);
        if (lastActiveDate < startOfToday) {
          // Last logged in BEFORE today 00:00 UTC
          tokensToSend.push(row.token);
        }
      }
    }

    if (tokensToSend.length === 0) {
      return new Response(JSON.stringify({ message: 'All users with tokens have already logged in today.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // 3. Build Google OAuth2 Token utilizing Service Account Secrets
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

    // 4. Send Firebase Notifications in bulk loop
    const results = [];
    for (const token of tokensToSend) {
      const fcmPayload = {
        message: {
          token: token,
          notification: {
            title: 'Evening Azkaar',
            body: 'Take a few minutes to complete your evening Azkaar and keep your streak alive!'
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
