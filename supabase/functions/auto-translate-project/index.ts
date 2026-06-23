// auto-translate-project
//
// Reads the English `title` and `description` of a community_projects row and
// fills in the 14 per-locale columns (title_<lang>, description_<lang> for ar,
// ur, fr, id, ms, ru, tr) via Google Translate's public web endpoint.
//
// Triggered by a Postgres `AFTER INSERT OR UPDATE OF title, description`
// trigger on community_projects via pg_net.http_post — see migration
// 20260623_010_community_projects_auto_translate_trigger.sql.
//
// Manual invocation (e.g. to backfill or re-translate a single row):
//   curl -X POST <function-url> \
//     -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
//     -H "Content-Type: application/json" \
//     -d '{"project_id":"<uuid>"}'
//
// Why Google Translate's free endpoint: same one the in-app `TranslationService`
// already uses for short benefit lines. No API key, no quota signup. The
// non-public `translate_a/single` endpoint has no SLA but is very reliable for
// short strings (single titles, paragraph-long descriptions). If a single
// translation fails, we leave that column NULL so the client falls back to
// English — no row-level failure.

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
      // Short timeout so a slow language doesn't hold up the whole batch.
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) return null;
    const body = await res.json();
    // Response shape: [[[ "<translated>", "<original>", null, null, 1 ], ...], ...]
    // Concatenate every chunk in the outer first array to keep multi-sentence
    // input intact.
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

  let projectId: string;
  try {
    const body = await req.json();
    projectId = body?.project_id;
    if (!projectId || typeof projectId !== "string") {
      return jsonResponse({ error: "Missing project_id" }, 400);
    }
  } catch (_) {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  // 1) Fetch English title + description
  const fetchRes = await fetch(
    `${supabaseUrl}/rest/v1/community_projects?id=eq.${projectId}&select=title,description`,
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
    return jsonResponse({ error: "Project not found" }, 404);
  }

  const title = (row.title as string | null) ?? "";
  const description = (row.description as string | null) ?? "";

  // 2) Translate to each target language in parallel.
  // Per-call failures leave that column NULL — client falls back to English.
  const tasks = TARGET_LANGS.map(async (lang) => {
    const [tTitle, tDesc] = await Promise.all([
      translate(title, lang),
      translate(description, lang),
    ]);
    return { lang, tTitle, tDesc };
  });
  const results = await Promise.all(tasks);

  // 3) Build the PATCH payload of only the locale columns.
  const patch: Record<string, string | null> = {};
  for (const r of results) {
    patch[`title_${r.lang}`] = r.tTitle;
    patch[`description_${r.lang}`] = r.tDesc;
  }

  // 4) Apply the update. Authorization with service-role bypasses RLS.
  const updateRes = await fetch(
    `${supabaseUrl}/rest/v1/community_projects?id=eq.${projectId}`,
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
    title: r.tTitle ? "ok" : "skip",
    description: r.tDesc ? "ok" : "skip",
  }));
  return jsonResponse({ project_id: projectId, translated: summary });
});
