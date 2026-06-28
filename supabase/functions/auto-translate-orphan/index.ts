// auto-translate-orphan
//
// Reads the English `story` of a sponsored_orphans row and fills the
// 7 per-locale `story_<lang>` columns via Google Translate.
//
// Triggered by `AFTER INSERT OR UPDATE OF story` on sponsored_orphans via
// pg_net.http_post — see migration 20260627_010_orphans_story_translations.sql.
//
// Manual invocation:
//   curl -X POST <function-url> \
//     -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
//     -H "Content-Type: application/json" \
//     -d '{"orphan_id":"<uuid>"}'

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const TARGET_LANGS = ["ar", "ur", "fr", "id", "ms", "ru", "tr"] as const;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
    status,
  });
}

async function translate(text: string, target: string): Promise<string | null> {
  if (!text || !text.trim()) return null;
  try {
    const url =
      "https://translate.googleapis.com/translate_a/single" +
      `?client=gtx&sl=en&tl=${encodeURIComponent(target)}&dt=t&q=` +
      encodeURIComponent(text);
    const res = await fetch(url, {
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) return null;
    const body = await res.json();
    const segments = body?.[0];
    if (!Array.isArray(segments)) return null;
    const out = segments
      .map((seg: unknown) =>
        Array.isArray(seg) && typeof seg[0] === "string" ? (seg[0] as string) : ""
      )
      .join("")
      .trim();
    return out.length > 0 ? out : null;
  } catch (_) {
    return null;
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    return jsonResponse({ error: "Server misconfigured" }, 500);
  }

  let orphanId: string;
  try {
    const body = await req.json();
    orphanId = body?.orphan_id;
    if (!orphanId || typeof orphanId !== "string") {
      return jsonResponse({ error: "Missing orphan_id" }, 400);
    }
  } catch (_) {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  // 1) Fetch English story
  const fetchRes = await fetch(
    `${supabaseUrl}/rest/v1/sponsored_orphans?id=eq.${orphanId}&select=story`,
    {
      headers: {
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
      },
    }
  );
  if (!fetchRes.ok) {
    return jsonResponse(
      { error: `Fetch failed: ${fetchRes.status}` },
      fetchRes.status
    );
  }
  const rows = await fetchRes.json();
  const row = Array.isArray(rows) ? rows[0] : null;
  if (!row) {
    return jsonResponse({ error: "Orphan not found" }, 404);
  }

  const story = (row.story as string | null) ?? "";

  // 2) Translate to each target language in parallel.
  const results = await Promise.all(
    TARGET_LANGS.map(async (lang) => ({
      lang,
      text: await translate(story, lang),
    }))
  );

  // 3) Build PATCH payload — only story_<lang> columns.
  const patch: Record<string, string | null> = {};
  for (const r of results) {
    patch[`story_${r.lang}`] = r.text;
  }

  // 4) Apply update. Service-role bypasses RLS.
  const updateRes = await fetch(
    `${supabaseUrl}/rest/v1/sponsored_orphans?id=eq.${orphanId}`,
    {
      method: "PATCH",
      headers: {
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify(patch),
    }
  );
  if (!updateRes.ok) {
    const errText = await updateRes.text();
    return jsonResponse(
      { error: `Update failed: ${updateRes.status} ${errText}` },
      500
    );
  }

  const summary = results.map((r) => ({
    lang: r.lang,
    story: r.text ? "ok" : "skip",
  }));
  return jsonResponse({ orphan_id: orphanId, translated: summary });
});
