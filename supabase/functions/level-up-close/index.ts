// level-up-close — "You're X points from Level Y" teaser
// Schedule: Cron every hour, targets users whose local time is ~12:00 (noon)
// Only sends once per level threshold (not daily)

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

    // 1. Get level thresholds
    const { data: levels } = await supabase
      .from('xp_levels')
      .select('level, xp_required, title')
      .order('level', { ascending: true });

    if (!levels || levels.length === 0) {
      return new Response(JSON.stringify({ message: 'No level data' }));
    }

    // 2. Get FCM tokens, filter for noon local (+ user locale for variant lookup)
    const { data: fcmTokens } = await supabase
      .from('fcm_tokens')
      .select('user_id, token, timezone, app_locale');

    const noonUsers = new Map<string, { token: string; locale: string }>();
    for (const row of fcmTokens || []) {
      const tz = row.timezone || 'UTC';
      try {
        const parts = new Intl.DateTimeFormat('en-US', {
          timeZone: tz, hour: 'numeric', hour12: false,
        }).formatToParts(now);
        const hour = parseInt(parts.find(p => p.type === 'hour')?.value ?? '0', 10);
        if (hour === 12) {
          noonUsers.set(row.user_id, {
            token: row.token,
            locale: row.app_locale ?? 'en',
          });
        }
      } catch { /* skip */ }
    }

    if (noonUsers.size === 0) {
      return new Response(JSON.stringify({ message: 'No users at noon' }));
    }

    // 3. Get profiles with XP for these users
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, total_xp, level')
      .in('id', [...noonUsers.keys()]);

    // 4. Find users within 20% of next level
    const closeUsers: { userId: string; token: string; locale: string; ptsNeeded: number; nextLevel: number; nextTitle: string }[] = [];

    for (const p of profiles || []) {
      const currentXp = p.total_xp ?? 0;
      const currentLevel = p.level ?? 1;

      // Find next level threshold
      const nextLevelData = levels.find((l: any) => l.level === currentLevel + 1);
      if (!nextLevelData) continue;

      const needed = nextLevelData.xp_required - currentXp;
      if (needed <= 0) continue;

      // Check if within 20% of the threshold gap
      const prevLevelData = levels.find((l: any) => l.level === currentLevel);
      const gap = nextLevelData.xp_required - (prevLevelData?.xp_required ?? 0);
      if (gap <= 0) continue;

      const progress = 1 - (needed / gap);
      if (progress >= 0.8) {
        const entry = noonUsers.get(p.id);
        if (entry) {
          closeUsers.push({
            userId: p.id,
            token: entry.token,
            locale: entry.locale,
            ptsNeeded: needed,
            nextLevel: nextLevelData.level,
            nextTitle: nextLevelData.title,
          });
        }
      }
    }

    // 5. Dedup — only send once per level threshold
    const toNotify: typeof closeUsers = [];
    for (const u of closeUsers) {
      const dedupKey = `level_up_${u.nextLevel}`;
      const { data: existing } = await supabase
        .from('notification_log')
        .select('id')
        .eq('user_id', u.userId)
        .eq('notification_type', dedupKey)
        .limit(1);

      if (!existing || existing.length === 0) {
        toNotify.push(u);
      }
    }

    if (toNotify.length === 0) {
      return new Response(JSON.stringify({ message: 'No close-to-level-up users' }));
    }

    // 6. Send
    const accessToken = await getAccessToken();
    const { projectId } = getFcmCreds();
    let sent = 0;

    for (const u of toNotify) {
      const nid = crypto.randomUUID();
      const variant = await pickVariant(
        supabase,
        'level_up',
        u.locale,
        { ptsNeeded: u.ptsNeeded, nextLevel: u.nextLevel, nextTitle: u.nextTitle },
        {
          title: `Level ${u.nextLevel} is within reach!`,
          body: `You're just ${u.ptsNeeded} points from becoming "${u.nextTitle}". One session gets you there!`,
          route: 'journey',
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
        const dedupKey = `level_up_${u.nextLevel}`;
        await supabase.from('notification_log').insert({
          user_id: u.userId,
          notification_type: dedupKey,
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
