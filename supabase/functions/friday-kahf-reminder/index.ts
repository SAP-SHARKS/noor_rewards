// friday-kahf-reminder — fires twice on Fridays (in each user's local
// timezone): once in the morning (~07:00 local) to encourage starting, and
// once in the afternoon (~16:00 local) as a last reminder before Maghrib.
//
// Schedule: hourly. The function self-gates on day-of-week === Friday AND
// hour ∈ {7, 16}, so a UTC firing only picks users whose local clock matches.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';
import { getFcmCreds } from '../_shared/fcm.ts';
import { pickVariant } from '../_shared/variants.ts';
import { filterPausedUsers } from '../_shared/disengagement.ts';

const MORNING_HOUR = 7;
const AFTERNOON_HOUR = 16;

serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const now = new Date();

    // 1. Load FCM tokens + filter paused users.
    const { data: fcmTokensRaw } = await supabase
      .from('fcm_tokens')
      .select('user_id, token, timezone, app_locale');
    const fcmTokens = await filterPausedUsers(supabase, fcmTokensRaw ?? []);
    if (fcmTokens.length === 0) {
      return new Response(JSON.stringify({ message: 'No FCM tokens' }));
    }

    // 2. Pick users whose local day-of-week is Friday AND local hour is
    //    the morning OR afternoon slot. Bucket by slot so each gets dedup'd
    //    independently (a user shouldn't get both pushes if they're in two
    //    slots somehow, but slot-level dedup also lets the afternoon push
    //    fire even if the morning one was skipped for some reason).
    const morningSlot = new Map<string, { tokens: string[]; locale: string }>();
    const afternoonSlot = new Map<string, { tokens: string[]; locale: string }>();

    for (const row of fcmTokens) {
      const tz = row.timezone || 'UTC';
      let weekday = '';
      let hour = -1;
      try {
        const parts = new Intl.DateTimeFormat('en-US', {
          timeZone: tz,
          weekday: 'short',
          hour: 'numeric',
          hour12: false,
        }).formatToParts(now);
        weekday = parts.find((p) => p.type === 'weekday')?.value ?? '';
        hour = parseInt(parts.find((p) => p.type === 'hour')?.value ?? '-1', 10);
      } catch {
        // Bad timezone — skip this row entirely; Friday Sunnah shouldn't
        // fire at a random UTC hour for users whose tz we can't resolve.
        continue;
      }

      if (weekday !== 'Fri') continue;

      const bucket = hour === MORNING_HOUR
        ? morningSlot
        : hour === AFTERNOON_HOUR
        ? afternoonSlot
        : null;
      if (!bucket) continue;

      if (!bucket.has(row.user_id)) {
        bucket.set(row.user_id, { tokens: [], locale: row.app_locale ?? 'en' });
      }
      bucket.get(row.user_id)!.tokens.push(row.token);
    }

    if (morningSlot.size === 0 && afternoonSlot.size === 0) {
      return new Response(JSON.stringify({ message: 'No users in a Friday slot' }));
    }

    // 3. Dedup per slot — at most one push per slot per Friday.
    //    Slot windows: morning = 00:00–11:59 local, afternoon = 12:00–end of
    //    day local. Since the function only fires on the matching hour, we
    //    can dedup conservatively by checking "any surah_kahf_friday push
    //    sent to this user in the last 6 hours".
    const cutoff = new Date(now);
    cutoff.setHours(cutoff.getHours() - 6);
    const recentSlotKey = (uid: string, slot: 'morning' | 'afternoon') =>
      `${uid}:${slot}`;
    const recentlySent = new Set<string>();

    const candidateIds = [
      ...morningSlot.keys(),
      ...afternoonSlot.keys(),
    ];
    if (candidateIds.length > 0) {
      const { data: recent } = await supabase
        .from('notification_log')
        .select('user_id, sent_at')
        .eq('notification_type', 'surah_kahf_friday')
        .in('user_id', candidateIds)
        .gte('sent_at', cutoff.toISOString());
      for (const r of recent ?? []) {
        // If a kahf push was sent in the last 6h, treat both slots as taken
        // for that user — keeps it strictly one push per slot per Friday.
        recentlySent.add(recentSlotKey((r as any).user_id, 'morning'));
        recentlySent.add(recentSlotKey((r as any).user_id, 'afternoon'));
      }
    }

    // 4. FCM auth.
    const accessToken = await getAccessToken();
    const { projectId } = getFcmCreds();
    let sent = 0;

    const sendOne = async (
      userId: string,
      entry: { tokens: string[]; locale: string },
      slot: 'morning' | 'afternoon',
    ) => {
      if (recentlySent.has(recentSlotKey(userId, slot))) return;

      const nid = crypto.randomUUID();
      const variant = await pickVariant(
        supabase,
        'surah_kahf_friday',
        entry.locale,
        {},
        {
          title: 'It\'s Friday — read Surah Al-Kahf',
          body:
            'Whoever recites Surah Al-Kahf on Friday, light shines for them ' +
            'between the two Fridays.',
          route: 'quran',
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
                data: { route: variant.route ?? 'quran', nid },
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
            notification_type: 'surah_kahf_friday',
            notification_id: nid,
            title: variant.title,
            body: variant.body,
            route: variant.route,
            variant_id: variant.id || null,
            sent_at: now.toISOString(),
          })
          .catch(() => {});
      }
    };

    for (const [uid, entry] of morningSlot.entries()) {
      await sendOne(uid, entry, 'morning');
    }
    for (const [uid, entry] of afternoonSlot.entries()) {
      await sendOne(uid, entry, 'afternoon');
    }

    return new Response(JSON.stringify({
      success: true,
      morning_candidates: morningSlot.size,
      afternoon_candidates: afternoonSlot.size,
      sent,
    }));
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
