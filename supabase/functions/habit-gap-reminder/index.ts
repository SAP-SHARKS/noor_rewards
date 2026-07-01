// habit-gap-reminder — fires once per user per day at SEND_HOUR local for
// users who in the last 7 days have been active in EXACTLY ONE of {Quran,
// dhikr} but not the other. Routes them to the missing habit with gentle
// "two wings of worship" copy.
//
// Schedule: hourly. Function self-gates on user-local hour === SEND_HOUR.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';
import { getFcmCreds } from '../_shared/fcm.ts';
import { pickVariant } from '../_shared/variants.ts';
import { filterPausedUsers } from '../_shared/disengagement.ts';
import { dailyPushCapReached } from '../_shared/daily_cap.ts';

const SEND_HOUR = 14;
const WINDOW_DAYS = 7;

serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );
    const now = new Date();

    // 1. Local-hour-gated candidates.
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

    // 2. Activity in the last WINDOW_DAYS, bucketed by type.
    const windowStart = new Date(now);
    windowStart.setDate(windowStart.getDate() - WINDOW_DAYS);
    const { data: acts } = await supabase
      .from('user_activities')
      .select('user_id, activity_type')
      .in('user_id', candidateIds)
      .gte('created_at', windowStart.toISOString());

    const hasQuran = new Set<string>();
    const hasDhikr = new Set<string>();
    for (const a of acts ?? []) {
      const r = a as any;
      if (r.activity_type === 'quran') hasQuran.add(r.user_id);
      if (r.activity_type === 'dhikr') hasDhikr.add(r.user_id);
    }

    // 3. Decide who needs which nudge (active in exactly ONE of the two).
    const needsDhikr: string[] = []; // Quran-active, missing dhikr
    const needsQuran: string[] = []; // dhikr-active, missing Quran
    for (const uid of candidateIds) {
      const q = hasQuran.has(uid);
      const d = hasDhikr.has(uid);
      if (q && !d) needsDhikr.push(uid);
      else if (d && !q) needsQuran.push(uid);
    }
    if (needsDhikr.length === 0 && needsQuran.length === 0) {
      return new Response(JSON.stringify({ message: 'No habit gaps detected' }));
    }

    // 4. Dedup per type per UTC day.
    const todayStart = new Date(now);
    todayStart.setUTCHours(0, 0, 0, 0);
    const { data: alreadySent } = await supabase
      .from('notification_log')
      .select('user_id, notification_type')
      .in('notification_type', ['habit_gap_quran', 'habit_gap_dhikr'])
      .in('user_id', [...needsDhikr, ...needsQuran])
      .gte('sent_at', todayStart.toISOString());
    const sentDhikr = new Set<string>();
    const sentQuran = new Set<string>();
    for (const r of alreadySent ?? []) {
      const x = r as any;
      if (x.notification_type === 'habit_gap_dhikr') sentDhikr.add(x.user_id);
      if (x.notification_type === 'habit_gap_quran') sentQuran.add(x.user_id);
    }

    const finalDhikr = needsDhikr.filter((u) => !sentDhikr.has(u));
    const finalQuran = needsQuran.filter((u) => !sentQuran.has(u));

    // 5. Send.
    const accessToken = await getAccessToken();
    const { projectId } = getFcmCreds();
    let sent = 0;

    const sendOne = async (
      userId: string,
      type: 'habit_gap_dhikr' | 'habit_gap_quran',
      fallbackTitle: string,
      fallbackBody: string,
      fallbackRoute: string,
    ) => {
      if (await dailyPushCapReached(supabase, userId)) return;
      const entry = candidates.get(userId);
      if (!entry) return;
      const nid = crypto.randomUUID();
      const variant = await pickVariant(
        supabase,
        type,
        entry.locale,
        {},
        { title: fallbackTitle, body: fallbackBody, route: fallbackRoute },
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
                data: { route: variant.route ?? fallbackRoute, nid },
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
            notification_type: type,
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

    for (const uid of finalDhikr) {
      await sendOne(
        uid,
        'habit_gap_dhikr',
        'Pair the Quran with dhikr',
        'You\'ve been reading the Quran consistently. Crown your day with morning or evening adhkar.',
        'dhikr',
      );
    }
    for (const uid of finalQuran) {
      await sendOne(
        uid,
        'habit_gap_quran',
        'Open the Mushaf today',
        'Your dhikr is steady. Take a few minutes for the Quran too — even one ayah counts.',
        'quran',
      );
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
