// validate-seeds-reminder — once-per-user-per-day nudge for users who have
// accumulated Seeds but haven't donated to a Cause recently. Encourages
// turning Seeds into real-world barakah via the donations system.
//
// Schedule: hourly. Function gates on:
//   • user-local hour === SEND_HOUR (18:00 local — early evening)
//   • profiles.noor_points >= MIN_SEEDS
//   • no row in user_donations within the last NO_DONATION_DAYS days
//   • dailyPushCapReached() === false
//   • notifications_paused === false (via filterPausedUsers)
//   • dedup against today's notification_log

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';
import { getFcmCreds } from '../_shared/fcm.ts';
import { pickVariant } from '../_shared/variants.ts';
import { filterPausedUsers } from '../_shared/disengagement.ts';
import { dailyPushCapReached } from '../_shared/daily_cap.ts';

const SEND_HOUR = 18;
const MIN_SEEDS = 50;
const NO_DONATION_DAYS = 7;

serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );
    const now = new Date();

    // 1. Find users whose local hour is SEND_HOUR right now.
    const { data: fcmTokensRaw } = await supabase
      .from('fcm_tokens')
      .select('user_id, token, timezone, app_locale');
    const fcmTokens = await filterPausedUsers(supabase, fcmTokensRaw ?? []);
    if (fcmTokens.length === 0) {
      return new Response(JSON.stringify({ message: 'No tokens' }));
    }

    const candidates = new Map<string, { tokens: string[]; locale: string }>();
    for (const row of fcmTokens) {
      const tz = row.timezone || 'UTC';
      let hour = -1;
      try {
        const parts = new Intl.DateTimeFormat('en-US', {
          timeZone: tz, hour: 'numeric', hour12: false,
        }).formatToParts(now);
        hour = parseInt(parts.find((p) => p.type === 'hour')?.value ?? '-1', 10);
      } catch { continue; }
      if (hour !== SEND_HOUR) continue;

      if (!candidates.has(row.user_id)) {
        candidates.set(row.user_id, { tokens: [], locale: row.app_locale ?? 'en' });
      }
      candidates.get(row.user_id)!.tokens.push(row.token);
    }
    if (candidates.size === 0) {
      return new Response(JSON.stringify({ message: 'No users at SEND_HOUR' }));
    }

    const candidateIds = [...candidates.keys()];

    // 2. Filter to users with enough Seeds.
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, noor_points')
      .in('id', candidateIds)
      .gte('noor_points', MIN_SEEDS);
    const seedyUsers = new Set<string>((profiles ?? []).map((p: any) => p.id));
    if (seedyUsers.size === 0) {
      return new Response(JSON.stringify({ message: 'No users with enough Seeds' }));
    }

    // 3. Drop users who donated in the last NO_DONATION_DAYS days.
    const donationCutoff = new Date(now);
    donationCutoff.setDate(donationCutoff.getDate() - NO_DONATION_DAYS);
    const { data: recentDonors } = await supabase
      .from('user_donations')
      .select('user_id')
      .in('user_id', [...seedyUsers])
      .gte('created_at', donationCutoff.toISOString());
    const recentlyDonated = new Set<string>(
      (recentDonors ?? []).map((d: any) => d.user_id),
    );
    const toNotify = [...seedyUsers].filter((uid) => !recentlyDonated.has(uid));
    if (toNotify.length === 0) {
      return new Response(JSON.stringify({ message: 'All Seed-rich users donated recently' }));
    }

    // 4. Dedup — only one validate_seeds push per user per UTC day.
    const todayStart = new Date(now);
    todayStart.setUTCHours(0, 0, 0, 0);
    const { data: alreadySent } = await supabase
      .from('notification_log')
      .select('user_id')
      .eq('notification_type', 'validate_seeds')
      .in('user_id', toNotify)
      .gte('sent_at', todayStart.toISOString());
    const sentSet = new Set<string>((alreadySent ?? []).map((r: any) => r.user_id));
    const final = toNotify.filter((uid) => !sentSet.has(uid));
    if (final.length === 0) {
      return new Response(JSON.stringify({ message: 'All targeted users already notified today' }));
    }

    // 5. Send.
    const accessToken = await getAccessToken();
    const { projectId } = getFcmCreds();
    let sent = 0;

    for (const userId of final) {
      if (await dailyPushCapReached(supabase, userId)) continue;
      const entry = candidates.get(userId)!;
      const nid = crypto.randomUUID();
      const variant = await pickVariant(
        supabase,
        'validate_seeds',
        entry.locale,
        {},
        {
          title: 'Your Seeds are growing',
          body:
            'Donate your Sabiq Seeds to fund real projects — orphans, ' +
            'masjids, free meals. Every Seed plants a deed.',
          route: 'cause',
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
                data: { route: variant.route ?? 'cause', nid },
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
            notification_type: 'validate_seeds',
            notification_id: nid,
            title: variant.title,
            body: variant.body,
            route: variant.route,
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
