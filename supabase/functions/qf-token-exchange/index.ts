import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

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
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const { code, code_verifier, redirect_uri, client_id } = await req.json();
    if (!code || !code_verifier || !redirect_uri || !client_id) {
      return jsonResponse({ error: "Missing required parameters" }, 400);
    }

    // F-13 fix: only accept known client_ids. Set QF_ALLOWED_CLIENT_IDS
    // (comma-separated) in Supabase Edge Function secrets. Leave unset to
    // skip the check (back-compat) — but you should set it.
    const allowed = (Deno.env.get("QF_ALLOWED_CLIENT_IDS") || "")
      .split(",").map(s => s.trim()).filter(Boolean);
    if (allowed.length > 0 && !allowed.includes(client_id)) {
      return jsonResponse({ error: "Invalid client" }, 400);
    }

    const qfEnv = Deno.env.get("QF_ENV") || "production";
    const authBase = qfEnv === "production"
      ? "https://oauth2.quran.foundation"
      : "https://prelive-oauth2.quran.foundation";

    const clientSecret =
      Deno.env.get(`QF_CLIENT_SECRET_${client_id}`) ||
      Deno.env.get("QF_CLIENT_SECRET");
    if (!clientSecret) return jsonResponse({ error: "Client secret not configured" }, 500);

    // Exchange code for QF tokens
    const resp = await fetch(`${authBase}/oauth2/token`, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": `Basic ${btoa(`${client_id}:${clientSecret}`)}`,
        "Accept": "application/json",
      },
      body: new URLSearchParams({
        grant_type: "authorization_code",
        code, redirect_uri, client_id, code_verifier,
      }).toString(),
    });

    const data = await resp.json();
    if (!resp.ok || data.error) {
      // F-24 fix: log full provider response server-side; return generic
      // error to the client instead of echoing OAuth provider details.
      console.error("qf-token-exchange provider error:", resp.status, data);
      return jsonResponse({ error: "Token exchange failed" }, resp.status);
    }

    // Return only QF tokens — Supabase session is handled client-side
    return jsonResponse({
      access_token:  data.access_token,
      refresh_token: data.refresh_token,
    });

  } catch (err: unknown) {
    console.error("qf-token-exchange error:", err);
    return jsonResponse({ error: "Internal error" }, 500);
  }
});
