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
    const { code, code_verifier, redirect_uri, client_id } = await req.json();

    if (!code || !code_verifier || !redirect_uri || !client_id) {
      return jsonResponse({ error: "Missing required parameters" }, 400);
    }

    const qfEnv = Deno.env.get("QF_ENV") || "prelive";
    const authBase = qfEnv === "production"
      ? "https://oauth2.quran.foundation"
      : "https://prelive-oauth2.quran.foundation";

    // Expected environment variable format for dynamic client secrets
    const clientSecret = Deno.env.get(`QF_CLIENT_SECRET_${client_id}`) || Deno.env.get("QF_CLIENT_SECRET");
    
    if (!clientSecret) {
      return jsonResponse({ error: "Client secret not configured" }, 500);
    }

    const tokenUrl = `${authBase}/oauth2/token`;
    const basicAuth = btoa(`${client_id}:${clientSecret}`);

    const body = new URLSearchParams({
      grant_type: "authorization_code",
      code,
      redirect_uri,
      client_id,
      code_verifier,
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
    return jsonResponse(data, response.status);

  } catch (err: any) {
    return jsonResponse({ error: err.message }, 500);
  }
});
