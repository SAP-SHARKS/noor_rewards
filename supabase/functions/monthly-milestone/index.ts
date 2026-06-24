// monthly-milestone — Celebrate user's monthly progress with comparison
// Schedule: Cron on 1st of every month (or last day)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';
import { getFcmCreds } from '../_shared/fcm.ts';
import { pickVariant } from '../_shared/variants.ts';

serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const now = new Date();
    // Last month's first day
    const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const lastMonthStr = lastMonth.toISOString().substring(0, 10);
    // Month before that
    const twoMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 2, 1);
    const twoMonthsAgoStr = twoMonthsAgo.toISOString().substring(0, 10);

    // 1. Get last month's stats for all users
    const { data: lastMonthStats } = await supabase
      .from('user_monthly_stats')
      .select('user_id, ayahs_read, dhikr_sets, total_points')
      .eq('month', lastMonthStr);

    if (!lastMonthStats || lastMonthStats.length === 0) {
      return new Response(JSON.stringify({ message: 'No stats for last month' }));
    }

    // 2. Get the month before for comparison
    const { data: prevStats } = await supabase
      .from('user_monthly_stats')
      .select('user_id, ayahs_read, dhikr_sets, total_points')
      .eq('month', twoMonthsAgoStr);

    const prevMap = new Map((prevStats || []).map((r: any) => [r.user_id, r]));

    // 3. Get FCM tokens (+ user locale for variant lookup)
    const { data: fcmTokens } = await supabase
      .from('fcm_tokens')
      .select('user_id, token, app_locale');

    const tokenMap = new Map<string, { token: string; locale: string }>(
      (fcmTokens || []).map((r: any) => [r.user_id, { token: r.token, locale: r.app_locale ?? 'en' }])
    );

    // 4. Dedup
    const monthKey = `monthly_milestone_${lastMonthStr}`;
    const { data: alreadySent } = await supabase
      .from('notification_log')
      .select('user_id')
      .eq('notification_type', monthKey);

    const sentSet = new Set((alreadySent || []).map((r: any) => r.user_id));

    // 5. Build notifications
    const accessToken = await getAccessToken();
    const { projectId } = getFcmCreds();
    let sent = 0;

    const monthName = lastMonth.toLocaleString('en-US', { month: 'long' });

    for (const stat of lastMonthStats) {
      if (sentSet.has(stat.user_id)) continue;
      const entry = tokenMap.get(stat.user_id);
      if (!entry) continue;
      if (stat.ayahs_read === 0 && stat.dhikr_sets === 0) continue;

      const prev = prevMap.get(stat.user_id);
      let fallbackBody = `In ${monthName} you read ${stat.ayahs_read} ayahs and completed ${stat.dhikr_sets} dhikr sets.`;

      if (prev && prev.ayahs_read > 0) {
        const diff = stat.ayahs_read - prev.ayahs_read;
        if (diff > 0) {
          fallbackBody += ` That's ${diff} more ayahs than the month before!`;
        }
      }

      const nid = crypto.randomUUID();
      const variant = await pickVariant(
        supabase,
        'monthly_milestone',
        entry.locale,
        { monthName, ayahs: stat.ayahs_read, dhikrSets: stat.dhikr_sets },
        {
          title: `MashaAllah! Your ${monthName} recap`,
          body: fallbackBody,
          route: 'akhirah',
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
                ...(variant.imageUrl ? { fcm_options: { image: variant.imageUrl } } : {}),
              },
            },
          }),
        }
      );

      if (res.ok) {
        sent++;
        await supabase.from('notification_log').insert({
          user_id: stat.user_id,
          notification_type: monthKey,
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
