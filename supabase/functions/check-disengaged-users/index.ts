// check-disengaged-users — fires one "we're pausing reminders" push to users
// who haven't returned to the app in a while AND haven't opened any of the
// notifications we've been sending them, then flips notifications_paused so
// future scheduled pushes skip them. They auto-resume via mark_user_active()
// the next time they open the app.
//
// Schedule: daily (see migration 20260628_020_disengagement_pause.sql).
// Thresholds:
//   • inactive for >= 14 days (last_seen_at)
//   • >= 7 unopened pushes sent in the last 14 days
// Message text comes from `notification_variants` (5 different phrasings)
// via the existing pickVariant helper, so two paused users in a row see
// different copy.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';
import { getFcmCreds } from '../_shared/fcm.ts';
import { pickVariant } from '../_shared/variants.ts';

const INACTIVE_DAYS = 14;
const MIN_UNOPENED_PUSHES = 7;

serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const now = new Date();
    const windowStart = new Date(now);
    windowStart.setDate(windowStart.getDate() - INACTIVE_DAYS);
    const windowStartIso = windowStart.toISOString();

    // 1. Candidates: profiles inactive for >= INACTIVE_DAYS and not already paused.
    //    `last_seen_at IS NULL` covers users who joined but never bumped the
    //    timestamp once it was introduced — still treat as inactive.
    const { data: candidates } = await supabase
      .from('profiles')
      .select('id')
      .eq('notifications_paused', false)
      .or(`last_seen_at.lt.${windowStartIso},last_seen_at.is.null`);

    if (!candidates || candidates.length === 0) {
      return new Response(JSON.stringify({ message: 'No disengagement candidates' }));
    }
    const candidateIds = candidates.map((r: any) => r.id);

    // 2. Count unopened pushes per candidate in the same window.
    const { data: pushes } = await supabase
      .from('notification_log')
      .select('user_id')
      .in('user_id', candidateIds)
      .is('opened_at', null)
      .gte('sent_at', windowStartIso);

    const unopenedCount = new Map<string, number>();
    for (const row of pushes ?? []) {
      const uid = (row as any).user_id as string;
      unopenedCount.set(uid, (unopenedCount.get(uid) ?? 0) + 1);
    }

    const toPause = candidateIds.filter(
      (uid: string) => (unopenedCount.get(uid) ?? 0) >= MIN_UNOPENED_PUSHES,
    );

    if (toPause.length === 0) {
      return new Response(JSON.stringify({ message: 'No users meet pause threshold' }));
    }

    // 3. Fetch FCM tokens + locale for those users.
    const { data: fcmTokens } = await supabase
      .from('fcm_tokens')
      .select('user_id, token, app_locale')
      .in('user_id', toPause);

    const userTokens = new Map<string, { token: string; locale: string }>();
    for (const row of fcmTokens ?? []) {
      const r = row as any;
      userTokens.set(r.user_id, {
        token: r.token,
        locale: r.app_locale ?? 'en',
      });
    }

    if (userTokens.size === 0) {
      // Still flip the flag even with no token — no point trying to nudge a
      // user whose device we can't reach.
      await supabase
        .from('profiles')
        .update({ notifications_paused: true, notifications_paused_at: now.toISOString() })
        .in('id', toPause);
      return new Response(JSON.stringify({ paused: toPause.length, sent: 0 }));
    }

    // 4. Send + log + flip the pause flag.
    const accessToken = await getAccessToken();
    const { projectId } = getFcmCreds();
    let sent = 0;
    const pausedUsers: string[] = [];

    for (const userId of toPause) {
      const entry = userTokens.get(userId);
      if (!entry) {
        // No token but still pause — they won't see the goodbye message but
        // we should stop trying to push them.
        pausedUsers.push(userId);
        continue;
      }

      const nid = crypto.randomUUID();
      const variant = await pickVariant(
        supabase,
        'disengagement_pause',
        entry.locale,
        {},
        {
          title: 'Reminders paused',
          body:
            'It looks like our nudges aren\'t reaching you. We\'ll quiet them ' +
            'for now — open Sabiq whenever your heart calls and they\'ll come ' +
            'back on their own.',
          route: 'home',
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
              token: entry.token,
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
                ...(variant.imageUrl
                  ? { fcm_options: { image: variant.imageUrl } }
                  : {}),
              },
            },
          }),
        },
      );

      if (res.ok) {
        sent++;
        await supabase
          .from('notification_log')
          .insert({
            user_id: userId,
            notification_type: 'disengagement_pause',
            notification_id: nid,
            title: variant.title,
            body: variant.body,
            route: variant.route,
            variant_id: variant.id || null,
            sent_at: now.toISOString(),
          })
          .catch(() => {});
      }
      pausedUsers.push(userId);
    }

    // 5. Flip notifications_paused for everyone we tried to notify.
    if (pausedUsers.length > 0) {
      await supabase
        .from('profiles')
        .update({
          notifications_paused: true,
          notifications_paused_at: now.toISOString(),
        })
        .in('id', pausedUsers);
    }

    return new Response(
      JSON.stringify({ success: true, paused: pausedUsers.length, sent }),
    );
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
