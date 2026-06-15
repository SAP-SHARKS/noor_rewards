import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.3';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { user_id, title, body, data } = await req.json();

    if (!user_id || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters: user_id, title, body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 1. Initialize Supabase Client with the Authorization header of the caller
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Missing Authorization header');
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    );

    // F-12 fix: caller can only send a push to their OWN user_id.
    // Without this, any signed-in user could spoof phishing pushes to
    // any other user via this endpoint.
    const { data: { user }, error: authErr } = await supabase.auth.getUser();
    if (authErr || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    if (user.id !== user_id) {
      return new Response(
        JSON.stringify({ error: 'Forbidden' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 2. Query FCM Token
    const { data: tokenData, error: dbError } = await supabase
      .from('fcm_tokens')
      .select('token')
      .eq('user_id', user_id)
      .single();

    if (dbError || !tokenData?.token) {
      throw new Error(`Device token not found for user_id: ${user_id}. ${dbError?.message || ''}`);
    }

    const fcmToken = tokenData.token;

    // 3. Reconstruct Google OAuth2 Token using Service Account Credentials
    const projectId = Deno.env.get('FCM_PROJECT_ID');
    const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL');
    const privateKeyStr = Deno.env.get('FCM_PRIVATE_KEY');

    if (!projectId || !clientEmail || !privateKeyStr) {
      throw new Error('FCM secrets are not configured in Supabase (FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY)');
    }

    // Fix escaped newlines which happen when saving PEM keys as env secrets
    const privateKey = privateKeyStr.replace(/\\n/g, '\n');

    // Generate JWT via npm:jose
    const privateKeyObj = await importPKCS8(privateKey, 'RS256');
    const jwt = await new SignJWT({
      iss: clientEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
    })
      .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
      .setIssuedAt()
      .setExpirationTime('1h') // Token validity
      .sign(privateKeyObj);

    // Request Access Token from Google OAuth2 Server
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    });

    const tokenDataRes = await tokenResponse.json();
    if (!tokenResponse.ok) {
      throw new Error(`Failed to generate Google access token: ${tokenDataRes.error_description || tokenDataRes.error}`);
    }

    const accessToken = tokenDataRes.access_token;

    // 4. Send the Push Notification via Firebase HTTP v1 API
    const nid = crypto.randomUUID();
    const dataWithNid = { ...(data || {}), nid };
    const fcmPayload = {
      message: {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: dataWithNid,
        android: {
          priority: 'high',
          notification: {
            sound: 'default'
          }
        },
        apns: { payload: { aps: { sound: 'default' } } },
      }
    };

    const fcmResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(fcmPayload),
      }
    );

    const fcmResult = await fcmResponse.json();

    if (!fcmResponse.ok) {
      throw new Error(`FCM API Error: ${JSON.stringify(fcmResult)}`);
    }

    // Log the send so the admin can show sent/opened analytics.
    await supabase.from('notification_log').insert({
      user_id: user_id,
      notification_type: (data && (data as any).type) || 'manual_send',
      notification_id: nid,
      title,
      body,
      route: (data && (data as any).route) || null,
      sent_at: new Date().toISOString(),
    }).catch(() => {});

    return new Response(
      JSON.stringify({ success: true, result: fcmResult }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error: any) {
    // F-24 fix: don't leak DB / provider details to the client.
    console.error('send-fcm error:', error?.message ?? error);
    return new Response(
      JSON.stringify({ error: 'Internal error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
