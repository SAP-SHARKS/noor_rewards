// featured-dua-reminder — daily "featured dua" push at user-local 13:00.
// Each user gets a random azkar from `azkar_items` whose `hadith_full`
// is non-trivial (>30 chars), with the hadith excerpt as the body and
// a rotating prefix title from notification_variants.
//
// Schedule: hourly cron. Function gates on:
//   • user-local hour === SEND_HOUR (13:00)
//   • notifications_paused === false (via filterPausedUsers)
//   • dailyPushCapReached() === false
//   • dedup: one featured_dua push per user per UTC day

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';
import { getFcmCreds } from '../_shared/fcm.ts';
import { pickVariant } from '../_shared/variants.ts';
import { filterPausedUsers } from '../_shared/disengagement.ts';
import { dailyPushCapReached } from '../_shared/daily_cap.ts';

const SEND_HOUR = 13;
const MIN_HADITH_LEN = 30;
const BODY_MAX = 200;

serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );
    const now = new Date();

    // 1. FCM tokens + paused-user filter.
    const { data: fcmTokensRaw } = await supabase
      .from('fcm_tokens')
      .select('user_id, token, timezone, app_locale');
    const fcmTokens = await filterPausedUsers(supabase, fcmTokensRaw ?? []);
    if (fcmTokens.length === 0) {
      return new Response(JSON.stringify({ message: 'No tokens' }));
    }

    // 2. Bucket users whose local hour matches SEND_HOUR.
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

    // 3. Pull a pool of azkar with substantive hadith text. Per-user random
    // pick from the pool for variety; pool is fetched once per run.
    const { data: poolRaw } = await supabase
      .from('azkar_items')
      .select('id, transliteration, translation, hadith_full, reward')
      .not('hadith_full', 'is', null)
      .limit(200);
    const pool = (poolRaw ?? []).filter((r: any) =>
      typeof r.hadith_full === 'string' && r.hadith_full.length > MIN_HADITH_LEN
    );
    // Secondary pool — fall back to `reward` text if no hadith is good enough.
    const fallbackPool = (poolRaw ?? []).filter((r: any) =>
      typeof r.reward === 'string' && r.reward.length > 0
    );
    const effectivePool = pool.length > 0 ? pool : fallbackPool;
    if (effectivePool.length === 0) {
      return new Response(JSON.stringify({ message: 'No azkar with usable hadith/reward' }));
    }

    // 4. Dedup — one featured_dua push per user per UTC day.
    const todayStart = new Date(now);
    todayStart.setUTCHours(0, 0, 0, 0);
    const candidateIds = [...candidates.keys()];
    const { data: alreadySent } = await supabase
      .from('notification_log')
      .select('user_id')
      .eq('notification_type', 'featured_dua')
      .in('user_id', candidateIds)
      .gte('sent_at', todayStart.toISOString());
    const sentSet = new Set<string>((alreadySent ?? []).map((r: any) => r.user_id));
    const final = candidateIds.filter((uid) => !sentSet.has(uid));
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

      const pick = effectivePool[Math.floor(Math.random() * effectivePool.length)];
      const rawText: string = (pick.hadith_full && pick.hadith_full.length > MIN_HADITH_LEN)
        ? pick.hadith_full
        : (pick.reward ?? '');
      const bodyText = rawText.length > BODY_MAX
        ? rawText.slice(0, BODY_MAX).trimEnd() + '…'
        : rawText;

      const variant = await pickVariant(
        supabase,
        'featured_dua',
        entry.locale,
        {},
        {
          title: 'A dua for today',
          body: bodyText,
          route: 'dhikr',
        },
      );

      // Server-side title (rotating prefix from variants); always override the
      // body with the picked azkar text so the push carries real content.
      const finalTitle = variant.title;
      const finalBody = bodyText;

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
                  title: finalTitle,
                  body: finalBody,
                  ...(variant.imageUrl ? { image: variant.imageUrl } : {}),
                },
                data: { route: variant.route ?? 'dhikr', nid },
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
            notification_type: 'featured_dua',
            notification_id: nid,
            title: finalTitle,
            body: finalBody,
            route: variant.route ?? 'dhikr',
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
