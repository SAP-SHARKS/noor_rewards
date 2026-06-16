"use client";

import { useEffect, useMemo, useState } from "react";
import { supabase } from "@/lib/supabase";

// ── Types ────────────────────────────────────────────────────────────────────
type Azkar = {
  id: string;
  arabic: string;
  transliteration: string | null;
  translation: string | null;
  recommended_count: number;
  category_id: string | null;
  reward: string | null;
  reference: string | null;
  sort_order: number;
  hadith_full: string | null;
  audio_url: string | null;
};

type Category = {
  id: string;
  label: string;
  sort_order: number;
};

type Animation = {
  id: string;
  key: string;
  name: string;
  description: string | null;
  icon: string | null;
  is_active: boolean;
  sort_order: number;
};

const EMPTY: Omit<Azkar, "id"> = {
  arabic: "",
  transliteration: "",
  translation: "",
  recommended_count: 1,
  category_id: null,
  reward: "",
  reference: "",
  sort_order: 0,
  hadith_full: "",
  audio_url: "",
};

// ── Component ────────────────────────────────────────────────────────────────
export default function AzkarPage() {
  const [azkar, setAzkar] = useState<Azkar[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [animations, setAnimations] = useState<Animation[]>([]);
  // azkar_id → list of category_ids
  const [itemCats, setItemCats] = useState<Record<string, string[]>>({});
  // azkar_id → list of animation_ids
  const [itemAnims, setItemAnims] = useState<Record<string, string[]>>({});

  const [loading, setLoading] = useState(true);
  const [view, setView] = useState<"list" | "form" | "animations">("list");
  const [editing, setEditing] = useState<Azkar | null>(null);
  const [form, setForm] = useState<Omit<Azkar, "id">>(EMPTY);
  const [formCats, setFormCats] = useState<Set<string>>(new Set());
  const [formAnims, setFormAnims] = useState<Set<string>>(new Set());
  const [saving, setSaving] = useState(false);

  const [filterCat, setFilterCat] = useState<string>("");
  const [search, setSearch] = useState("");

  // ── Load ────────────────────────────────────────────────────────────────
  useEffect(() => {
    loadAll();
  }, []);

  async function loadAll() {
    setLoading(true);
    const [aRes, cRes, animRes, aicRes, aiaRes] = await Promise.all([
      supabase.from("azkar_items").select("*").order("sort_order"),
      supabase.from("azkar_categories").select("id, label, sort_order").order("sort_order"),
      supabase.from("azkar_animations").select("*").order("sort_order"),
      supabase.from("azkar_item_categories").select("azkar_id, category_id"),
      supabase.from("azkar_item_animations").select("azkar_id, animation_id"),
    ]);
    setAzkar((aRes.data ?? []) as Azkar[]);
    setCategories((cRes.data ?? []) as Category[]);
    setAnimations((animRes.data ?? []) as Animation[]);

    const cats: Record<string, string[]> = {};
    for (const row of (aicRes.data ?? []) as { azkar_id: string; category_id: string }[]) {
      (cats[row.azkar_id] ??= []).push(row.category_id);
    }
    setItemCats(cats);

    const anims: Record<string, string[]> = {};
    for (const row of (aiaRes.data ?? []) as { azkar_id: string; animation_id: string }[]) {
      (anims[row.azkar_id] ??= []).push(row.animation_id);
    }
    setItemAnims(anims);

    setLoading(false);
  }

  // ── CRUD ────────────────────────────────────────────────────────────────
  function startCreate() {
    setEditing(null);
    setForm({ ...EMPTY });
    setFormCats(new Set());
    setFormAnims(new Set());
    setView("form");
  }

  function startEdit(a: Azkar) {
    setEditing(a);
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { id, ...rest } = a;
    setForm(rest);
    setFormCats(new Set(itemCats[a.id] ?? []));
    setFormAnims(new Set(itemAnims[a.id] ?? []));
    setView("form");
  }

  async function save() {
    if (!form.arabic.trim()) {
      alert("Arabic is required.");
      return;
    }
    setSaving(true);
    try {
      let azkarId = editing?.id;
      if (editing) {
        const { error } = await supabase
          .from("azkar_items")
          .update(form)
          .eq("id", editing.id);
        if (error) throw error;
      } else {
        // Insert and let Supabase auto-generate id if column allows it,
        // otherwise the user must pass an explicit id.
        const newId =
          form.arabic
            .replace(/\s+/g, "_")
            .substring(0, 30)
            .toLowerCase() + "_" + Date.now();
        const { error } = await supabase
          .from("azkar_items")
          .insert({ ...form, id: newId });
        if (error) throw error;
        azkarId = newId;
      }

      // Sync category junction
      const { error: delCatErr } = await supabase
        .from("azkar_item_categories")
        .delete()
        .eq("azkar_id", azkarId);
      if (delCatErr) throw delCatErr;
      if (formCats.size > 0) {
        const catRows = Array.from(formCats).map((cid) => ({
          azkar_id: azkarId,
          category_id: cid,
          sort_order: form.sort_order,
        }));
        const { error: insCatErr } = await supabase
          .from("azkar_item_categories")
          .insert(catRows);
        if (insCatErr) throw insCatErr;
      }

      // Sync animation junction
      const { error: delAnimErr } = await supabase
        .from("azkar_item_animations")
        .delete()
        .eq("azkar_id", azkarId);
      if (delAnimErr) throw delAnimErr;
      if (formAnims.size > 0) {
        const animRows = Array.from(formAnims).map((aid, idx) => ({
          azkar_id: azkarId,
          animation_id: aid,
          sort_order: idx,
        }));
        const { error: insAnimErr } = await supabase
          .from("azkar_item_animations")
          .insert(animRows);
        if (insAnimErr) throw insAnimErr;
      }

      await loadAll();
      setView("list");
    } catch (e) {
      alert(`Save failed: ${e instanceof Error ? e.message : String(e)}`);
    } finally {
      setSaving(false);
    }
  }

  async function remove(a: Azkar) {
    if (!confirm(`Delete this azkar? All category + animation tags will be removed too.`)) return;
    const { error } = await supabase.from("azkar_items").delete().eq("id", a.id);
    if (error) {
      alert(`Delete failed: ${error.message}`);
      return;
    }
    await loadAll();
  }

  // ── Filtering ───────────────────────────────────────────────────────────
  const filtered = useMemo(() => {
    let list = azkar;
    if (filterCat) {
      list = list.filter((a) => (itemCats[a.id] ?? []).includes(filterCat));
    }
    if (search.trim()) {
      const q = search.trim().toLowerCase();
      list = list.filter(
        (a) =>
          a.id.toLowerCase().includes(q) ||
          (a.transliteration ?? "").toLowerCase().includes(q) ||
          (a.translation ?? "").toLowerCase().includes(q) ||
          (a.arabic ?? "").toLowerCase().includes(q),
      );
    }
    return list;
  }, [azkar, filterCat, search, itemCats]);

  // ── Renders ─────────────────────────────────────────────────────────────
  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  if (view === "form") return renderForm();
  if (view === "animations") return renderAnimationsManager();
  return renderList();

  // ────────────────────────────────────────────────────────────────────────

  function renderList() {
    return (
      <div className="space-y-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h1 className="text-2xl font-bold text-slate-900 dark:text-slate-100">
              Azkar Library
            </h1>
            <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
              Manage all azkar. Each azkar can be tagged with multiple categories and rotate through a pool of animations.
            </p>
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => setView("animations")}
              className="px-4 py-2 rounded-lg border border-slate-300 dark:border-slate-700 text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 text-sm font-medium"
            >
              Manage Animations
            </button>
            <button
              onClick={startCreate}
              className="px-4 py-2 rounded-lg bg-teal-600 hover:bg-teal-700 text-white text-sm font-medium"
            >
              + New Azkar
            </button>
          </div>
        </div>

        {/* Filters */}
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-4 flex flex-wrap gap-3">
          <input
            type="text"
            placeholder="Search by id / transliteration / translation / arabic…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="flex-1 min-w-[240px] px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
          />
          <select
            value={filterCat}
            onChange={(e) => setFilterCat(e.target.value)}
            className="px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
          >
            <option value="">All categories</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.label}
              </option>
            ))}
          </select>
          <div className="text-sm text-slate-500 dark:text-slate-400 self-center">
            <span className="font-semibold">{filtered.length}</span> shown / {azkar.length} total
          </div>
        </div>

        {/* List */}
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-slate-50 dark:bg-slate-900">
                <tr>
                  <th className="text-left px-4 py-3 text-slate-600 dark:text-slate-300 font-medium">ID</th>
                  <th className="text-left px-4 py-3 text-slate-600 dark:text-slate-300 font-medium">Arabic</th>
                  <th className="text-left px-4 py-3 text-slate-600 dark:text-slate-300 font-medium">Categories</th>
                  <th className="text-left px-4 py-3 text-slate-600 dark:text-slate-300 font-medium">Animations</th>
                  <th className="text-right px-4 py-3 text-slate-600 dark:text-slate-300 font-medium">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((a) => {
                  const cats = (itemCats[a.id] ?? [])
                    .map((cid) => categories.find((c) => c.id === cid)?.label ?? cid);
                  const anims = (itemAnims[a.id] ?? [])
                    .map((aid) => animations.find((x) => x.id === aid)?.name ?? aid);
                  return (
                    <tr
                      key={a.id}
                      className="border-t border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-900"
                    >
                      <td className="px-4 py-3 text-slate-700 dark:text-slate-300 font-mono text-xs whitespace-nowrap">
                        {a.id}
                      </td>
                      <td className="px-4 py-3 text-slate-900 dark:text-slate-100 max-w-md">
                        <div
                          className="line-clamp-2 text-right"
                          style={{ fontFamily: "Amiri, serif" }}
                          dir="rtl"
                        >
                          {a.arabic}
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex flex-wrap gap-1">
                          {cats.length === 0 ? (
                            <span className="text-xs text-slate-400 italic">none</span>
                          ) : (
                            cats.map((c, i) => (
                              <span
                                key={i}
                                className="text-xs px-2 py-0.5 rounded-full bg-teal-50 dark:bg-teal-900/30 text-teal-700 dark:text-teal-300"
                              >
                                {c}
                              </span>
                            ))
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex flex-wrap gap-1">
                          {anims.length === 0 ? (
                            <span className="text-xs text-slate-400 italic">none</span>
                          ) : (
                            anims.map((n, i) => (
                              <span
                                key={i}
                                className="text-xs px-2 py-0.5 rounded-full bg-amber-50 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300"
                              >
                                {n}
                              </span>
                            ))
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-3 text-right whitespace-nowrap">
                        <button
                          onClick={() => startEdit(a)}
                          className="text-xs px-2.5 py-1 rounded bg-slate-100 dark:bg-slate-700 hover:bg-slate-200 dark:hover:bg-slate-600 text-slate-700 dark:text-slate-200 mr-2"
                        >
                          Edit
                        </button>
                        <button
                          onClick={() => remove(a)}
                          className="text-xs px-2.5 py-1 rounded bg-red-50 dark:bg-red-900/30 hover:bg-red-100 dark:hover:bg-red-900/50 text-red-600 dark:text-red-400"
                        >
                          Delete
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    );
  }

  function renderForm() {
    return (
      <div className="space-y-6 max-w-3xl">
        <div className="flex items-center justify-between gap-3">
          <h1 className="text-2xl font-bold text-slate-900 dark:text-slate-100">
            {editing ? `Edit ${editing.id}` : "New Azkar"}
          </h1>
          <button
            onClick={() => setView("list")}
            className="text-sm text-slate-600 dark:text-slate-300 hover:underline"
          >
            ← Back
          </button>
        </div>

        <Section title="Text">
          <Field label="Arabic *">
            <textarea
              value={form.arabic}
              onChange={(e) => setForm({ ...form, arabic: e.target.value })}
              rows={3}
              dir="rtl"
              style={{ fontFamily: "Amiri, serif", fontSize: 18 }}
              className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-teal-500"
            />
          </Field>
          <Field label="Transliteration">
            <textarea
              value={form.transliteration ?? ""}
              onChange={(e) => setForm({ ...form, transliteration: e.target.value })}
              rows={2}
              className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
            />
          </Field>
          <Field label="Translation">
            <textarea
              value={form.translation ?? ""}
              onChange={(e) => setForm({ ...form, translation: e.target.value })}
              rows={3}
              className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
            />
          </Field>
        </Section>

        <Section title="Counts & References">
          <Row>
            <Field label="Recommended count">
              <Input
                type="number"
                value={String(form.recommended_count)}
                onChange={(v) => setForm({ ...form, recommended_count: Number(v) || 1 })}
              />
            </Field>
            <Field label="Default category (legacy)">
              <Select
                value={form.category_id ?? ""}
                onChange={(v) => setForm({ ...form, category_id: v || null })}
                options={[
                  { value: "", label: "—" },
                  ...categories.map((c) => ({ value: c.id, label: c.label })),
                ]}
              />
            </Field>
            <Field label="Sort order">
              <Input
                type="number"
                value={String(form.sort_order)}
                onChange={(v) => setForm({ ...form, sort_order: Number(v) || 0 })}
              />
            </Field>
          </Row>
          <Field label="Reward">
            <Input
              value={form.reward ?? ""}
              onChange={(v) => setForm({ ...form, reward: v })}
            />
          </Field>
          <Field label="Reference">
            <Input
              value={form.reference ?? ""}
              onChange={(v) => setForm({ ...form, reference: v })}
            />
          </Field>
          <Field label="Audio URL">
            <Input
              value={form.audio_url ?? ""}
              onChange={(v) => setForm({ ...form, audio_url: v })}
              placeholder="https://..."
            />
          </Field>
          <Field label="Hadith (full text)">
            <textarea
              value={form.hadith_full ?? ""}
              onChange={(e) => setForm({ ...form, hadith_full: e.target.value })}
              rows={4}
              className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
            />
          </Field>
        </Section>

        <Section title="Categories (tags)">
          <p className="text-xs text-slate-500 dark:text-slate-400 mb-3">
            Pick every category this azkar should appear in. Pick at least one.
          </p>
          <ChipPicker
            options={categories.map((c) => ({ id: c.id, label: c.label }))}
            selected={formCats}
            onToggle={(id) => {
              const next = new Set(formCats);
              next.has(id) ? next.delete(id) : next.add(id);
              setFormCats(next);
            }}
            color="teal"
          />
        </Section>

        <Section title="Animations (daily rotation pool)">
          <p className="text-xs text-slate-500 dark:text-slate-400 mb-3">
            The app cycles through these one per day. Pick one or more — selected ones show a number indicating their order in the rotation.
          </p>
          <AnimationCardPicker
            animations={animations.filter((a) => a.is_active)}
            itemAnims={itemAnims}
            selected={formAnims}
            onToggle={(id) => {
              const next = new Set(formAnims);
              next.has(id) ? next.delete(id) : next.add(id);
              setFormAnims(next);
            }}
          />
        </Section>

        <div className="flex justify-end gap-2 pt-2">
          <button
            onClick={() => setView("list")}
            className="px-4 py-2 rounded-lg border border-slate-300 dark:border-slate-700 text-slate-700 dark:text-slate-200 text-sm font-medium"
          >
            Cancel
          </button>
          <button
            onClick={save}
            disabled={saving}
            className="px-5 py-2 rounded-lg bg-teal-600 hover:bg-teal-700 disabled:opacity-50 text-white text-sm font-medium"
          >
            {saving ? "Saving…" : editing ? "Save changes" : "Create azkar"}
          </button>
        </div>
      </div>
    );
  }

  function renderAnimationsManager() {
    return (
      <div className="space-y-6 max-w-4xl">
        <div className="flex items-center justify-between gap-3">
          <h1 className="text-2xl font-bold text-slate-900 dark:text-slate-100">
            Animations Catalog
          </h1>
          <button
            onClick={() => setView("list")}
            className="text-sm text-slate-600 dark:text-slate-300 hover:underline"
          >
            ← Back to azkar
          </button>
        </div>
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-5">
          <p className="text-sm text-slate-600 dark:text-slate-300">
            Animations are referenced by their <code className="bg-slate-100 dark:bg-slate-700 px-1 rounded">key</code> in
            the Flutter app. Adding a new key here also requires a matching case in <code>_buildIllustration</code>.
          </p>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-2">
            For now this view is read-only. Toggle active / add new via SQL or
            in a future iteration of this page.
          </p>
        </div>
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-slate-50 dark:bg-slate-900">
              <tr>
                <th className="text-left px-4 py-3 font-medium text-slate-600 dark:text-slate-300">Icon</th>
                <th className="text-left px-4 py-3 font-medium text-slate-600 dark:text-slate-300">Key</th>
                <th className="text-left px-4 py-3 font-medium text-slate-600 dark:text-slate-300">Name</th>
                <th className="text-left px-4 py-3 font-medium text-slate-600 dark:text-slate-300">Description</th>
                <th className="text-left px-4 py-3 font-medium text-slate-600 dark:text-slate-300">Used by</th>
              </tr>
            </thead>
            <tbody>
              {animations.map((a) => {
                const usedBy = Object.entries(itemAnims).filter(([, ids]) =>
                  ids.includes(a.id),
                ).length;
                return (
                  <tr
                    key={a.id}
                    className="border-t border-slate-200 dark:border-slate-700"
                  >
                    <td className="px-4 py-3 text-xl">{a.icon ?? "·"}</td>
                    <td className="px-4 py-3 font-mono text-xs text-slate-700 dark:text-slate-300">
                      {a.key}
                    </td>
                    <td className="px-4 py-3 text-slate-900 dark:text-slate-100">{a.name}</td>
                    <td className="px-4 py-3 text-slate-500 dark:text-slate-400 text-xs">
                      {a.description}
                    </td>
                    <td className="px-4 py-3 text-slate-500 dark:text-slate-400">
                      {usedBy} azkar
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    );
  }
}

// ── Small layout helpers ─────────────────────────────────────────────────────

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-5 space-y-3">
      <h2 className="text-sm font-semibold text-slate-900 dark:text-slate-100">{title}</h2>
      {children}
    </div>
  );
}

function Row({ children }: { children: React.ReactNode }) {
  return <div className="grid grid-cols-1 md:grid-cols-3 gap-3">{children}</div>;
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label className="block text-xs font-medium text-slate-700 dark:text-slate-200 mb-1">
        {label}
      </label>
      {children}
    </div>
  );
}

function Input({
  value, onChange, type, placeholder,
}: {
  value: string; onChange: (v: string) => void; type?: string; placeholder?: string;
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

function Select({
  value, onChange, options,
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

// Public URL for an animation preview PNG. Generated by the Flutter
// "lib/preview_gen_main.dart" tool that uploads to Supabase Storage. If the
// PNG hasn't been generated yet, the <img> will 404 and the emoji shows.
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
function previewUrl(animKey: string) {
  return `${SUPABASE_URL}/storage/v1/object/public/animation-previews/${encodeURIComponent(animKey)}.png`;
}

// Thumbnail that prefers a real captured preview PNG from Supabase Storage,
// falling back to the emoji icon when the upload hasn't been generated yet.
function PreviewThumb({
  animKey,
  fallbackIcon,
}: {
  animKey: string;
  fallbackIcon: string;
}) {
  const [broken, setBroken] = useState(false);
  if (broken || !SUPABASE_URL) {
    return (
      <div className="w-full aspect-square rounded-md bg-slate-50 dark:bg-slate-900/40 flex items-center justify-center text-4xl border border-slate-200 dark:border-slate-700">
        {fallbackIcon}
      </div>
    );
  }
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={previewUrl(animKey)}
      alt={animKey}
      onError={() => setBroken(true)}
      className="w-full aspect-square rounded-md object-cover bg-slate-50 dark:bg-slate-900/40 border border-slate-200 dark:border-slate-700"
      loading="lazy"
    />
  );
}

// Rich card grid for animation selection — shows the actual rendered
// illustration (captured by lib/preview_gen_main.dart) so admins pick
// by sight instead of guessing from emojis.
function AnimationCardPicker({
  animations,
  itemAnims,
  selected,
  onToggle,
}: {
  animations: Animation[];
  itemAnims: Record<string, string[]>;
  selected: Set<string>;
  onToggle: (id: string) => void;
}) {
  // Stable order: selected items get a rotation-order badge based on the
  // insertion order in the Set, but we render every option in the same place.
  const orderById = new Map<string, number>();
  Array.from(selected).forEach((id, i) => orderById.set(id, i + 1));

  // Pre-compute "used by N azkar" so the admin sees popularity at a glance.
  const usageCount = (animId: string) =>
    Object.values(itemAnims).reduce(
      (n, ids) => (ids.includes(animId) ? n + 1 : n),
      0,
    );

  if (animations.length === 0) {
    return (
      <div className="text-sm text-slate-400 italic">
        No active animations. Manage them in the Animations Catalog.
      </div>
    );
  }

  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-2.5">
      {animations.map((a) => {
        const on = selected.has(a.id);
        const order = orderById.get(a.id);
        const used = usageCount(a.id);
        return (
          <button
            key={a.id}
            type="button"
            onClick={() => onToggle(a.id)}
            className={`relative text-left p-3 rounded-lg border-2 transition cursor-pointer ${
              on
                ? "border-teal-500 bg-teal-50 dark:bg-teal-900/20 ring-2 ring-teal-100 dark:ring-teal-900/40"
                : "border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 hover:border-slate-300 dark:hover:border-slate-600"
            }`}
          >
            {/* Rotation-order badge */}
            {on && order && (
              <span
                className="absolute -top-1.5 -right-1.5 w-5 h-5 rounded-full bg-teal-600 text-white text-[10px] font-bold flex items-center justify-center shadow"
                title={`#${order} in today's rotation order`}
              >
                {order}
              </span>
            )}

            {/* Real illustration preview (captured by the Flutter
                preview generator). Emoji fallback if PNG missing. */}
            <PreviewThumb animKey={a.key} fallbackIcon={a.icon ?? "✨"} />

            <div className="mt-2">
              <p
                className={`text-sm font-semibold truncate ${
                  on
                    ? "text-teal-900 dark:text-teal-100"
                    : "text-slate-800 dark:text-slate-100"
                }`}
              >
                {a.name}
              </p>
              <p className="text-[10px] font-mono text-slate-400 dark:text-slate-500 truncate">
                {a.key}
              </p>
              {a.description && (
                <p className="mt-1 text-[11px] text-slate-500 dark:text-slate-400 line-clamp-2">
                  {a.description}
                </p>
              )}
              <p className="mt-1 text-[10px] text-slate-400 dark:text-slate-500">
                used by {used} azkar
              </p>
            </div>
          </button>
        );
      })}
    </div>
  );
}

function ChipPicker({
  options, selected, onToggle, color,
}: {
  options: { id: string; label: string }[];
  selected: Set<string>;
  onToggle: (id: string) => void;
  color: "teal" | "amber";
}) {
  const selectedCls = color === "teal"
    ? "bg-teal-600 text-white border-teal-700"
    : "bg-amber-500 text-white border-amber-600";
  const idleCls = "bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-200 border-slate-200 dark:border-slate-600";
  if (options.length === 0) {
    return <div className="text-sm text-slate-400 italic">No options available.</div>;
  }
  return (
    <div className="flex flex-wrap gap-2">
      {options.map((o) => {
        const on = selected.has(o.id);
        return (
          <button
            key={o.id}
            type="button"
            onClick={() => onToggle(o.id)}
            className={`px-3 py-1.5 rounded-full border text-xs font-medium transition ${on ? selectedCls : idleCls}`}
          >
            {o.label}
          </button>
        );
      })}
    </div>
  );
}
