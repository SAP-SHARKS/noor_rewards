// streak-at-risk — Send notification to users with 3+ day streaks who haven't been active today
// Schedule: Cron every hour, targets users whose local time is ~19:00 (7 PM)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';
import { getFcmCreds } from '../_shared/fcm.ts';
import { pickVariant } from '../_shared/variants.ts';
import { filterPausedUsers } from '../_shared/disengagement.ts';
import { dailyPushCapReached } from '../_shared/daily_cap.ts';

serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 1. Get all FCM tokens (+ user locale for variant lookup)
    const { data: fcmTokensRaw, error: fcmErr } = await supabase
      .from('fcm_tokens')
      .select('user_id, token, timezone, app_locale');
    if (fcmErr) throw new Error(fcmErr.message);
    const fcmTokens = await filterPausedUsers(supabase, fcmTokensRaw ?? []);

    const now = new Date();

    // 2. Filter users whose local time is 19:00 (evening reminder)
    const eveningUsers = new Map<string, { token: string; locale: string }>();
    for (const row of fcmTokens) {
      const tz = row.timezone || 'UTC';
      try {
        const parts = new Intl.DateTimeFormat('en-US', {
          timeZone: tz, hour: 'numeric', hour12: false,
        }).formatToParts(now);
        const hour = parseInt(parts.find(p => p.type === 'hour')?.value ?? '0', 10);
        if (hour === 19) {
          eveningUsers.set(row.user_id, {
            token: row.token,
            locale: row.app_locale ?? 'en',
          });
        }
      } catch { /* skip invalid tz */ }
    }

    if (eveningUsers.size === 0) {
      return new Response(JSON.stringify({ message: 'No users at 19:00' }));
    }

    // 3. Get users with 3+ day streaks (any type)
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, login_streak, dhikr_streak, quran_streak')
      .in('id', [...eveningUsers.keys()]);

    const streakUsers: { userId: string; token: string; locale: string; streak: number; type: string }[] = [];
    for (const p of profiles || []) {
      const best = Math.max(p.login_streak ?? 0, p.dhikr_streak ?? 0, p.quran_streak ?? 0);
      if (best < 3) continue;

      const type = (p.quran_streak ?? 0) >= (p.dhikr_streak ?? 0) ? 'Quran' : 'Dhikr';
      const entry = eveningUsers.get(p.id)!;
      streakUsers.push({
        userId: p.id,
        token: entry.token,
        locale: entry.locale,
        streak: best,
        type,
      });
    }

    // 4. Check who was already active today
    const todayStart = new Date(now);
    todayStart.setUTCHours(0, 0, 0, 0);

    const { data: todayActive } = await supabase
      .from('user_activities')
      .select('user_id')
      .in('user_id', streakUsers.map(u => u.userId))
      .gte('created_at', todayStart.toISOString());

    const activeSet = new Set((todayActive || []).map((r: any) => r.user_id));

    // 5. Dedup via notification_log
    const { data: alreadySent } = await supabase
      .from('notification_log')
      .select('user_id')
      .eq('notification_type', 'streak_at_risk')
      .gte('sent_at', todayStart.toISOString());

    const sentSet = new Set((alreadySent || []).map((r: any) => r.user_id));

    const toNotify = streakUsers.filter(
      u => !activeSet.has(u.userId) && !sentSet.has(u.userId)
    );

    if (toNotify.length === 0) {
      return new Response(JSON.stringify({ message: 'No at-risk users to notify' }));
    }

    // 6. Send FCM
    const accessToken = await getAccessToken();
    const { projectId } = getFcmCreds();
    let sent = 0;

    for (const u of toNotify) {
      if (await dailyPushCapReached(supabase, u.userId)) continue;
      const nid = crypto.randomUUID();
      const variant = await pickVariant(
        supabase,
        'streak_at_risk',
        u.locale,
        { streak: u.streak, type: u.type },
        {
          title: "Don't break your streak!",
          body: `You've been consistent for ${u.streak} days with ${u.type}. Open now to keep it alive!`,
          route: u.type === 'Quran' ? 'quran' : 'dhikr',
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
          notification_type: 'streak_at_risk',
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
