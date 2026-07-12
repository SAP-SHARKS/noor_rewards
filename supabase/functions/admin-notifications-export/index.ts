// admin-notifications-export
//
// Streams every row of `notification_variants` back as a CSV so admins can
// bulk-edit copy (and AI-assisted translations) in a spreadsheet and then
// upload the result via `admin-notifications-import`.
//
// Auth model: same shape as admin-test-push — client passes the caller's
// user_id in the body, we check `app_roles` for role='admin'. Random anon
// callers can't reach this in the first place (Supabase gateway blocks
// non-service invocations without the anon key), and among authenticated
// callers only real admins are accepted.
//
// Response is either JSON (error) or CSV (success). CSV columns:
//   id, notification_type, locale, active, title, body, route, image_url, created_at
//
// Empty strings are used for NULL route / image_url so the downstream sheet
// keeps the columns aligned. Multi-line bodies (a few streak_milestone
// variants contain newlines) are wrapped in RFC-4180 quotes with `""` for
// embedded quotes — Google Sheets and Excel both round-trip that cleanly.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const CSV_COLUMNS = [
  'id',
  'notification_type',
  'locale',
  'active',
  'title',
  'body',
  'route',
  'image_url',
  'created_at',
] as const;

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { admin_user_id } = await req.json();
    if (!admin_user_id) {
      return json({ error: 'admin_user_id missing' }, 403);
    }

    const admin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    // ── Admin gate ─────────────────────────────────────────────────────────
    const { data: roleRow } = await admin
      .from('app_roles')
      .select('role')
      .eq('user_id', admin_user_id)
      .eq('role', 'admin')
      .maybeSingle();
    if (!roleRow) {
      return json({ error: `Forbidden — ${admin_user_id} is not an admin` }, 403);
    }

    // ── Pull every row, ordered so the sheet reads naturally ───────────────
    // Type → locale → id keeps translations of the same variant next to
    // each other, and puts English first when its locale sorts first.
    const { data: rows, error } = await admin
      .from('notification_variants')
      .select(
        'id, notification_type, locale, active, title, body, route, image_url, created_at',
      )
      .order('notification_type', { ascending: true })
      .order('locale', { ascending: true })
      .order('id', { ascending: true });

    if (error) return json({ error: `Fetch failed: ${error.message}` }, 500);

    const lines: string[] = [CSV_COLUMNS.join(',')];
    for (const r of rows ?? []) {
      lines.push(
        CSV_COLUMNS
          .map((k) => csvEscape(r[k as keyof typeof r]))
          .join(','),
      );
    }
    const csv = lines.join('\n') + '\n';

    const stamp = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19);
    return new Response(csv, {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': `attachment; filename="notification_variants_${stamp}.csv"`,
      },
    });
  } catch (err) {
    return json({ error: (err as Error).message ?? String(err) }, 500);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// RFC-4180 CSV escape. Wraps in quotes if the value contains a comma,
// double-quote, CR, or LF; doubles any embedded quotes.
function csvEscape(v: unknown): string {
  if (v === null || v === undefined) return '';
  const s = typeof v === 'boolean' ? (v ? 'true' : 'false') : String(v);
  if (/[",\r\n]/.test(s)) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}
