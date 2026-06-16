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

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const ADMIN_EMAILS = new Set([
  'pak.zakn@gmail.com',
  'zaid_azam@zeir.io',
]);

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { user_id, title, body, route, admin_email } = await req.json();

    if (!user_id || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing user_id, title, or body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const normEmail = (admin_email ?? '').toLowerCase().trim();
    if (!normEmail || !ADMIN_EMAILS.has(normEmail)) {
      return new Response(
        JSON.stringify({
          error: `Forbidden — admin_email "${admin_email ?? 'missing'}" is not in the allowlist`,
        }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ── Service role for fcm_tokens read + notification_log insert ──────────
    const admin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

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
    const projectId    = Deno.env.get('FCM_PROJECT_ID');
    const clientEmail  = Deno.env.get('FCM_CLIENT_EMAIL');
    const privateKeyStr = Deno.env.get('FCM_PRIVATE_KEY');
    if (!projectId || !clientEmail || !privateKeyStr) {
      return new Response(
        JSON.stringify({ error: 'FCM secrets not configured on the server' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }
    const privateKey = privateKeyStr.replace(/\\n/g, '\n');
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

    // 3. Send FCM
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
            notification: { title, body },
            data: { nid, ...(route ? { route } : {}) },
            android: { priority: 'high', notification: { sound: 'default' } },
            apns: { payload: { aps: { sound: 'default' } } },
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

    // 4. Log to notification_log so it shows in the admin
    try {
      await admin.from('notification_log').insert({
        user_id,
        notification_type: 'admin_test_push',
        notification_id: nid,
        title,
        body,
        route: route ?? null,
        sent_at: new Date().toISOString(),
      });
    } catch (logErr) {
      console.error('notification_log insert failed:', logErr);
    }

    return new Response(
      JSON.stringify({ success: true, notification_id: nid, sent_by: normEmail }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err?.message ?? String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
