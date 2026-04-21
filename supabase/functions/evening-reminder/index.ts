import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';

// ── Evening Reminder ── fires hourly, targets users at local 20:00 (8 PM)
// Deduped via notification_log — max ONE send per user per day.
// Distinct from local-azkaar-reminders (which targets 17:00).

const TARGET_HOUR = 20; // 8 PM in the user's local timezone
const LOG_TYPE    = 'evening_reminder';

serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const now = new Date();

    // ── 1. Load all FCM tokens with timezone ─────────────────────────────────
    const { data: fcmTokens, error: fcmError } = await supabase
      .from('fcm_tokens')
      .select('user_id, token, timezone');

    if (fcmError) throw new Error(`FCM load error: ${fcmError.message}`);
    if (!fcmTokens || fcmTokens.length === 0) {
      return new Response(JSON.stringify({ message: 'No FCM tokens found.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // ── 2. Filter users whose local hour == TARGET_HOUR ──────────────────────
    const targetUsers: string[] = [];
    const tokensMap = new Map<string, string>();

    for (const row of fcmTokens) {
      const tz = row.timezone || 'UTC';
      let hour = -1;
      try {
        const parts = new Intl.DateTimeFormat('en-US', {
          timeZone: tz, hour: 'numeric', hour12: false,
        }).formatToParts(now);
        hour = parseInt(parts.find(p => p.type === 'hour')?.value ?? '-1', 10);
      } catch {
        const parts = new Intl.DateTimeFormat('en-US', {
          timeZone: 'UTC', hour: 'numeric', hour12: false,
        }).formatToParts(now);
        hour = parseInt(parts.find(p => p.type === 'hour')?.value ?? '-1', 10);
      }

      tokensMap.set(row.user_id, row.token);
      if (hour === TARGET_HOUR) targetUsers.push(row.user_id);
    }

    if (targetUsers.length === 0) {
      return new Response(JSON.stringify({
        message: `No users at ${TARGET_HOUR}:00 local time right now.`,
        server_utc_hour: now.getUTCHours(),
      }), { headers: { 'Content-Type': 'application/json' } });
    }

    // ── 3. Dedup — skip users already notified today ──────────────────────────
    const todayStart = new Date(now);
    todayStart.setUTCHours(0, 0, 0, 0);

    const { data: alreadySent } = await supabase
      .from('notification_log')
      .select('user_id')
      .eq('notification_type', LOG_TYPE)
      .gte('sent_at', todayStart.toISOString());

    const alreadySentSet = new Set<string>((alreadySent || []).map((r: any) => r.user_id));

    const dedupedUsers = targetUsers.filter(uid => !alreadySentSet.has(uid));

    if (dedupedUsers.length === 0) {
      return new Response(JSON.stringify({
        message: 'All targeted users already received this notification today.',
      }), { headers: { 'Content-Type': 'application/json' } });
    }

    // ── 4. Build Google OAuth2 access token ───────────────────────────────────
    const projectId    = Deno.env.get('FCM_PROJECT_ID');
    const clientEmail  = Deno.env.get('FCM_CLIENT_EMAIL');
    const privateKeyStr = Deno.env.get('FCM_PRIVATE_KEY');

    if (!projectId || !clientEmail || !privateKeyStr) {
      throw new Error('FCM secrets missing: FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY');
    }

    const privateKey    = privateKeyStr.replace(/\\n/g, '\n');
    const privateKeyObj = await importPKCS8(privateKey, 'RS256');

    const jwt = await new SignJWT({
      iss:   clientEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud:   'https://oauth2.googleapis.com/token',
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

    const tokenData = await tokenResponse.json();
    if (!tokenResponse.ok) {
      throw new Error(`Google OAuth error: ${tokenData.error_description ?? tokenData.error}`);
    }
    const accessToken = tokenData.access_token;

    // ── 5. Send notifications + log to prevent duplicates ────────────────────
    const results: object[] = [];

    for (const userId of dedupedUsers) {
      const token = tokensMap.get(userId)!;

      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token,
              notification: {
                title: '🌙 Evening Azkaar',
                body:  'Take a few minutes to complete your evening Azkaar and keep your streak alive!',
              },
              data: { route: 'evening' },
              android: { priority: 'high', notification: { sound: 'default' } },
              apns:    { payload: { aps: { sound: 'default' } } },
            },
          }),
        }
      );

      const resJson = await res.json();
      results.push({ userId, success: res.ok, result: resJson });

      // Log BEFORE checking ok — even a partial failure should guard against retries
      if (res.ok) {
        await supabase.from('notification_log').insert({
          user_id:           userId,
          notification_type: LOG_TYPE,
          sent_at:           now.toISOString(),
        }).catch(() => {});
      }
    }

    return new Response(JSON.stringify({
      success:           true,
      server_utc_hour:   now.getUTCHours(),
      target_local_hour: TARGET_HOUR,
      sent_count:        dedupedUsers.length,
      results,
    }), { headers: { 'Content-Type': 'application/json' } });

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
