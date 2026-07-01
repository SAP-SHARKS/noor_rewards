// akhirah-milestone-celebration — celebratory push when a user's
// `profiles.total_xp` crosses one of the configured "akhirah" milestones.
// Each milestone fires AT MOST ONCE per user ever.
//
// Schedule: daily cron. Function gates on:
//   • profiles.total_xp >= first milestone (1000)
//   • notifications_paused === false (via filterPausedUsers)
//   • dailyPushCapReached() === false
//   • dedup: notification_log row of type 'akhirah_milestone' whose
//     title/body already references the reached milestone number → skip

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';
import { getFcmCreds } from '../_shared/fcm.ts';
import { pickVariant } from '../_shared/variants.ts';
import { filterPausedUsers } from '../_shared/disengagement.ts';
import { dailyPushCapReached } from '../_shared/daily_cap.ts';

const MILESTONES = [
  1000, 5000, 10000, 25000, 50000, 100000, 250000, 500000, 1000000,
];

// Pretty-print a milestone number for the push body: 1,000 / 10,000 / 1M etc.
function _fmt(n: number): string {
  if (n >= 1_000_000) {
    const m = n / 1_000_000;
    return (m % 1 === 0 ? m.toFixed(0) : m.toFixed(1)) + 'M';
  }
  return n.toLocaleString('en-US');
}

serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );
    const now = new Date();

    // 1. Profiles that have crossed at least the first milestone.
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, total_xp')
      .gte('total_xp', MILESTONES[0]);
    if (!profiles || profiles.length === 0) {
      return new Response(JSON.stringify({ message: 'No profiles at milestone' }));
    }

    // Map user_id -> highest milestone reached.
    const reachedByUser = new Map<string, number>();
    for (const p of profiles as any[]) {
      const xp: number = p.total_xp ?? 0;
      const reached = MILESTONES.filter((m) => xp >= m).pop();
      if (reached) reachedByUser.set(p.id, reached);
    }
    if (reachedByUser.size === 0) {
      return new Response(JSON.stringify({ message: 'No milestone matches' }));
    }
    const userIds = [...reachedByUser.keys()];

    // 2. FCM tokens for those users + paused-user filter.
    const { data: fcmTokensRaw } = await supabase
      .from('fcm_tokens')
      .select('user_id, token, timezone, app_locale')
      .in('user_id', userIds);
    const fcmTokens = await filterPausedUsers(supabase, fcmTokensRaw ?? []);
    if (fcmTokens.length === 0) {
      return new Response(JSON.stringify({ message: 'No tokens' }));
    }

    const byUser = new Map<string, { tokens: string[]; locale: string }>();
    for (const row of fcmTokens) {
      if (!byUser.has(row.user_id)) {
        byUser.set(row.user_id, { tokens: [], locale: row.app_locale ?? 'en' });
      }
      byUser.get(row.user_id)!.tokens.push(row.token);
    }

    // 3. Bulk-fetch every prior akhirah_milestone log row for the candidates,
    // then per-user check if the EXACT milestone has already been celebrated.
    const { data: priorLogs } = await supabase
      .from('notification_log')
      .select('user_id, title, body')
      .eq('notification_type', 'akhirah_milestone')
      .in('user_id', [...byUser.keys()]);
    const priorByUser = new Map<string, { title: string; body: string }[]>();
    for (const row of (priorLogs ?? []) as any[]) {
      const arr = priorByUser.get(row.user_id) ?? [];
      arr.push({ title: row.title ?? '', body: row.body ?? '' });
      priorByUser.set(row.user_id, arr);
    }

    const accessToken = await getAccessToken();
    const { projectId } = getFcmCreds();
    let sent = 0;

    for (const [userId, entry] of byUser) {
      const milestone = reachedByUser.get(userId);
      if (!milestone) continue;

      // 4. Dedup — has any prior akhirah_milestone push for this user
      // already mentioned this milestone number?
      const milestoneStr = _fmt(milestone);
      const milestoneRaw = String(milestone);
      const already = (priorByUser.get(userId) ?? []).some((r) => {
        const hay = `${r.title} ${r.body}`;
        return hay.includes(milestoneStr) || hay.includes(milestoneRaw);
      });
      if (already) continue;

      if (await dailyPushCapReached(supabase, userId)) continue;

      const nid = crypto.randomUUID();
      const variant = await pickVariant(
        supabase,
        'akhirah_milestone',
        entry.locale,
        { milestone: milestoneStr },
        {
          title: `${milestoneStr} XP for your akhirah`,
          body:
            `Subhan Allah — you've earned ${milestoneStr} XP. Every point ` +
            'is a deed planted for the next life. Keep going.',
          route: 'home',
        },
      );

      let anySuccess = false;
      for (const token of entry.tokens) {
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
                data: { route: variant.route ?? 'home', nid },
                android: {
                  priority: 'high',
                  notification: {
                    sound: 'default',
                    ...(variant.imageUrl ? { image: variant.imageUrl } : {}),
                  },
                },
                apns: {
                  payload: { aps: { sound: 'default', 'mutable-content': 1 } },
                  ...(variant.imageUrl
                    ? { fcm_options: { image: variant.imageUrl } }
                    : {}),
                },
              },
            }),
          },
        );
        if (res.ok) anySuccess = true;
      }

      if (anySuccess) {
        sent++;
        await supabase
          .from('notification_log')
          .insert({
            user_id: userId,
            notification_type: 'akhirah_milestone',
            notification_id: nid,
            title: variant.title,
            body: variant.body,
            route: variant.route ?? 'home',
            variant_id: variant.id || null,
            sent_at: now.toISOString(),
          })
          .catch(() => {});
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
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuedAt()
    .setExpirationTime('1h')
    .sign(key);

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error_description || data.error);
  return data.access_token;
}
