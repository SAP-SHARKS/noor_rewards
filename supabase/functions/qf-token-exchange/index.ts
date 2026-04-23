import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
    status,
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { code, code_verifier, redirect_uri, client_id } = await req.json();

    if (!code || !code_verifier || !redirect_uri || !client_id) {
      return jsonResponse({ error: "Missing required parameters" }, 400);
    }

    const qfEnv = Deno.env.get("QF_ENV") || "production";
    const authBase = qfEnv === "production"
      ? "https://oauth2.quran.foundation"
      : "https://prelive-oauth2.quran.foundation";

    const clientSecret =
      Deno.env.get(`QF_CLIENT_SECRET_${client_id}`) ||
      Deno.env.get("QF_CLIENT_SECRET");

    if (!clientSecret) {
      return jsonResponse({ error: "Client secret not configured" }, 500);
    }

    // ── 1. Exchange code for QF tokens ────────────────────────────────────────
    const tokenUrl = `${authBase}/oauth2/token`;
    const basicAuth = btoa(`${client_id}:${clientSecret}`);

    const tokenBody = new URLSearchParams({
      grant_type: "authorization_code",
      code,
      redirect_uri,
      client_id,
      code_verifier,
    });

    const tokenResponse = await fetch(tokenUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": `Basic ${basicAuth}`,
        "Accept": "application/json",
      },
      body: tokenBody.toString(),
    });

    const qfData = await tokenResponse.json();

    if (!tokenResponse.ok || qfData.error) {
      return jsonResponse(
        { error: qfData.error || "Token exchange failed", details: qfData },
        tokenResponse.status,
      );
    }

    // ── 2. Fetch QF user info to get email ────────────────────────────────────
    const userinfoResp = await fetch(`${authBase}/userinfo`, {
      headers: { Authorization: `Bearer ${qfData.access_token}` },
    });
    const userinfo = await userinfoResp.json();

    // The prelive QF client only allows 'openid' scope, so email may not be
    // returned. Fall back to a deterministic synthetic email derived from sub.
    const qfSub: string = userinfo.sub ?? "unknown";
    const email: string = userinfo.email ?? `${qfSub}@qf.quranfoundation.user`;
    const displayName: string =
      userinfo.name || userinfo.preferred_username || "";


    // ── 3. Create/ensure Supabase user exists for this QF identity ────────────
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // createUser is idempotent-ish: ignore "already exists" errors
    await supabase.auth.admin.createUser({
      email,
      email_confirm: true,
      user_metadata: {
        qf_sub: qfSub,
        full_name: displayName,
        qf_connected: true,
      },
    });

    // ── 4. Generate a one-time magic-link token for the Flutter app ───────────
    // admin.generateLink does NOT send an email — it only returns the token.
    const { data: linkData, error: linkError } = await supabase.auth.admin
      .generateLink({
        type: "magiclink",
        email,
        options: { redirectTo: "noorrewards://auth/supabase-callback" },
      });

    if (linkError) {
      // Non-fatal: return QF tokens without a Supabase session
      console.error("generateLink error:", linkError.message);
      return jsonResponse({
        access_token: qfData.access_token,
        refresh_token: qfData.refresh_token,
      });
    }

    // Extract the plain token from the action_link URL query string
    // e.g. https://xxx.supabase.co/auth/v1/verify?token=PLAIN&type=magiclink&...
    const actionUrl = new URL(linkData.properties.action_link);
    const supabaseToken = actionUrl.searchParams.get("token");

    return jsonResponse({
      // QF tokens
      access_token: qfData.access_token,
      refresh_token: qfData.refresh_token,
      // Supabase session bootstrap data
      supabase_email: email,
      supabase_token: supabaseToken,
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return jsonResponse({ error: message }, 500);
  }
});
