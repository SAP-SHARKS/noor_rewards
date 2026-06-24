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
import { pickVariant } from '../_shared/variants.ts';

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

    if (notification_type) {
      const variant = await pickVariant(
        admin,
        notification_type as string,
        recipientLocale,
        (vars as Record<string, string | number>) ?? {},
        {
          title: title ?? `[Test] ${notification_type}`,
          body: body ?? `Test push of type ${notification_type}`,
          route: route ?? null,
        },
      );
      finalTitle = variant.title;
      finalBody = variant.body;
      finalRoute = variant.route;
      finalImage = (variant as any).imageUrl ?? null;
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
