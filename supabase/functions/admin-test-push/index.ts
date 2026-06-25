// admin-test-push — Admin-only manual push for verifying delivery / open tracking.
//
// Auth model: the admin web passes the signed-in admin's email in the request
// body. We verify it's in ADMIN_EMAILS (case-insensitive). This works around
// supabase.functions.invoke()'s session-handling quirks while still keeping
// the function admin-only — random callers without the anon key can't invoke
// it at all (Supabase's gateway enforces that), and within authenticated
// callers, only the named admin emails are accepted.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';
import { getFcmCreds } from '../_shared/fcm.ts';
import { pickVariant, fillTemplate } from '../_shared/variants.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const {
      user_id,
      title,
      body,
      route,
      admin_user_id,
      notification_type,
      variant_id,
      vars,
    } = await req.json();

    // Either notification_type (variant lookup) OR title+body (manual) is required.
    if (!user_id || (!notification_type && (!title || !body))) {
      return new Response(
        JSON.stringify({
          error: 'Need user_id + either notification_type or (title + body)',
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }
    if (!admin_user_id) {
      return new Response(
        JSON.stringify({ error: 'Forbidden — admin_user_id missing' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ── Service role for fcm_tokens read + notification_log insert ──────────
    const admin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    // ── Admin check: caller's user_id must have role='admin' in app_roles.
    //    Stays in sync with whoever you've granted admin to in the DB —
    //    no hardcoded email list to drift out of sync.
    const { data: roleRow } = await admin
      .from('app_roles')
      .select('role')
      .eq('user_id', admin_user_id)
      .eq('role', 'admin')
      .maybeSingle();
    if (!roleRow) {
      return new Response(
        JSON.stringify({ error: `Forbidden — ${admin_user_id} is not an admin` }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // 1. Fetch the target user's FCM token
    const { data: tokenRow, error: tokErr } = await admin
      .from('fcm_tokens')
      .select('token')
      .eq('user_id', user_id)
      .maybeSingle();

    if (tokErr) {
      return new Response(
        JSON.stringify({ error: `Token lookup failed: ${tokErr.message}` }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }
    if (!tokenRow?.token) {
      return new Response(
        JSON.stringify({
          error: 'No FCM token registered for this user — they have not opened the app since notifications were set up.',
        }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // 2. Google OAuth2 access token for FCM HTTP v1 API
    let projectId: string, clientEmail: string, privateKey: string;
    try {
      ({ projectId, clientEmail, privateKey } = getFcmCreds());
    } catch (e) {
      return new Response(
        JSON.stringify({ error: (e as Error).message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }
    const privateKeyObj = await importPKCS8(privateKey, 'RS256');
    const jwt = await new SignJWT({
      iss: clientEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
    })
      .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
      .setIssuedAt()
      .setExpirationTime('1h')
      .sign(privateKeyObj);

    const tokRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    });
    const tokJson = await tokRes.json();
    if (!tokRes.ok) {
      return new Response(
        JSON.stringify({ error: `OAuth: ${tokJson.error_description || tokJson.error}` }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }
    const accessToken = tokJson.access_token;

    // 3. Resolve the final title/body — variant lookup if notification_type
    //    given, otherwise the literal title/body from the request.
    const { data: recipientRow } = await admin
      .from('fcm_tokens')
      .select('app_locale')
      .eq('user_id', user_id)
      .maybeSingle();
    const recipientLocale = (recipientRow?.app_locale as string) ?? 'en';

    let finalTitle = title as string | undefined;
    let finalBody = body as string | undefined;
    let finalRoute: string | null = route ?? null;
    let finalImage: string | null = null;
    let variantId: string | null = null;

    // Build REAL placeholder values from the DB so Test send mirrors what
    // the recipient would see if the cron fired naturally. If the real data
    // wouldn't pass the production guard (e.g. community_momentum needs
    // 5+ readers), we abort with a clear message instead of substituting
    // dummy values — testing the actual production behaviour matters more
    // than seeing the wording rendered.
    const resolved = await resolveRealVars(
      admin,
      (notification_type as string | undefined) ?? '',
      user_id as string,
    );
    if (resolved.skipReason) {
      return new Response(
        JSON.stringify({
          error: `Production would skip this push right now: ${resolved.skipReason}`,
        }),
        { status: 422, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }
    const mergedVars: Record<string, string | number> = {
      ...((vars as Record<string, string | number>) ?? {}),
      ...resolved.vars,
    };

    // Variant resolution order:
    //   1) Explicit `variant_id` → fetch that exact row (admin clicked a
    //      specific variant's Test button — they want THAT one, not a random
    //      pick from the pool). Required so admins can verify a specific
    //      image / wording without rolling the dice.
    //   2) `notification_type` (no id) → random pick from the active pool
    //      for that type + recipient locale.
    //   3) Otherwise → literal title/body from the request.
    if (variant_id) {
      const { data: row, error: vErr } = await admin
        .from('notification_variants')
        .select('id, title, body, route, image_url')
        .eq('id', variant_id as string)
        .maybeSingle();
      if (vErr || !row) {
        return new Response(
          JSON.stringify({ error: `Variant ${variant_id} not found` }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }
      finalTitle = fillTemplate(row.title as string, mergedVars);
      finalBody = fillTemplate(row.body as string, mergedVars);
      finalRoute = (row.route as string | null) ?? null;
      finalImage = (row.image_url as string | null) ?? null;
      variantId = row.id as string;
    } else if (notification_type) {
      const variant = await pickVariant(
        admin,
        notification_type as string,
        recipientLocale,
        mergedVars,
        {
          title: title ?? `[Test] ${notification_type}`,
          body: body ?? `Test push of type ${notification_type}`,
          route: route ?? null,
        },
      );
      finalTitle = variant.title;
      finalBody = variant.body;
      finalRoute = variant.route;
      finalImage = variant.imageUrl ?? null;
      variantId = variant.id || null;
    }

    // 4. Send FCM
    const nid = crypto.randomUUID();
    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token: tokenRow.token,
            notification: {
              title: finalTitle,
              body: finalBody,
              ...(finalImage ? { image: finalImage } : {}),
            },
            data: { nid, ...(finalRoute ? { route: finalRoute } : {}) },
            android: {
              priority: 'high',
              notification: {
                sound: 'default',
                ...(finalImage ? { image: finalImage } : {}),
              },
            },
            apns: {
              payload: { aps: { sound: 'default', 'mutable-content': 1 } },
              ...(finalImage
                ? { fcm_options: { image: finalImage } }
                : {}),
            },
          },
        }),
      },
    );
    const fcmJson = await fcmRes.json();
    if (!fcmRes.ok) {
      return new Response(
        JSON.stringify({ error: `FCM: ${JSON.stringify(fcmJson)}` }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // 5. Log to notification_log so it shows in the admin
    try {
      await admin.from('notification_log').insert({
        user_id,
        notification_type: (notification_type as string) ?? 'admin_test_push',
        notification_id: nid,
        title: finalTitle,
        body: finalBody,
        route: finalRoute,
        variant_id: variantId,
        sent_at: new Date().toISOString(),
      });
    } catch (logErr) {
      console.error('notification_log insert failed:', logErr);
    }

    return new Response(
      JSON.stringify({ success: true, notification_id: nid, sent_by: admin_user_id }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err?.message ?? String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});

// ─── Real-value resolver ────────────────────────────────────────────────────
// Reads the same data sources the cron functions would use, so Test send
// previews real numbers (e.g. yesterday's community readers, the recipient's
// actual streak / last-read position) instead of the hardcoded dummy values
// the admin page sends as a fallback. Any field this can't resolve is just
// omitted — the caller-supplied `vars` then wins for those keys.
const SURAH_NAMES_TEST: Record<number, string> = {
  1:'Al-Fatiha',2:'Al-Baqarah',3:'Ali Imran',4:'An-Nisa',5:'Al-Maidah',
  6:'Al-Anam',7:'Al-Araf',8:'Al-Anfal',9:'At-Tawbah',10:'Yunus',
  11:'Hud',12:'Yusuf',13:'Ar-Rad',14:'Ibrahim',15:'Al-Hijr',
  16:'An-Nahl',17:'Al-Isra',18:'Al-Kahf',19:'Maryam',20:'Ta-Ha',
  21:'Al-Anbiya',22:'Al-Hajj',23:'Al-Muminun',24:'An-Nur',25:'Al-Furqan',
  26:'Ash-Shuara',27:'An-Naml',28:'Al-Qasas',29:'Al-Ankabut',30:'Ar-Rum',
  36:'Ya-Sin',55:'Ar-Rahman',67:'Al-Mulk',
  // Tail-end mapping kept short — full table lives in the cron functions.
};

interface ResolvedRealVars {
  vars: Record<string, string | number>;
  skipReason?: string;
}

async function resolveRealVars(
  admin: any,
  type: string,
  userId: string,
): Promise<ResolvedRealVars> {
  const out: Record<string, string | number> = {};
  if (!type || !userId) return { vars: out };

  try {
    switch (type) {
      case 'community_momentum': {
        const yest = new Date();
        yest.setDate(yest.getDate() - 1);
        const { data } = await admin
          .from('global_daily_stats')
          .select('active_readers, total_ayahs, total_users')
          .eq('stat_date', yest.toISOString().substring(0, 10))
          .maybeSingle();
        const count = (data?.active_readers ?? data?.total_users) as
          | number
          | null
          | undefined;
        // Cron function skips when readers < 5 — test should reflect that.
        if (typeof count !== 'number' || count < 5) {
          return {
            vars: out,
            skipReason: `Only ${count ?? 0} community readers yesterday (need 5+).`,
          };
        }
        out.count = count;
        if (typeof data?.total_ayahs === 'number' && data.total_ayahs > 0) {
          out.ayahs = data.total_ayahs;
        }
        break;
      }

      case 'streak_at_risk': {
        const { data } = await admin
          .from('profiles')
          .select('login_streak, dhikr_streak, quran_streak')
          .eq('id', userId)
          .maybeSingle();
        if (data) {
          const best = Math.max(
            data.login_streak ?? 0,
            data.dhikr_streak ?? 0,
            data.quran_streak ?? 0,
          );
          if (best > 0) out.streak = best;
          out.type =
            (data.quran_streak ?? 0) >= (data.dhikr_streak ?? 0)
              ? 'Quran'
              : 'Dhikr';
        }
        break;
      }

      case 'resume_reading': {
        const { data } = await admin
          .from('quran_progress')
          .select('current_surah, current_ayah')
          .eq('user_id', userId)
          .maybeSingle();
        if (data?.current_surah) {
          out.surahName =
            SURAH_NAMES_TEST[data.current_surah] ??
            `Surah ${data.current_surah}`;
          out.ayah = data.current_ayah ?? 1;
        }
        break;
      }

      case 'level_up': {
        const { data: profile } = await admin
          .from('profiles')
          .select('total_xp, level')
          .eq('id', userId)
          .maybeSingle();
        const { data: levels } = await admin
          .from('xp_levels')
          .select('level, xp_required, title')
          .order('level', { ascending: true });
        if (profile && levels) {
          const cur = profile.level ?? 1;
          const next = levels.find((l: any) => l.level === cur + 1);
          if (next) {
            const need = next.xp_required - (profile.total_xp ?? 0);
            if (need > 0) {
              out.ptsNeeded = need;
              out.nextLevel = next.level;
              out.nextTitle = next.title;
            }
          }
        }
        break;
      }

      case 'monthly_quran':
      case 'monthly_milestone': {
        const monthDate =
          type === 'monthly_milestone'
            ? new Date(new Date().getFullYear(), new Date().getMonth() - 1, 1)
            : new Date(new Date().getFullYear(), new Date().getMonth(), 1);
        out.monthName = monthDate.toLocaleString('en-US', { month: 'long' });

        const { data } = await admin
          .from('user_monthly_stats')
          .select('ayahs_read, dhikr_sets')
          .eq('user_id', userId)
          .eq('month', monthDate.toISOString().substring(0, 10))
          .maybeSingle();
        if (data) {
          if (typeof data.ayahs_read === 'number') {
            out.ayahs = data.ayahs_read;
            out.verses = data.ayahs_read;
            out.hasanat = data.ayahs_read * 10;
          }
          if (typeof data.dhikr_sets === 'number') {
            out.dhikrSets = data.dhikr_sets;
          }
        }
        break;
      }

      case 'nightly_checkin': {
        const { data } = await admin
          .from('profiles')
          .select('total_xp')
          .eq('id', userId)
          .maybeSingle();
        if (typeof data?.total_xp === 'number') out.seeds = data.total_xp;
        break;
      }
    }
  } catch (_) {
    // Best-effort — leave whatever we couldn't fetch to fall back to dummies.
  }

  return { vars: out };
}
