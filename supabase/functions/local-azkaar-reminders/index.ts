import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';
import { getFcmCreds } from '../_shared/fcm.ts';
import { pickVariant } from '../_shared/variants.ts';

serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const now = new Date();

    // ── 1. Load all FCM tokens with timezone (+ user locale for variant lookup) ──
    const { data: fcmTokens, error: fcmError } = await supabase
      .from('fcm_tokens')
      .select('user_id, token, timezone, app_locale');

    if (fcmError) throw new Error(`FCM load error: ${fcmError.message}`);
    if (!fcmTokens || fcmTokens.length === 0) {
      return new Response(JSON.stringify({ message: 'No FCM tokens found in database.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // ── 2. Bucket users by local hour (8 = morning, 17 = evening) ─────────────
    const morningUsers: string[] = [];
    const eveningUsers: string[] = [];
    const userMap = new Map<string, { tokens: string[]; locale: string }>();

    for (const row of fcmTokens) {
      const tz = row.timezone || 'UTC';
      let hour = -1;
      try {
        const parts = new Intl.DateTimeFormat('en-US', {
          timeZone: tz, hour: 'numeric', hour12: false,
        }).formatToParts(now);
        hour = parseInt(parts.find(p => p.type === 'hour')?.value ?? '-1', 10);
      } catch {
        // Invalid timezone — use UTC
        const parts = new Intl.DateTimeFormat('en-US', {
          timeZone: 'UTC', hour: 'numeric', hour12: false,
        }).formatToParts(now);
        hour = parseInt(parts.find(p => p.type === 'hour')?.value ?? '-1', 10);
      }

      if (!userMap.has(row.user_id)) {
        userMap.set(row.user_id, { tokens: [], locale: row.app_locale ?? 'en' });
      }
      userMap.get(row.user_id)!.tokens.push(row.token);

      if (hour === 8)  morningUsers.push(row.user_id);
      if (hour === 17) eveningUsers.push(row.user_id);
    }

    if (morningUsers.length === 0 && eveningUsers.length === 0) {
      return new Response(JSON.stringify({
        message: 'No users at 08:00 or 17:00 right now.',
        server_utc_hour: now.getUTCHours(),
      }), { headers: { 'Content-Type': 'application/json' } });
    }

    // ── 3. Dedup — skip users already notified today ───────────────────────────
    const todayStart = new Date(now);
    todayStart.setUTCHours(0, 0, 0, 0);

    const { data: alreadySent } = await supabase
      .from('notification_log')
      .select('user_id, notification_type')
      .in('notification_type', ['morning_azkaar', 'evening_azkaar'])
      .gte('sent_at', todayStart.toISOString());

    const sentMorning = new Set<string>();
    const sentEvening = new Set<string>();
    for (const r of alreadySent || []) {
      if (r.notification_type === 'morning_azkaar') sentMorning.add(r.user_id);
      if (r.notification_type === 'evening_azkaar') sentEvening.add(r.user_id);
    }

    const dedupedMorning = morningUsers.filter(uid => !sentMorning.has(uid));
    const dedupedEvening = eveningUsers.filter(uid => !sentEvening.has(uid));

    if (dedupedMorning.length === 0 && dedupedEvening.length === 0) {
      return new Response(JSON.stringify({ message: 'All targeted users already notified today.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // ── 4. Get Google OAuth2 access token ─────────────────────────────────────
    const { projectId, clientEmail, privateKey } = getFcmCreds();
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

    // ── 5. Send notifications ──────────────────────────────────────────────────
    const results: object[] = [];

    const sendNotification = async (
      userId: string,
      tokens: string[],
      locale: string,
      fallbackTitle: string,
      fallbackBody: string,
      logType: string,
    ) => {
      const nid   = crypto.randomUUID();
      const fallbackRoute = logType === 'morning_azkaar' ? 'morning' : 'evening';
      const variant = await pickVariant(
        supabase,
        logType,
        locale,
        {},
        {
          title: fallbackTitle,
          body: fallbackBody,
          route: fallbackRoute,
        },
      );

      let anySuccess = false;
      for (const token of tokens) {
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
              },
            }),
          }
        );
        const resJson = await res.json();
        results.push({ userId, type: logType, success: res.ok, result: resJson });
        if (res.ok) anySuccess = true;
      }

      if (anySuccess) {
        try {
          await supabase.from('notification_log').insert({
            user_id: userId,
            notification_type: logType,
            notification_id: nid,
            title: variant.title,
            body: variant.body,
            route: variant.route,
            variant_id: variant.id || null,
            sent_at: now.toISOString(),
          });
        } catch (_) {}
      }
    };

    for (const uid of dedupedMorning) {
      const entry = userMap.get(uid)!;
      await sendNotification(
        uid, entry.tokens, entry.locale,
        '🌅 Morning Azkaar',
        'Start your day with blessings. Tap to read your morning Azkaar.',
        'morning_azkaar',
      );
    }

    for (const uid of dedupedEvening) {
      const entry = userMap.get(uid)!;
      await sendNotification(
        uid, entry.tokens, entry.locale,
        '🌇 Evening Azkaar',
        'Protect yourself for the night. Tap to read your evening Azkaar.',
        'evening_azkaar',
      );
    }

    return new Response(JSON.stringify({
      success: true,
      server_utc_hour: now.getUTCHours(),
      morning_sent: dedupedMorning.length,
      evening_sent: dedupedEvening.length,
      results,
    }), { headers: { 'Content-Type': 'application/json' } });

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
