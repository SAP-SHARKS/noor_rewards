"use client";

import { useEffect, useState, useRef } from "react";
import { supabase } from "@/lib/supabase";

// ── Types ────────────────────────────────────────────────────────────────────

type Orphan = {
  id: string;
  first_name: string;
  last_initial: string;
  age: number;
  gender: "male" | "female" | "";
  grade: string;
  school: string;
  city: string;
  country: string;
  father_passed_cause: string;
  mother_status: string;
  siblings_count: number;
  story: string;
  photo_url: string;
  target_seeds: number;
  min_sponsorship: number;
  partner_org: string;
  is_active: boolean;
  sort_order: number;
};

type OrphanStats = {
  current_seeds: number;
  sponsor_count: number;
};

const EMPTY: Omit<Orphan, "id"> = {
  first_name: "",
  last_initial: "",
  age: 0,
  gender: "",
  grade: "",
  school: "",
  city: "",
  country: "",
  father_passed_cause: "",
  mother_status: "",
  siblings_count: 0,
  story: "",
  photo_url: "",
  target_seeds: 1000,
  min_sponsorship: 50,
  partner_org: "",
  is_active: true,
  sort_order: 0,
};

const BUCKET = "orphan-photos";

// CSV column order — share this with the bulk-upload template
const CSV_COLUMNS: (keyof Omit<Orphan, "id">)[] = [
  "first_name",
  "last_initial",
  "age",
  "gender",
  "grade",
  "school",
  "city",
  "country",
  "father_passed_cause",
  "mother_status",
  "siblings_count",
  "story",
  "target_seeds",
  "min_sponsorship",
  "partner_org",
  "sort_order",
];

// ── Helpers ──────────────────────────────────────────────────────────────────

function pct(current: number, target: number): number {
  if (target <= 0) return 0;
  return Math.min(100, Math.round((current / target) * 100));
}

function mimeFor(ext: string): string {
  if (ext === "png") return "image/png";
  if (ext === "webp") return "image/webp";
  return "image/jpeg";
}

// Minimal CSV parser — handles quoted fields with commas, double-quote escaping.
// Returns array of row objects keyed by header.
function parseCSV(text: string): Record<string, string>[] {
  const rows: string[][] = [];
  let cur: string[] = [];
  let field = "";
  let inQuotes = false;
  let i = 0;
  const n = text.length;
  while (i < n) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') {
        if (i + 1 < n && text[i + 1] === '"') {
          field += '"';
          i += 2;
          continue;
        }
        inQuotes = false;
        i++;
        continue;
      }
      field += c;
      i++;
      continue;
    }
    if (c === '"') {
      inQuotes = true;
      i++;
      continue;
    }
    if (c === ",") {
      cur.push(field);
      field = "";
      i++;
      continue;
    }
    if (c === "\n" || c === "\r") {
      cur.push(field);
      rows.push(cur);
      cur = [];
      field = "";
      // swallow \r\n
      if (c === "\r" && i + 1 < n && text[i + 1] === "\n") i += 2;
      else i++;
      continue;
    }
    field += c;
    i++;
  }
  if (field.length > 0 || cur.length > 0) {
    cur.push(field);
    rows.push(cur);
  }
  // strip empty trailing rows
  const cleaned = rows.filter((r) => r.some((v) => v.trim().length > 0));
  if (cleaned.length === 0) return [];
  const header = cleaned[0].map((h) => h.trim());
  return cleaned.slice(1).map((row) => {
    const obj: Record<string, string> = {};
    header.forEach((h, idx) => {
      obj[h] = (row[idx] ?? "").trim();
    });
    return obj;
  });
}

function csvTemplate(): string {
  const header = CSV_COLUMNS.join(",");
  const example = [
    "Amina",
    "K",
    "9",
    "female",
    "Grade 4",
    "Iqra Primary School",
    "Karachi",
    "Pakistan",
    "Heart attack while at work",
    "alive",
    "3",
    "Amina lives with her mother and three siblings. She loves reading.",
    "1000",
    "50",
    "Helping Hand",
    "1",
  ];
  // wrap fields containing commas in quotes
  const row = example
    .map((v) => (v.includes(",") || v.includes('"') ? `"${v.replace(/"/g, '""')}"` : v))
    .join(",");
  return `${header}\n${row}\n`;
}

// ── Component ────────────────────────────────────────────────────────────────

export default function OrphansPage() {
  const [orphans, setOrphans] = useState<Orphan[]>([]);
  const [stats, setStats] = useState<Record<string, OrphanStats>>({});
  const [loading, setLoading] = useState(true);
  const [view, setView] = useState<"list" | "form" | "import">("list");
  const [editing, setEditing] = useState<Orphan | null>(null);
  const [form, setForm] = useState<Omit<Orphan, "id">>(EMPTY);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const photoRef = useRef<HTMLInputElement>(null);

  // CSV import state
  const [csvRows, setCsvRows] = useState<Record<string, string>[]>([]);
  const [csvErrors, setCsvErrors] = useState<string[]>([]);
  const [importing, setImporting] = useState(false);
  const csvFileRef = useRef<HTMLInputElement>(null);

  // ── Data loading ─────────────────────────────────────────────────────────
  useEffect(() => {
    loadOrphans();
  }, []);

  async function loadOrphans() {
    setLoading(true);
    const { data } = await supabase
      .from("sponsored_orphans")
      .select("*")
      .order("sort_order", { ascending: true })
      .order("created_at", { ascending: false });
    const list = (data ?? []) as Orphan[];
    setOrphans(list);
    if (list.length > 0) {
      const { data: statsData } = await supabase.rpc("get_orphan_stats_bulk", {
        p_orphan_ids: list.map((o) => o.id),
      });
      const map: Record<string, OrphanStats> = {};
      (statsData ?? []).forEach((r: { orphan_id: string; current_seeds: number; sponsor_count: number }) => {
        map[r.orphan_id] = {
          current_seeds: Number(r.current_seeds),
          sponsor_count: Number(r.sponsor_count),
        };
      });
      setStats(map);
    }
    setLoading(false);
  }

  // ── CRUD ────────────────────────────────────────────────────────────────
  function startCreate() {
    setEditing(null);
    setForm({ ...EMPTY, sort_order: orphans.length });
    setView("form");
  }

  function startEdit(o: Orphan) {
    setEditing(o);
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { id, ...rest } = o;
    setForm(rest);
    setView("form");
  }

  async function save() {
    if (!form.first_name.trim()) {
      alert("First name is required.");
      return;
    }
    setSaving(true);
    try {
      if (editing) {
        const { error } = await supabase
          .from("sponsored_orphans")
          .update(form)
          .eq("id", editing.id);
        if (error) throw error;
      } else {
        const { error } = await supabase
          .from("sponsored_orphans")
          .insert(form);
        if (error) throw error;
      }
      await loadOrphans();
      setView("list");
    } catch (e) {
      alert(`Save failed: ${e instanceof Error ? e.message : String(e)}`);
    } finally {
      setSaving(false);
    }
  }

  async function remove(o: Orphan) {
    if (!confirm(`Delete ${o.first_name}? This cannot be undone.`)) return;
    const { error } = await supabase
      .from("sponsored_orphans")
      .delete()
      .eq("id", o.id);
    if (error) {
      alert(`Delete failed: ${error.message}`);
      return;
    }
    await loadOrphans();
  }

  async function toggleActive(o: Orphan) {
    const { error } = await supabase
      .from("sponsored_orphans")
      .update({ is_active: !o.is_active })
      .eq("id", o.id);
    if (error) {
      alert(`Update failed: ${error.message}`);
      return;
    }
    await loadOrphans();
  }

  // ── Photo upload ────────────────────────────────────────────────────────
  async function uploadPhoto(file: File): Promise<string | null> {
    setUploading(true);
    try {
      const ext = (file.name.split(".").pop() || "jpg").toLowerCase();
      const slug = (form.first_name || "orphan").toLowerCase().replace(/[^a-z0-9]+/g, "-");
      const path = `${slug}-${Date.now()}.${ext}`;
      const { error } = await supabase.storage.from(BUCKET).upload(path, file, {
        upsert: true,
        contentType: mimeFor(ext),
      });
      if (error) throw error;
      const { data } = supabase.storage.from(BUCKET).getPublicUrl(path);
      return data.publicUrl;
    } catch (e) {
      alert(`Photo upload failed: ${e instanceof Error ? e.message : String(e)}`);
      return null;
    } finally {
      setUploading(false);
    }
  }

  async function handlePhotoChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    const url = await uploadPhoto(file);
    if (url) setForm({ ...form, photo_url: url });
    if (photoRef.current) photoRef.current.value = "";
  }

  // ── CSV bulk import ─────────────────────────────────────────────────────
  function downloadTemplate() {
    const blob = new Blob([csvTemplate()], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "orphans-template.csv";
    a.click();
    URL.revokeObjectURL(url);
  }

  async function handleCsvFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    const text = await file.text();
    const rows = parseCSV(text);
    const errs: string[] = [];
    rows.forEach((r, i) => {
      if (!r.first_name) errs.push(`Row ${i + 2}: missing first_name`);
      const ageNum = Number(r.age);
      if (!Number.isFinite(ageNum) || ageNum < 0 || ageNum > 25) {
        errs.push(`Row ${i + 2}: invalid age "${r.age}"`);
      }
      if (r.gender && r.gender !== "male" && r.gender !== "female") {
        errs.push(`Row ${i + 2}: gender must be male/female (got "${r.gender}")`);
      }
    });
    setCsvRows(rows);
    setCsvErrors(errs);
    if (csvFileRef.current) csvFileRef.current.value = "";
  }

  async function commitImport() {
    if (csvRows.length === 0 || csvErrors.length > 0) return;
    setImporting(true);
    try {
      const payload = csvRows.map((r, idx) => ({
        first_name: r.first_name || "",
        last_initial: r.last_initial || null,
        age: Number(r.age) || 0,
        gender: r.gender || null,
        grade: r.grade || null,
        school: r.school || null,
        city: r.city || null,
        country: r.country || null,
        father_passed_cause: r.father_passed_cause || null,
        mother_status: r.mother_status || null,
        siblings_count: Number(r.siblings_count) || 0,
        story: r.story || null,
        target_seeds: Number(r.target_seeds) || 1000,
        min_sponsorship: Number(r.min_sponsorship) || 50,
        partner_org: r.partner_org || null,
        sort_order: Number(r.sort_order) || orphans.length + idx,
        is_active: true,
      }));
      const { error } = await supabase.from("sponsored_orphans").insert(payload);
      if (error) throw error;
      alert(`Imported ${payload.length} orphan${payload.length === 1 ? "" : "s"}.`);
      setCsvRows([]);
      setCsvErrors([]);
      setView("list");
      await loadOrphans();
    } catch (e) {
      alert(`Import failed: ${e instanceof Error ? e.message : String(e)}`);
    } finally {
      setImporting(false);
    }
  }

  // ── Renders ─────────────────────────────────────────────────────────────

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  if (view === "form") return renderForm();
  if (view === "import") return renderImport();
  return renderList();

  // ────────────────────────────────────────────────────────────────────────

  function renderList() {
    return (
      <div className="space-y-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h1 className="text-2xl font-bold text-slate-900 dark:text-slate-100">
              Sponsored Orphans
            </h1>
            <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
              Manage the list of orphans displayed in the app for sponsorship.
            </p>
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => setView("import")}
              className="px-4 py-2 rounded-lg border border-slate-300 dark:border-slate-700 text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 text-sm font-medium"
            >
              Bulk Import (CSV)
            </button>
            <button
              onClick={startCreate}
              className="px-4 py-2 rounded-lg bg-teal-600 hover:bg-teal-700 text-white text-sm font-medium"
            >
              + Add Orphan
            </button>
          </div>
        </div>

        {orphans.length === 0 ? (
          <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-12 text-center">
            <div className="text-slate-500 dark:text-slate-400 text-sm">
              No orphans added yet. Click <span className="font-medium">+ Add Orphan</span> or{" "}
              <span className="font-medium">Bulk Import</span> to get started.
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {orphans.map((o) => {
              const s = stats[o.id] ?? { current_seeds: 0, sponsor_count: 0 };
              const progress = pct(s.current_seeds, o.target_seeds);
              return (
                <div
                  key={o.id}
                  className={`bg-white dark:bg-slate-800 rounded-xl border ${
                    o.is_active
                      ? "border-slate-200 dark:border-slate-700"
                      : "border-slate-200 dark:border-slate-700 opacity-60"
                  } overflow-hidden flex flex-col`}
                >
                  <div className="aspect-[4/3] bg-slate-100 dark:bg-slate-900 relative">
                    {o.photo_url ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={o.photo_url}
                        alt={o.first_name}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-slate-300 dark:text-slate-600 text-5xl">
                        {o.first_name.charAt(0).toUpperCase() || "?"}
                      </div>
                    )}
                    {!o.is_active && (
                      <div className="absolute top-2 right-2 bg-red-500 text-white text-xs px-2 py-0.5 rounded-full font-medium">
                        Inactive
                      </div>
                    )}
                  </div>
                  <div className="p-4 flex flex-col gap-2 flex-1">
                    <div className="flex items-baseline justify-between">
                      <div className="font-semibold text-slate-900 dark:text-slate-100">
                        {o.first_name}
                        {o.last_initial ? ` ${o.last_initial}.` : ""}
                        <span className="text-slate-500 dark:text-slate-400 font-normal text-sm">
                          {" "}
                          · {o.age}
                        </span>
                      </div>
                      {o.grade && (
                        <span className="text-xs px-2 py-0.5 rounded-full bg-teal-50 dark:bg-teal-900/30 text-teal-700 dark:text-teal-300">
                          {o.grade}
                        </span>
                      )}
                    </div>
                    {(o.city || o.country) && (
                      <div className="text-xs text-slate-500 dark:text-slate-400">
                        {[o.city, o.country].filter(Boolean).join(", ")}
                      </div>
                    )}
                    <div className="mt-1">
                      <div className="h-1.5 bg-slate-100 dark:bg-slate-700 rounded-full overflow-hidden">
                        <div
                          className="h-full bg-teal-500"
                          style={{ width: `${progress}%` }}
                        />
                      </div>
                      <div className="flex justify-between text-xs text-slate-500 dark:text-slate-400 mt-1">
                        <span>
                          {s.current_seeds.toLocaleString()} / {o.target_seeds.toLocaleString()} seeds
                        </span>
                        <span>
                          {s.sponsor_count} sponsor{s.sponsor_count === 1 ? "" : "s"}
                        </span>
                      </div>
                    </div>
                    <div className="flex gap-2 mt-2">
                      <button
                        onClick={() => startEdit(o)}
                        className="flex-1 text-xs py-1.5 rounded-md bg-slate-100 dark:bg-slate-700 hover:bg-slate-200 dark:hover:bg-slate-600 text-slate-700 dark:text-slate-200"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => toggleActive(o)}
                        className="flex-1 text-xs py-1.5 rounded-md bg-slate-100 dark:bg-slate-700 hover:bg-slate-200 dark:hover:bg-slate-600 text-slate-700 dark:text-slate-200"
                      >
                        {o.is_active ? "Deactivate" : "Activate"}
                      </button>
                      <button
                        onClick={() => remove(o)}
                        className="text-xs py-1.5 px-3 rounded-md bg-red-50 dark:bg-red-900/30 hover:bg-red-100 dark:hover:bg-red-900/50 text-red-600 dark:text-red-400"
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    );
  }

  function renderForm() {
    return (
      <div className="space-y-6 max-w-3xl">
        <div className="flex items-center justify-between gap-3">
          <h1 className="text-2xl font-bold text-slate-900 dark:text-slate-100">
            {editing ? `Edit ${editing.first_name}` : "Add Orphan"}
          </h1>
          <button
            onClick={() => setView("list")}
            className="text-sm text-slate-600 dark:text-slate-300 hover:underline"
          >
            ← Back to list
          </button>
        </div>

        {/* Photo */}
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-5">
          <label className="block text-sm font-medium text-slate-700 dark:text-slate-200 mb-2">
            Photo
          </label>
          <div className="flex items-start gap-4">
            <div className="w-32 h-32 rounded-xl overflow-hidden bg-slate-100 dark:bg-slate-900 flex items-center justify-center text-slate-300 dark:text-slate-600">
              {form.photo_url ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={form.photo_url} alt="" className="w-full h-full object-cover" />
              ) : (
                <span className="text-4xl">
                  {form.first_name.charAt(0).toUpperCase() || "?"}
                </span>
              )}
            </div>
            <div className="flex-1">
              <input
                ref={photoRef}
                type="file"
                accept="image/jpeg,image/png,image/webp"
                onChange={handlePhotoChange}
                className="block text-sm"
              />
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-2">
                Portrait orientation recommended. Max 10MB. JPG / PNG / WebP.
              </p>
              {uploading && (
                <p className="text-xs text-teal-600 mt-1">Uploading…</p>
              )}
              {form.photo_url && (
                <button
                  onClick={() => setForm({ ...form, photo_url: "" })}
                  className="text-xs text-red-600 hover:underline mt-2"
                >
                  Remove photo
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Identity */}
        <Section title="Identity">
          <Row>
            <Field label="First name *" span={2}>
              <Input
                value={form.first_name}
                onChange={(v) => setForm({ ...form, first_name: v })}
              />
            </Field>
            <Field label="Last initial">
              <Input
                value={form.last_initial}
                onChange={(v) => setForm({ ...form, last_initial: v })}
                placeholder="e.g. K"
              />
            </Field>
          </Row>
          <Row>
            <Field label="Age *">
              <Input
                type="number"
                value={String(form.age)}
                onChange={(v) => setForm({ ...form, age: Number(v) || 0 })}
              />
            </Field>
            <Field label="Gender">
              <Select
                value={form.gender}
                onChange={(v) =>
                  setForm({ ...form, gender: v as "male" | "female" | "" })
                }
                options={[
                  { value: "", label: "—" },
                  { value: "male", label: "Male" },
                  { value: "female", label: "Female" },
                ]}
              />
            </Field>
            <Field label="Grade">
              <Input
                value={form.grade}
                onChange={(v) => setForm({ ...form, grade: v })}
                placeholder="e.g. Grade 4"
              />
            </Field>
          </Row>
          <Row>
            <Field label="School" span={3}>
              <Input
                value={form.school}
                onChange={(v) => setForm({ ...form, school: v })}
              />
            </Field>
          </Row>
        </Section>

        {/* Location */}
        <Section title="Location">
          <Row>
            <Field label="City">
              <Input value={form.city} onChange={(v) => setForm({ ...form, city: v })} />
            </Field>
            <Field label="Country">
              <Input
                value={form.country}
                onChange={(v) => setForm({ ...form, country: v })}
              />
            </Field>
          </Row>
        </Section>

        {/* Family */}
        <Section title="Family">
          <Row>
            <Field label="How the father passed (one sentence)" span={3}>
              <Input
                value={form.father_passed_cause}
                onChange={(v) => setForm({ ...form, father_passed_cause: v })}
                placeholder="e.g. Heart attack while at work"
              />
            </Field>
          </Row>
          <Row>
            <Field label="Mother status">
              <Input
                value={form.mother_status}
                onChange={(v) => setForm({ ...form, mother_status: v })}
                placeholder="e.g. alive, passed, remarried"
              />
            </Field>
            <Field label="Siblings count">
              <Input
                type="number"
                value={String(form.siblings_count)}
                onChange={(v) =>
                  setForm({ ...form, siblings_count: Number(v) || 0 })
                }
              />
            </Field>
          </Row>
        </Section>

        {/* Story */}
        <Section title="Story">
          <Field label="Their story (2–3 sentences shown on detail screen)">
            <Textarea
              value={form.story}
              onChange={(v) => setForm({ ...form, story: v })}
              rows={4}
            />
          </Field>
        </Section>

        {/* Sponsorship + admin */}
        <Section title="Sponsorship">
          <Row>
            <Field label="Target seeds">
              <Input
                type="number"
                value={String(form.target_seeds)}
                onChange={(v) =>
                  setForm({ ...form, target_seeds: Number(v) || 0 })
                }
              />
            </Field>
            <Field label="Min sponsorship (per donation)">
              <Input
                type="number"
                value={String(form.min_sponsorship)}
                onChange={(v) =>
                  setForm({ ...form, min_sponsorship: Number(v) || 0 })
                }
              />
            </Field>
            <Field label="Partner organization">
              <Input
                value={form.partner_org}
                onChange={(v) => setForm({ ...form, partner_org: v })}
              />
            </Field>
          </Row>
          <Row>
            <Field label="Sort order (lower = first)">
              <Input
                type="number"
                value={String(form.sort_order)}
                onChange={(v) => setForm({ ...form, sort_order: Number(v) || 0 })}
              />
            </Field>
            <Field label="Active">
              <label className="flex items-center gap-2 text-sm text-slate-700 dark:text-slate-200">
                <input
                  type="checkbox"
                  checked={form.is_active}
                  onChange={(e) =>
                    setForm({ ...form, is_active: e.target.checked })
                  }
                />
                Visible in the app
              </label>
            </Field>
          </Row>
        </Section>

        <div className="flex justify-end gap-2 pt-4">
          <button
            onClick={() => setView("list")}
            className="px-4 py-2 rounded-lg border border-slate-300 dark:border-slate-700 text-slate-700 dark:text-slate-200 text-sm font-medium"
          >
            Cancel
          </button>
          <button
            onClick={save}
            disabled={saving || uploading}
            className="px-5 py-2 rounded-lg bg-teal-600 hover:bg-teal-700 disabled:opacity-50 text-white text-sm font-medium"
          >
            {saving ? "Saving…" : editing ? "Save changes" : "Add orphan"}
          </button>
        </div>
      </div>
    );
  }

  function renderImport() {
    const hasFile = csvRows.length > 0;
    const canCommit = hasFile && csvErrors.length === 0;
    return (
      <div className="space-y-6 max-w-4xl">
        <div className="flex items-center justify-between gap-3">
          <h1 className="text-2xl font-bold text-slate-900 dark:text-slate-100">
            Bulk Import Orphans
          </h1>
          <button
            onClick={() => {
              setCsvRows([]);
              setCsvErrors([]);
              setView("list");
            }}
            className="text-sm text-slate-600 dark:text-slate-300 hover:underline"
          >
            ← Back to list
          </button>
        </div>

        <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-5 space-y-3">
          <h2 className="text-sm font-semibold text-slate-900 dark:text-slate-100">
            How it works
          </h2>
          <ol className="text-sm text-slate-600 dark:text-slate-300 list-decimal pl-5 space-y-1">
            <li>Download the CSV template.</li>
            <li>Fill in one row per orphan in Excel / Google Sheets. Save as CSV.</li>
            <li>Upload the CSV here, review the preview, then click Import.</li>
            <li>Photos are NOT imported via CSV — upload them per-orphan after import using <span className="font-medium">Edit</span>.</li>
          </ol>
          <div className="flex gap-2 pt-2">
            <button
              onClick={downloadTemplate}
              className="px-4 py-2 rounded-lg border border-slate-300 dark:border-slate-700 text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 text-sm font-medium"
            >
              Download CSV template
            </button>
            <label className="px-4 py-2 rounded-lg bg-teal-600 hover:bg-teal-700 text-white text-sm font-medium cursor-pointer">
              Upload CSV
              <input
                ref={csvFileRef}
                type="file"
                accept=".csv,text/csv"
                onChange={handleCsvFile}
                className="hidden"
              />
            </label>
          </div>
        </div>

        {csvErrors.length > 0 && (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-xl p-4">
            <h3 className="text-sm font-semibold text-red-700 dark:text-red-300 mb-2">
              {csvErrors.length} issue{csvErrors.length === 1 ? "" : "s"} — fix them in your sheet and re-upload
            </h3>
            <ul className="text-xs text-red-700 dark:text-red-300 space-y-0.5 list-disc pl-5">
              {csvErrors.slice(0, 20).map((e, i) => (
                <li key={i}>{e}</li>
              ))}
              {csvErrors.length > 20 && <li>… and {csvErrors.length - 20} more</li>}
            </ul>
          </div>
        )}

        {hasFile && (
          <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 overflow-hidden">
            <div className="p-4 border-b border-slate-200 dark:border-slate-700 flex items-center justify-between">
              <div className="text-sm text-slate-700 dark:text-slate-200">
                <span className="font-semibold">{csvRows.length}</span> row
                {csvRows.length === 1 ? "" : "s"} ready to import
              </div>
              <button
                onClick={commitImport}
                disabled={!canCommit || importing}
                className="px-4 py-2 rounded-lg bg-teal-600 hover:bg-teal-700 disabled:opacity-50 text-white text-sm font-medium"
              >
                {importing ? "Importing…" : `Import ${csvRows.length}`}
              </button>
            </div>
            <div className="overflow-x-auto">
              <table className="text-xs w-full">
                <thead className="bg-slate-50 dark:bg-slate-900">
                  <tr>
                    {CSV_COLUMNS.map((c) => (
                      <th
                        key={c}
                        className="text-left px-3 py-2 font-medium text-slate-600 dark:text-slate-300"
                      >
                        {c}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {csvRows.slice(0, 25).map((r, i) => (
                    <tr
                      key={i}
                      className="border-t border-slate-200 dark:border-slate-700"
                    >
                      {CSV_COLUMNS.map((c) => (
                        <td
                          key={c}
                          className="px-3 py-2 text-slate-700 dark:text-slate-300 max-w-xs truncate"
                        >
                          {r[c] || ""}
                        </td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
              {csvRows.length > 25 && (
                <div className="p-3 text-xs text-slate-500 dark:text-slate-400 text-center">
                  … {csvRows.length - 25} more rows not shown
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    );
  }
}

// ── Small layout helpers ─────────────────────────────────────────────────────

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-5 space-y-3">
      <h2 className="text-sm font-semibold text-slate-900 dark:text-slate-100">
        {title}
      </h2>
      {children}
    </div>
  );
}

function Row({ children }: { children: React.ReactNode }) {
  return <div className="grid grid-cols-1 md:grid-cols-3 gap-3">{children}</div>;
}

function Field({
  label,
  children,
  span,
}: {
  label: string;
  children: React.ReactNode;
  span?: number;
}) {
  const cls = span === 2 ? "md:col-span-2" : span === 3 ? "md:col-span-3" : "";
  return (
    <div className={cls}>
      <label className="block text-xs font-medium text-slate-700 dark:text-slate-200 mb-1">
        {label}
      </label>
      {children}
    </div>
  );
}

function Input({
  value,
  onChange,
  type,
  placeholder,
}: {
  value: string;
  onChange: (v: string) => void;
  type?: string;
  placeholder?: string;
}) {
  return (
    <input
      type={type ?? "text"}
      value={value}
      placeholder={placeholder}
      onChange={(e) => onChange(e.target.value)}
      className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
    />
  );
}

function Textarea({
  value,
  onChange,
  rows,
}: {
  value: string;
  onChange: (v: string) => void;
  rows?: number;
}) {
  return (
    <textarea
      value={value}
      rows={rows ?? 3}
      onChange={(e) => onChange(e.target.value)}
      className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
    />
  );
}

function Select({
  value,
  onChange,
  options,
}: {
  value: string;
  onChange: (v: string) => void;
  options: { value: string; label: string }[];
}) {
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
    >
      {options.map((o) => (
        <option key={o.value} value={o.value}>
          {o.label}
        </option>
      ))}
    </select>
  );
}
