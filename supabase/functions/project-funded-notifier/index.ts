// project-funded-notifier — "the project you donated to is fully funded!"
// thank-you push to every donor of a community_project that has just
// flipped to is_completed=true.
//
// Schedule: daily cron. Function gates on:
//   • community_projects.is_completed === true
//   • community_projects.updated_at within the last LOOKBACK_HOURS
//   • notifications_paused === false (via filterPausedUsers)
//   • dailyPushCapReached() === false
//   • dedup: one project_funded push per (user, project) pair, ever —
//     enforced via notification_log where route LIKE 'cause/<projectId>'

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';
import { getFcmCreds } from '../_shared/fcm.ts';
import { pickVariant } from '../_shared/variants.ts';
import { filterPausedUsers } from '../_shared/disengagement.ts';
import { dailyPushCapReached } from '../_shared/daily_cap.ts';

const LOOKBACK_HOURS = 36;

serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );
    const now = new Date();

    // 1. Find recently-completed community projects.
    const cutoff = new Date(now.getTime() - LOOKBACK_HOURS * 60 * 60 * 1000);
    const { data: projects } = await supabase
      .from('community_projects')
      .select('id, name, updated_at')
      .eq('is_completed', true)
      .gte('updated_at', cutoff.toISOString());

    if (!projects || projects.length === 0) {
      return new Response(JSON.stringify({ message: 'No newly-completed projects' }));
    }

    const accessToken = await getAccessToken();
    const { projectId: fcmProjectId } = getFcmCreds();
    let totalSent = 0;

    for (const project of projects) {
      const projId: string = project.id;
      const projName: string = project.name ?? 'your project';
      const route = `cause/${projId}`;

      // 2. All donors for this project.
      const { data: donors } = await supabase
        .from('user_donations')
        .select('user_id')
        .eq('project_id', projId);
      const donorIds = Array.from(new Set((donors ?? []).map((d: any) => d.user_id)));
      if (donorIds.length === 0) continue;

      // 3. FCM tokens for those donors, with paused-user filter.
      const { data: fcmTokensRaw } = await supabase
        .from('fcm_tokens')
        .select('user_id, token, timezone, app_locale')
        .in('user_id', donorIds);
      const fcmTokens = await filterPausedUsers(supabase, fcmTokensRaw ?? []);
      if (fcmTokens.length === 0) continue;

      const byUser = new Map<string, { tokens: string[]; locale: string }>();
      for (const row of fcmTokens) {
        if (!byUser.has(row.user_id)) {
          byUser.set(row.user_id, { tokens: [], locale: row.app_locale ?? 'en' });
        }
        byUser.get(row.user_id)!.tokens.push(row.token);
      }
      const userIds = [...byUser.keys()];

      // 4. Dedup — has this donor already received a project_funded push
      // for this exact project? (Route stores 'cause/<projectId>'.)
      const { data: alreadySent } = await supabase
        .from('notification_log')
        .select('user_id')
        .eq('notification_type', 'project_funded')
        .in('user_id', userIds)
        .ilike('route', `%${projId}%`);
      const sentSet = new Set<string>((alreadySent ?? []).map((r: any) => r.user_id));
      const final = userIds.filter((uid) => !sentSet.has(uid));
      if (final.length === 0) continue;

      // 5. Send.
      for (const userId of final) {
        if (await dailyPushCapReached(supabase, userId)) continue;
        const entry = byUser.get(userId)!;
        const nid = crypto.randomUUID();
        const variant = await pickVariant(
          supabase,
          'project_funded',
          entry.locale,
          { projectName: projName },
          {
            title: 'Your sadaqah reached its goal',
            body:
              `"${projName}" is fully funded — jazak Allahu khayran for being ` +
              'part of it. Your reward continues with every soul it benefits.',
            route,
          },
        );

        let anySuccess = false;
        for (const token of entry.tokens) {
          const res = await fetch(
            `https://fcm.googleapis.com/v1/projects/${fcmProjectId}/messages:send`,
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
                  data: { route: variant.route ?? route, nid },
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
          totalSent++;
          await supabase
            .from('notification_log')
            .insert({
              user_id: userId,
              notification_type: 'project_funded',
              notification_id: nid,
              title: variant.title,
              body: variant.body,
              route: variant.route ?? route,
              variant_id: variant.id || null,
              sent_at: now.toISOString(),
            })
            .catch(() => {});
        }
      }
    }

    return new Response(JSON.stringify({ success: true, sent: totalSent }));
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
