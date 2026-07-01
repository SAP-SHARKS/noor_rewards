// streak-milestone-celebration — celebratory push when a user's
// best streak (login / dhikr / quran) reaches one of the configured
// milestones. Each (user × streak_type × milestone) combo fires at most
// once ever.
//
// Schedule: daily cron. Function gates on:
//   • profiles.best_login_streak / best_dhikr_streak / best_quran_streak
//     matches a value in STREAK_MILESTONES exactly
//   • notifications_paused === false (via filterPausedUsers)
//   • dailyPushCapReached() === false
//   • dedup: notification_log row of type 'streak_milestone' whose
//     title/body already references "<n> days" for that user → skip

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';
import { getFcmCreds } from '../_shared/fcm.ts';
import { pickVariant } from '../_shared/variants.ts';
import { filterPausedUsers } from '../_shared/disengagement.ts';
import { dailyPushCapReached } from '../_shared/daily_cap.ts';

const STREAK_MILESTONES = [3, 7, 14, 30, 60, 100];

interface StreakHit {
  userId: string;
  type: 'login' | 'dhikr' | 'quran';
  milestone: number;
}

function streakTypeLabel(t: 'login' | 'dhikr' | 'quran'): string {
  switch (t) {
    case 'login': return 'daily login';
    case 'dhikr': return 'dhikr';
    case 'quran': return 'Quran reading';
  }
}

serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );
    const now = new Date();

    // 1. Pull profiles with any best_*_streak that exactly hits a milestone.
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, best_login_streak, best_dhikr_streak, best_quran_streak');
    if (!profiles || profiles.length === 0) {
      return new Response(JSON.stringify({ message: 'No profiles' }));
    }

    const hits: StreakHit[] = [];
    const milestoneSet = new Set<number>(STREAK_MILESTONES);
    for (const p of profiles as any[]) {
      const login = Number(p.best_login_streak ?? 0);
      const dhikr = Number(p.best_dhikr_streak ?? 0);
      const quran = Number(p.best_quran_streak ?? 0);
      if (milestoneSet.has(login)) hits.push({ userId: p.id, type: 'login', milestone: login });
      if (milestoneSet.has(dhikr)) hits.push({ userId: p.id, type: 'dhikr', milestone: dhikr });
      if (milestoneSet.has(quran)) hits.push({ userId: p.id, type: 'quran', milestone: quran });
    }
    if (hits.length === 0) {
      return new Response(JSON.stringify({ message: 'No streak milestones hit' }));
    }

    const hitUserIds = Array.from(new Set(hits.map((h) => h.userId)));

    // 2. FCM tokens + paused-user filter.
    const { data: fcmTokensRaw } = await supabase
      .from('fcm_tokens')
      .select('user_id, token, timezone, app_locale')
      .in('user_id', hitUserIds);
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

    // 3. Bulk-fetch every prior streak_milestone log row for candidates,
    // so we can check per-(user, milestone) whether it was already celebrated.
    const { data: priorLogs } = await supabase
      .from('notification_log')
      .select('user_id, title, body')
      .eq('notification_type', 'streak_milestone')
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

    for (const hit of hits) {
      const entry = byUser.get(hit.userId);
      if (!entry) continue;

      // 4. Dedup — has this user already been congratulated for this
      // streak milestone (any type)? We match on "<n> days" appearing in
      // the title or body of an earlier streak_milestone log row.
      const needle = `${hit.milestone} days`;
      const already = (priorByUser.get(hit.userId) ?? []).some((r) => {
        const hay = `${r.title} ${r.body}`.toLowerCase();
        return hay.includes(needle.toLowerCase());
      });
      if (already) continue;

      if (await dailyPushCapReached(supabase, hit.userId)) continue;

      const label = streakTypeLabel(hit.type);
      const nid = crypto.randomUUID();
      const variant = await pickVariant(
        supabase,
        'streak_milestone',
        entry.locale,
        { streak: String(hit.milestone), streakType: label },
        {
          title: `${hit.milestone} days of ${label}`,
          body:
            `Ma sha Allah — ${hit.milestone} days of ${label} in a row. ` +
            'Consistency is what Allah loves most. Keep the chain alive.',
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
        // Update in-memory prior cache so a second matching hit for the same
        // user (same milestone, different streak_type) doesn't double-send
        // within this same run.
        const arr = priorByUser.get(hit.userId) ?? [];
        arr.push({ title: variant.title, body: variant.body });
        priorByUser.set(hit.userId, arr);

        await supabase
          .from('notification_log')
          .insert({
            user_id: hit.userId,
            notification_type: 'streak_milestone',
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
