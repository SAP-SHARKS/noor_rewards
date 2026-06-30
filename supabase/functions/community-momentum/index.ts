// community-momentum — Social proof nudge: "X believers reading today, join them"
// Schedule: Cron every hour, targets users whose local time is ~9:00 AM and haven't opened today

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';
import { getFcmCreds } from '../_shared/fcm.ts';
import { pickVariant } from '../_shared/variants.ts';
import { filterPausedUsers } from '../_shared/disengagement.ts';

serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const now = new Date();

    // 1. Get yesterday's global stats for the social proof number
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    const yStr = yesterday.toISOString().substring(0, 10);

    const { data: globalRow } = await supabase
      .from('global_daily_stats')
      .select('active_readers, total_ayahs, total_users')
      .eq('stat_date', yStr)
      .maybeSingle();

    const readers = globalRow?.active_readers ?? globalRow?.total_users ?? 0;
    const ayahs = globalRow?.total_ayahs ?? 0;

    if (readers < 5) {
      return new Response(JSON.stringify({ message: 'Not enough community activity yet' }));
    }

    // 2. Get FCM tokens, filter for 9 AM local
    const { data: fcmTokensRaw } = await supabase
      .from('fcm_tokens')
      .select('user_id, token, timezone, app_locale');
    const fcmTokens = await filterPausedUsers(supabase, fcmTokensRaw ?? []);

    const morningUsers = new Map<string, { token: string; locale: string }>();
    for (const row of fcmTokens) {
      const tz = row.timezone || 'UTC';
      try {
        const parts = new Intl.DateTimeFormat('en-US', {
          timeZone: tz, hour: 'numeric', hour12: false,
        }).formatToParts(now);
        const hour = parseInt(parts.find(p => p.type === 'hour')?.value ?? '0', 10);
        if (hour === 9) {
          morningUsers.set(row.user_id, {
            token: row.token,
            locale: row.app_locale ?? 'en',
          });
        }
      } catch { /* skip */ }
    }

    if (morningUsers.size === 0) {
      return new Response(JSON.stringify({ message: 'No users at 9 AM' }));
    }

    // 3. Check who already opened the app today
    const todayStart = new Date(now);
    todayStart.setUTCHours(0, 0, 0, 0);

    const { data: todayActive } = await supabase
      .from('user_activities')
      .select('user_id')
      .in('user_id', [...morningUsers.keys()])
      .gte('created_at', todayStart.toISOString());

    const activeSet = new Set((todayActive || []).map((r: any) => r.user_id));

    // 4. Dedup
    const { data: alreadySent } = await supabase
      .from('notification_log')
      .select('user_id')
      .eq('notification_type', 'community_momentum')
      .gte('sent_at', todayStart.toISOString());

    const sentSet = new Set((alreadySent || []).map((r: any) => r.user_id));

    const toNotify: { userId: string; token: string; locale: string }[] = [];
    for (const [userId, entry] of morningUsers) {
      if (!activeSet.has(userId) && !sentSet.has(userId)) {
        toNotify.push({ userId, token: entry.token, locale: entry.locale });
      }
    }

    if (toNotify.length === 0) {
      return new Response(JSON.stringify({ message: 'All morning users already active or notified' }));
    }

    // 5. Send
    const accessToken = await getAccessToken();
    const { projectId } = getFcmCreds();
    let sent = 0;

    for (const u of toNotify) {
      const nid = crypto.randomUUID();
      const variant = await pickVariant(
        supabase,
        'community_momentum',
        u.locale,
        { count: readers, ayahs },
        {
          title: `${readers} believers read Quran yesterday`,
          body: `They read ${ayahs} ayahs together. Join them today — your morning adhkar is waiting.`,
          route: 'morning',
        },
      );

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
            },
          }),
        }
      );

      if (res.ok) {
        sent++;
        await supabase.from('notification_log').insert({
          user_id: u.userId,
          notification_type: 'community_momentum',
          notification_id: nid,
          title: variant.title,
          body: variant.body,
          route: variant.route,
          variant_id: variant.id || null,
          sent_at: now.toISOString(),
        }).catch(() => {});
      }
    }

    return new Response(JSON.stringify({ success: true, sent }));
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});

async function getAccessToken(): Promise<string> {
  const { clientEmail, privateKey } = getFcmCreds();
  const key = await importPKCS8(privateKey, 'RS256');
  const jwt = await new SignJWT({
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
  }).setProtectedHeader({ alg: 'RS256', typ: 'JWT' }).setIssuedAt().setExpirationTime('1h').sign(key);

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error_description || data.error);
  return data.access_token;
}
