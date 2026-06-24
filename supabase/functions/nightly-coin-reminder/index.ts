import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';
import { getFcmCreds } from '../_shared/fcm.ts';
import { pickVariant } from '../_shared/variants.ts';

serve(async (req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Get all FCM tokens with their timezone (+ user locale for variant lookup)
    const { data: fcmTokens, error: fcmError } = await supabase
      .from('fcm_tokens')
      .select('user_id, token, timezone, app_locale');

    if (fcmError) throw new Error(`FCM load error: ${fcmError.message}`);

    const now = new Date();
    const targetedUsers: string[] = [];
    const targetedTokensMap = new Map<string, { token: string; locale: string }>();

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
        targetedTokensMap.set(row.user_id, {
          token: row.token,
          locale: row.app_locale ?? 'en',
        });
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

    // Gather final list of users to message
    const usersToSend: { userId: string; token: string; locale: string }[] = [];
    for (const userId of targetedUsers) {
      if (!usersWhoValidated.has(userId)) {
        const entry = targetedTokensMap.get(userId)!;
        usersToSend.push({ userId, token: entry.token, locale: entry.locale });
      }
    }

    if (usersToSend.length === 0) {
      return new Response(JSON.stringify({ message: 'All targeted users have already validated their coins.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Step 2.5: Deduplicate — skip users who already received this notification today
    // Check notification_log table (create if needed) to avoid duplicate sends
    const todayStart = new Date(now);
    todayStart.setUTCHours(0, 0, 0, 0);

    // Ensure the dedup table exists
    await supabase.rpc('ensure_notification_log_exists').catch(() => {});

    const { data: alreadySent } = await supabase
      .from('notification_log')
      .select('user_id')
      .eq('notification_type', 'nightly_checkin')
      .gte('sent_at', todayStart.toISOString());

    const alreadySentSet = new Set((alreadySent || []).map((r: any) => r.user_id));

    // Filter out users who already got today's notification
    const dedupedUsers: { userId: string; token: string; locale: string }[] = [];
    for (const u of usersToSend) {
      if (!alreadySentSet.has(u.userId)) {
        dedupedUsers.push(u);
      }
    }

    if (dedupedUsers.length === 0) {
      return new Response(JSON.stringify({ message: 'All targeted users already notified or validated.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Step 3: Build Google OAuth2 Token utilizing Service Account Secrets
    const { projectId, clientEmail, privateKey } = getFcmCreds();
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
    for (const u of dedupedUsers) {
      const nid = crypto.randomUUID();
      const variant = await pickVariant(
        supabase,
        'nightly_checkin',
        u.locale,
        {},
        {
          title: '🌙 Points expiring at midnight!',
          body: "You have unclaimed points from today's deeds. Seal the Day now or they'll expire!",
          route: '',
        },
      );

      const fcmPayload = {
        message: {
          token: u.token,
          notification: {
            title: variant.title,
            body: variant.body,
            ...(variant.imageUrl ? { image: variant.imageUrl } : {}),
          },
          data: { route: variant.route ?? '', nid },
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              ...(variant.imageUrl ? { image: variant.imageUrl } : {}),
            },
          },
          apns: {
            payload: { aps: { sound: 'default', 'mutable-content': 1 } },
            ...(variant.imageUrl ? { fcm_options: { image: variant.imageUrl } } : {}),
          },
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
      results.push({ token: u.token, success: fcmResponse.ok, result: resJson });

      // Log successful sends to prevent duplicates
      if (fcmResponse.ok) {
        await supabase.from('notification_log').insert({
          user_id: u.userId,
          notification_type: 'nightly_checkin',
          notification_id: nid,
          title: variant.title,
          body: variant.body,
          route: variant.route,
          variant_id: variant.id || null,
          sent_at: now.toISOString(),
        }).catch(() => {});
      }
    }

    return new Response(JSON.stringify({
      success: true,
      sent_count: dedupedUsers.length,
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
