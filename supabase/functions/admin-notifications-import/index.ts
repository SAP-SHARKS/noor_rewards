// admin-notifications-import
//
// Companion to admin-notifications-export. Accepts a CSV in the same
// column layout, computes a per-row diff against the current DB state,
// and either previews the diff (`mode: 'dry_run'`) or applies it
// (`mode: 'apply'`).
//
// Request body:
//   {
//     admin_user_id: string,
//     csv:           string,
//     mode:          'dry_run' | 'apply'
//   }
//
// Response body (both modes):
//   {
//     summary: { updated, inserted, unchanged, rejected },
//     changes: [
//       {
//         row:      number,          // 1-based CSV row (excluding header)
//         action:   'unchanged' | 'update' | 'insert' | 'reject',
//         id:       string | null,
//         type:     string,
//         locale:   string,
//         before:   { title, body, route, image_url, active } | null,
//         after:    { title, body, route, image_url, active } | null,
//         diff:     string[],        // list of column names that changed
//         reason?:  string,          // populated only when action='reject'
//       },
//       …
//     ],
//     applied: boolean               // true only in mode='apply'
//   }
//
// Validation rules for each row:
//   - locale must be in the 8-locale allowlist (en/ur/ar/fr/id/ms/ru/tr)
//   - notification_type non-empty
//   - title non-empty AND ≤ 100 chars
//   - body non-empty AND ≤ 400 chars
//   - `active` parseable as bool ('true'/'false'/'1'/'0')
//   - Every {placeholder} present in the ENGLISH row's title/body for
//     this notification_type must survive in the non-EN row (prevents an
//     AI translation from silently dropping the {streak}, {name}, etc.
//     tokens the client substitutes at send time).
//
// Auth model matches admin-test-push and admin-notifications-export.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const ALLOWED_LOCALES = new Set([
  'en',
  'ur',
  'ar',
  'fr',
  'id',
  'ms',
  'ru',
  'tr',
]);
const PLACEHOLDER_RE = /\{[a-zA-Z][a-zA-Z0-9_]*\}/g;

interface DbRow {
  id: string;
  notification_type: string;
  locale: string;
  active: boolean;
  title: string;
  body: string;
  route: string | null;
  image_url: string | null;
}

interface CsvRow {
  rowIndex: number;
  id: string | null;
  notification_type: string;
  locale: string;
  active: boolean;
  title: string;
  body: string;
  route: string | null;
  image_url: string | null;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { admin_user_id, csv, mode } = await req.json();
    if (!admin_user_id) return json({ error: 'admin_user_id missing' }, 403);
    if (typeof csv !== 'string' || csv.trim() === '') {
      return json({ error: 'csv missing or empty' }, 400);
    }
    if (mode !== 'dry_run' && mode !== 'apply') {
      return json({ error: `mode must be 'dry_run' or 'apply' (got ${mode})` }, 400);
    }

    const admin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const { data: roleRow } = await admin
      .from('app_roles')
      .select('role')
      .eq('user_id', admin_user_id)
      .eq('role', 'admin')
      .maybeSingle();
    if (!roleRow) return json({ error: `Forbidden — ${admin_user_id} is not an admin` }, 403);

    // ── Parse CSV ──────────────────────────────────────────────────────────
    let csvRows: CsvRow[];
    try {
      csvRows = parseCsv(csv);
    } catch (e) {
      return json({ error: `CSV parse error: ${(e as Error).message}` }, 400);
    }

    // ── Pull current DB rows keyed by id ──────────────────────────────────
    const { data: dbRows, error: fetchErr } = await admin
      .from('notification_variants')
      .select('id, notification_type, locale, active, title, body, route, image_url');
    if (fetchErr) return json({ error: `DB fetch failed: ${fetchErr.message}` }, 500);

    const dbById = new Map<string, DbRow>();
    for (const r of (dbRows ?? []) as DbRow[]) dbById.set(r.id, r);

    // Regression-only placeholder check: for each existing DB row we
    // remember the set of `{placeholders}` it currently has. On UPDATE
    // we require the incoming CSV version to still contain all of them
    // — this catches accidental drops (e.g. an AI translation stripping
    // {streak} from the Urdu title) without spuriously rejecting other
    // fine-but-different variants of the same notification_type that
    // legitimately don't use every placeholder.
    const placeholdersOf = (title: string, body: string): Set<string> => {
      const set = new Set<string>();
      for (const m of `${title}\n${body}`.matchAll(PLACEHOLDER_RE)) set.add(m[0]);
      return set;
    };
    const dbPlaceholdersById = new Map<string, Set<string>>();
    for (const r of (dbRows ?? []) as DbRow[]) {
      dbPlaceholdersById.set(r.id, placeholdersOf(r.title, r.body));
    }

    // ── Diff each CSV row against DB ──────────────────────────────────────
    const changes: unknown[] = [];
    const rejectedIds = new Set<string>();
    let updated = 0, inserted = 0, unchanged = 0, rejected = 0;

    for (const row of csvRows) {
      const reject = (reason: string) => {
        rejected++;
        rejectedIds.add(row.id ?? `__row_${row.rowIndex}`);
        changes.push({
          row: row.rowIndex,
          action: 'reject',
          id: row.id,
          type: row.notification_type,
          locale: row.locale,
          before: row.id ? snapshot(dbById.get(row.id)) : null,
          after: snapshot(row),
          diff: [],
          reason,
        });
      };

      if (!row.notification_type) return reject_early(row, 'notification_type is empty');

      // If this row already exists AND is byte-identical to the DB, it's
      // an untouched pass-through — mark unchanged and skip validation.
      // Otherwise pre-existing data that violates a modern rule would
      // spuriously get rejected on every round-trip.
      const existing = row.id ? dbById.get(row.id) : undefined;
      if (existing) {
        const diff = diffFields(existing, row);
        if (diff.length === 0) {
          unchanged++;
          changes.push({
            row: row.rowIndex,
            action: 'unchanged',
            id: row.id,
            type: row.notification_type,
            locale: row.locale,
            before: snapshot(existing),
            after: snapshot(row),
            diff,
          });
          continue;
        }
      }

      // Below here the row is either a new insert or a genuine update.
      // Validate — mistakes at this point are real regressions.
      if (!ALLOWED_LOCALES.has(row.locale)) { reject(`locale '${row.locale}' not in allowlist`); continue; }
      if (!row.title) { reject('title empty'); continue; }
      if (row.title.length > 100) { reject(`title too long (${row.title.length} > 100)`); continue; }
      if (!row.body) { reject('body empty'); continue; }
      if (row.body.length > 400) { reject(`body too long (${row.body.length} > 400)`); continue; }

      // Placeholder-regression check. Only enforced when updating an
      // existing row — for a brand-new insert we have no baseline to
      // compare against, so the admin is free to author whatever
      // placeholder set makes sense for that variant.
      if (existing) {
        const before = dbPlaceholdersById.get(existing.id) ?? new Set<string>();
        const after = placeholdersOf(row.title, row.body);
        const missing = [...before].filter((p) => !after.has(p));
        if (missing.length > 0) {
          reject(`placeholder(s) dropped vs. previous version: ${missing.join(', ')}`);
          continue;
        }
      }

      if (existing) {
        updated++;
        const diff = diffFields(existing, row);
        changes.push({
          row: row.rowIndex,
          action: 'update',
          id: row.id,
          type: row.notification_type,
          locale: row.locale,
          before: snapshot(existing),
          after: snapshot(row),
          diff,
        });
        continue;
      }

      // No id, or id doesn't exist in DB → insert.
      inserted++;
      changes.push({
        row: row.rowIndex,
        action: 'insert',
        id: null,
        type: row.notification_type,
        locale: row.locale,
        before: null,
        after: snapshot(row),
        diff: ['id', 'notification_type', 'locale', 'title', 'body', 'route', 'image_url', 'active'],
      });
    }

    const summary = { updated, inserted, unchanged, rejected };

    if (mode === 'dry_run') {
      return json({ summary, changes, applied: false });
    }

    // ── Apply ─────────────────────────────────────────────────────────────
    // Two passes to keep the writes readable: UPSERT for update+insert,
    // skip rejected + unchanged.
    const toWrite: Array<Partial<DbRow>> = [];
    for (const c of changes as Array<{ action: string; id: string | null; type: string; locale: string; after: any }>) {
      if (c.action === 'unchanged' || c.action === 'reject') continue;
      toWrite.push({
        ...(c.id ? { id: c.id } : {}),
        notification_type: c.type,
        locale: c.locale,
        title: c.after.title,
        body: c.after.body,
        route: c.after.route,
        image_url: c.after.image_url,
        active: c.after.active,
      });
    }

    if (toWrite.length === 0) {
      return json({ summary, changes, applied: true });
    }

    const { error: writeErr } = await admin
      .from('notification_variants')
      .upsert(toWrite, { onConflict: 'id' });
    if (writeErr) return json({ error: `UPSERT failed: ${writeErr.message}` }, 500);

    return json({ summary, changes, applied: true });
  } catch (err) {
    return json({ error: (err as Error).message ?? String(err) }, 500);
  }
});

function reject_early(row: CsvRow, reason: string): Response {
  return json({
    error: `row ${row.rowIndex}: ${reason}`,
  }, 400);
}

function snapshot(r: DbRow | CsvRow | undefined): unknown {
  if (!r) return null;
  return {
    title: r.title,
    body: r.body,
    route: r.route,
    image_url: r.image_url,
    active: r.active,
  };
}

function diffFields(before: DbRow, after: CsvRow): string[] {
  const fields: Array<keyof DbRow> = [
    'notification_type',
    'locale',
    'title',
    'body',
    'route',
    'image_url',
    'active',
  ];
  const diff: string[] = [];
  for (const f of fields) {
    const b = before[f] ?? null;
    const a = (after as unknown as Record<string, unknown>)[f] ?? null;
    if (b !== a) diff.push(f);
  }
  return diff;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// ── CSV parser (RFC-4180 with quoted fields + `""` escapes) ────────────────
function parseCsv(csv: string): CsvRow[] {
  const records = tokenizeCsv(csv);
  if (records.length === 0) throw new Error('CSV is empty');
  const header = records[0].map((h) => h.trim().toLowerCase());
  const required = ['notification_type', 'locale', 'title', 'body'];
  for (const r of required) {
    if (!header.includes(r)) throw new Error(`missing required column '${r}'`);
  }
  const idxOf = (name: string) => header.indexOf(name);
  const idI = idxOf('id');
  const typeI = idxOf('notification_type');
  const localeI = idxOf('locale');
  const activeI = idxOf('active');
  const titleI = idxOf('title');
  const bodyI = idxOf('body');
  const routeI = idxOf('route');
  const imageI = idxOf('image_url');

  const rows: CsvRow[] = [];
  for (let i = 1; i < records.length; i++) {
    const raw = records[i];
    if (raw.length === 1 && raw[0].trim() === '') continue; // blank line
    const val = (i: number): string => (i >= 0 && i < raw.length ? raw[i] : '');
    const boolField = (s: string): boolean => {
      const t = s.trim().toLowerCase();
      if (t === 'true' || t === '1') return true;
      if (t === 'false' || t === '0' || t === '') return false;
      throw new Error(`row ${i}: 'active' must be true/false/1/0 (got '${s}')`);
    };
    rows.push({
      rowIndex: i, // 1-based excluding header
      id: idI >= 0 && val(idI).trim() !== '' ? val(idI).trim() : null,
      notification_type: val(typeI).trim(),
      locale: val(localeI).trim(),
      active: activeI >= 0 ? boolField(val(activeI)) : true,
      title: val(titleI),
      body: val(bodyI),
      route: routeI >= 0 && val(routeI).trim() !== '' ? val(routeI).trim() : null,
      image_url: imageI >= 0 && val(imageI).trim() !== '' ? val(imageI).trim() : null,
    });
  }
  return rows;
}

function tokenizeCsv(csv: string): string[][] {
  const records: string[][] = [];
  let current: string[] = [];
  let field = '';
  let inQuotes = false;
  let i = 0;
  while (i < csv.length) {
    const c = csv[i];
    if (inQuotes) {
      if (c === '"') {
        if (csv[i + 1] === '"') { field += '"'; i += 2; continue; }
        inQuotes = false; i++; continue;
      }
      field += c; i++; continue;
    }
    if (c === '"') { inQuotes = true; i++; continue; }
    if (c === ',') { current.push(field); field = ''; i++; continue; }
    if (c === '\r') { i++; continue; }
    if (c === '\n') {
      current.push(field); records.push(current);
      current = []; field = ''; i++; continue;
    }
    field += c; i++;
  }
  // trailing field / record
  if (field !== '' || current.length > 0) {
    current.push(field);
    records.push(current);
  }
  return records;
}
