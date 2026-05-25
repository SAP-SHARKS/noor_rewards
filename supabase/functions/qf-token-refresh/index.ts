import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(data: any, status = 200) {
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
    const { refresh_token, client_id } = await req.json();

    if (!refresh_token || !client_id) {
      return jsonResponse({ error: "Missing required parameters" }, 400);
    }

    // F-13 fix: same allowlist as qf-token-exchange.
    const allowed = (Deno.env.get("QF_ALLOWED_CLIENT_IDS") || "")
      .split(",").map(s => s.trim()).filter(Boolean);
    if (allowed.length > 0 && !allowed.includes(client_id)) {
      return jsonResponse({ error: "Invalid client" }, 400);
    }

    const qfEnv = Deno.env.get("QF_ENV") || "production";
    const authBase = qfEnv === "production"
      ? "https://oauth2.quran.foundation"
      : "https://prelive-oauth2.quran.foundation";

    const clientSecret = Deno.env.get(`QF_CLIENT_SECRET_${client_id}`) || Deno.env.get("QF_CLIENT_SECRET");
    
    if (!clientSecret) {
      return jsonResponse({ error: "Client secret not configured" }, 500);
    }

    const tokenUrl = `${authBase}/oauth2/token`;
    const basicAuth = btoa(`${client_id}:${clientSecret}`);

    const body = new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token,
      client_id,
    });

    const response = await fetch(tokenUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": `Basic ${basicAuth}`,
        "Accept": "application/json",
      },
      body: body.toString(),
    });

    const data = await response.json();
    if (!response.ok) {
      // F-24 fix: don't leak provider details.
      console.error("qf-token-refresh provider error:", response.status, data);
      return jsonResponse({ error: "Refresh failed" }, response.status);
    }
    return jsonResponse(data, response.status);

  } catch (err: any) {
    console.error("qf-token-refresh error:", err);
    return jsonResponse({ error: "Internal error" }, 500);
  }
});
