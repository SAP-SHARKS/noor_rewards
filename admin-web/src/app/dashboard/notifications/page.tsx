"use client";

// Push Notification Variants admin.
//
// Each `notification_type` (9 of them) has a pool of `notification_variants`
// rows. The push Edge Functions pick a random active row matching the user's
// locale at send time and substitute `{placeholder}` tokens. This page is the
// CRUD surface — list / create / edit / delete / toggle-active / test-send —
// plus an optional image upload that becomes a rich-notification attachment.
//
// The page is intentionally one file (per task constraints): list view at top,
// inline modal for create/edit, expandable placeholder reference panel.

import { useEffect, useMemo, useRef, useState } from "react";
import { supabase } from "@/lib/supabase";

// ── Constants ───────────────────────────────────────────────────────────────

const NOTIFICATION_TYPES = [
  "streak_at_risk",
  "nightly_checkin",
  "community_momentum",
  "resume_reading",
  "morning_azkaar",
  "evening_azkaar",
  "level_up",
  "monthly_quran",
  "monthly_milestone",
] as const;
type NotificationType = (typeof NOTIFICATION_TYPES)[number];

const TYPE_LABEL: Record<NotificationType, string> = {
  streak_at_risk: "Streak at Risk",
  nightly_checkin: "Nightly Check-in",
  community_momentum: "Community Momentum",
  resume_reading: "Resume Reading",
  morning_azkaar: "Morning Azkaar",
  evening_azkaar: "Evening Azkaar",
  level_up: "Level Up",
  monthly_quran: "Monthly Quran",
  monthly_milestone: "Monthly Milestone",
};

const TYPE_DESCRIPTION: Record<NotificationType, string> = {
  streak_at_risk: "Sent when a user's Quran or dhikr streak is about to break.",
  nightly_checkin: "Late-evening reminder to validate the day's Seeds before midnight.",
  community_momentum: "Live count of believers currently reading the Quran.",
  resume_reading: "Bookmark nudge — pick up where the user left off in the mushaf.",
  morning_azkaar: "Morning remembrance reminder (no placeholders).",
  evening_azkaar: "Evening remembrance reminder (no placeholders).",
  level_up: "Almost-there nudge when the user is close to the next level.",
  monthly_quran: "Start-of-month invitation to set a Quran intention.",
  monthly_milestone: "End-of-month recap of ayahs read and dhikr completed.",
};

const PLACEHOLDERS: Record<NotificationType, string[]> = {
  streak_at_risk: ["streak", "type"],
  nightly_checkin: ["seeds"],
  community_momentum: ["count"],
  resume_reading: ["surahName", "ayah"],
  morning_azkaar: [],
  evening_azkaar: [],
  level_up: ["ptsNeeded", "nextLevel", "nextTitle"],
  monthly_quran: ["monthName", "verses", "hasanat"],
  monthly_milestone: ["monthName", "ayahs", "dhikrSets"],
};

const DUMMY_VARS: Record<NotificationType, Record<string, string | number>> = {
  streak_at_risk: { streak: 7, type: "Quran" },
  nightly_checkin: { seeds: 50 },
  community_momentum: { count: 1234 },
  resume_reading: { surahName: "Al-Baqarah", ayah: 23 },
  morning_azkaar: {},
  evening_azkaar: {},
  level_up: { ptsNeeded: 150, nextLevel: 5, nextTitle: "Champion" },
  monthly_quran: { monthName: "November", verses: 234, hasanat: "15K" },
  monthly_milestone: { monthName: "November", ayahs: 234, dhikrSets: 45 },
};

const LOCALES = ["en", "ar", "ur", "fr", "id", "ms", "ru", "tr"] as const;
type Locale = (typeof LOCALES)[number];

const LOCALE_LABEL: Record<Locale, string> = {
  en: "English",
  ar: "Arabic",
  ur: "Urdu",
  fr: "French",
  id: "Indonesian",
  ms: "Malay",
  ru: "Russian",
  tr: "Turkish",
};

const BUCKET = "notifications";
const MAX_IMAGE_BYTES = 2 * 1024 * 1024;
const ALLOWED_IMAGE_TYPES = new Set(["image/png", "image/jpeg", "image/webp"]);

// Supabase project URL is needed to call the Edge Function directly. We avoid
// `supabase.functions.invoke` so we can pass a custom error toast on 4xx.
// Hardcoded fallback so a missing NEXT_PUBLIC_SUPABASE_URL doesn't break Test
// send with a confusing "Failed to fetch" (browser fires the POST at a
// relative path that 404s).
const SUPABASE_URL_FALLBACK = "https://fwjzhtcxfiendofnhyzp.supabase.co";
const FUNCTIONS_BASE =
  (process.env.NEXT_PUBLIC_SUPABASE_URL || SUPABASE_URL_FALLBACK)
    .trim()
    .replace(/\/$/, "") + "/functions/v1";

// ── Types ───────────────────────────────────────────────────────────────────

type Variant = {
  id: string;
  notification_type: NotificationType;
  locale: Locale;
  title: string;
  body: string;
  route: string | null;
  image_url: string | null;
  active: boolean;
  created_at: string;
};

type EditState = {
  notification_type: NotificationType;
  locale: Locale;
  title: string;
  body: string;
  route: string;
  image_url: string;
  active: boolean;
};

const EMPTY: Omit<EditState, "notification_type"> = {
  locale: "en",
  title: "",
  body: "",
  route: "",
  image_url: "",
  active: true,
};

// ── Helpers ─────────────────────────────────────────────────────────────────

function truncate(s: string, n: number): string {
  if (!s) return "";
  return s.length > n ? s.slice(0, n - 1) + "…" : s;
}

// Highlights `{token}` substrings — same idea as the Edge Function rendering
// so admins can spot unknown placeholders at a glance.
function renderWithTokens(
  text: string,
  validTokens: string[],
): { text: string; valid: boolean }[] {
  const parts: { text: string; valid: boolean }[] = [];
  const regex = /\{([a-zA-Z0-9_]+)\}/g;
  let last = 0;
  let m: RegExpExecArray | null;
  while ((m = regex.exec(text)) !== null) {
    if (m.index > last) parts.push({ text: text.slice(last, m.index), valid: true });
    parts.push({ text: m[0], valid: validTokens.includes(m[1]) });
    last = m.index + m[0].length;
  }
  if (last < text.length) parts.push({ text: text.slice(last), valid: true });
  return parts;
}

// ── Component ───────────────────────────────────────────────────────────────

export default function NotificationsPage() {
  const [variants, setVariants] = useState<Variant[]>([]);
  const [loading, setLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState("");

  // Modal state
  const [modalOpen, setModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<EditState>({
    notification_type: "streak_at_risk",
    ...EMPTY,
  });
  const [saving, setSaving] = useState(false);
  const [uploadingImage, setUploadingImage] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Per-row toggle / send / delete spinners
  const [busyRow, setBusyRow] = useState<string | null>(null);
  const [testingRow, setTestingRow] = useState<string | null>(null);

  // ── Test-send picker ─────────────────────────────────────────────────────
  // Opens when admin clicks "Test send" on a variant row. Lets the admin
  // pick which user gets the test push (default: themselves) so they don't
  // accidentally spam the whole audience.
  const [pickerVariant, setPickerVariant] = useState<Variant | null>(null);
  const [pickerQuery, setPickerQuery] = useState("");
  const [pickerResults, setPickerResults] = useState<
    { id: string; display_name: string | null }[]
  >([]);
  const [pickerSearching, setPickerSearching] = useState(false);

  // ── Locale filter ────────────────────────────────────────────────────────
  // Default to English so the page opens with a short, readable list
  // (~42 rows instead of ~336 with all locales mixed). Admins switch via
  // the dropdown to review/edit other languages.
  const [localeFilter, setLocaleFilter] = useState<Locale | "all">("en");

  // Toast
  const [toast, setToast] = useState<{
    kind: "success" | "error";
    msg: string;
  } | null>(null);

  // Placeholder reference accordion
  const [referenceOpen, setReferenceOpen] = useState(false);

  // ── Data loading ─────────────────────────────────────────────────────────

  async function loadVariants() {
    setLoading(true);
    setErrorMsg("");
    const { data, error } = await supabase
      .from("notification_variants")
      .select("*")
      .order("notification_type")
      .order("locale")
      .order("created_at");
    if (error) {
      setErrorMsg(error.message);
      setLoading(false);
      return;
    }
    setVariants((data ?? []) as Variant[]);
    setLoading(false);
  }

  useEffect(() => {
    void loadVariants();
  }, []);

  // Toast auto-dismiss
  useEffect(() => {
    if (!toast) return;
    const t = setTimeout(() => setToast(null), 4000);
    return () => clearTimeout(t);
  }, [toast]);

  // Group variants by notification_type for the list rendering.
  const grouped = useMemo(() => {
    const map: Record<NotificationType, Variant[]> = {
      streak_at_risk: [],
      nightly_checkin: [],
      community_momentum: [],
      resume_reading: [],
      morning_azkaar: [],
      evening_azkaar: [],
      level_up: [],
      monthly_quran: [],
      monthly_milestone: [],
    };
    for (const v of variants) {
      if (!NOTIFICATION_TYPES.includes(v.notification_type)) continue;
      if (localeFilter !== "all" && v.locale !== localeFilter) continue;
      map[v.notification_type].push(v);
    }
    return map;
  }, [variants, localeFilter]);

  // ── Modal open/close ─────────────────────────────────────────────────────

  function openCreate(type: NotificationType) {
    setEditingId(null);
    setForm({ notification_type: type, ...EMPTY });
    setModalOpen(true);
  }

  function openEdit(v: Variant) {
    setEditingId(v.id);
    setForm({
      notification_type: v.notification_type,
      locale: v.locale,
      title: v.title,
      body: v.body,
      route: v.route ?? "",
      image_url: v.image_url ?? "",
      active: v.active,
    });
    setModalOpen(true);
  }

  function closeModal() {
    if (saving || uploadingImage) return;
    setModalOpen(false);
    setEditingId(null);
  }

  // ── Image upload ─────────────────────────────────────────────────────────

  async function handleImageUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!ALLOWED_IMAGE_TYPES.has(file.type)) {
      setToast({
        kind: "error",
        msg: "Image must be PNG, JPEG, or WebP.",
      });
      if (fileInputRef.current) fileInputRef.current.value = "";
      return;
    }
    if (file.size > MAX_IMAGE_BYTES) {
      setToast({ kind: "error", msg: "Image must be 2 MB or smaller." });
      if (fileInputRef.current) fileInputRef.current.value = "";
      return;
    }
    setUploadingImage(true);
    try {
      const ext = file.name.split(".").pop()?.toLowerCase() ?? "png";
      const safeName = file.name
        .replace(/\.[^.]+$/, "")
        .replace(/[^a-zA-Z0-9_-]+/g, "-")
        .slice(0, 40) || "image";
      const path = `${crypto.randomUUID()}-${safeName}.${ext}`;
      const { error: upErr } = await supabase.storage
        .from(BUCKET)
        .upload(path, file, { contentType: file.type, upsert: false });
      if (upErr) {
        setToast({ kind: "error", msg: `Upload failed: ${upErr.message}` });
        return;
      }
      const { data } = supabase.storage.from(BUCKET).getPublicUrl(path);
      setForm((f) => ({ ...f, image_url: data.publicUrl }));
    } finally {
      setUploadingImage(false);
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  }

  function clearImage() {
    setForm((f) => ({ ...f, image_url: "" }));
  }

  // ── Save / delete / toggle ───────────────────────────────────────────────

  async function handleSave() {
    if (!form.title.trim() || !form.body.trim()) {
      setToast({ kind: "error", msg: "Title and body are required." });
      return;
    }
    setSaving(true);
    const payload = {
      notification_type: form.notification_type,
      locale: form.locale,
      title: form.title.trim(),
      body: form.body.trim(),
      route: form.route.trim() || null,
      image_url: form.image_url.trim() || null,
      active: form.active,
    };
    try {
      if (editingId) {
        const { error } = await supabase
          .from("notification_variants")
          .update(payload)
          .eq("id", editingId);
        if (error) throw error;
        setToast({ kind: "success", msg: "Variant updated." });
      } else {
        const { error } = await supabase
          .from("notification_variants")
          .insert(payload);
        if (error) throw error;
        setToast({ kind: "success", msg: "Variant created." });
      }
      setModalOpen(false);
      setEditingId(null);
      await loadVariants();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : "Save failed.";
      setToast({ kind: "error", msg });
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete(v: Variant) {
    if (
      !confirm(
        `Delete this ${TYPE_LABEL[v.notification_type]} (${v.locale}) variant?\n\n"${truncate(
          v.title,
          80,
        )}"`,
      )
    ) {
      return;
    }
    setBusyRow(v.id);
    const { error } = await supabase
      .from("notification_variants")
      .delete()
      .eq("id", v.id);
    setBusyRow(null);
    if (error) {
      setToast({ kind: "error", msg: `Delete failed: ${error.message}` });
      return;
    }
    setVariants((prev) => prev.filter((x) => x.id !== v.id));
    setToast({ kind: "success", msg: "Variant deleted." });
  }

  async function handleToggleActive(v: Variant) {
    setBusyRow(v.id);
    const next = !v.active;
    // Optimistic update.
    setVariants((prev) =>
      prev.map((x) => (x.id === v.id ? { ...x, active: next } : x)),
    );
    const { error } = await supabase
      .from("notification_variants")
      .update({ active: next })
      .eq("id", v.id);
    setBusyRow(null);
    if (error) {
      // Roll back.
      setVariants((prev) =>
        prev.map((x) => (x.id === v.id ? { ...x, active: !next } : x)),
      );
      setToast({ kind: "error", msg: `Toggle failed: ${error.message}` });
    }
  }

  // ── Test send ────────────────────────────────────────────────────────────

  // ── Test send ─────────────────────────────────────────────────────────────
  // Click on a row's "Test send" button opens a small picker — the admin
  // chooses WHICH user receives the test push. Default option is "Send to
  // myself" so quick smoke-checks stay one click.
  function openTestPicker(v: Variant) {
    setPickerVariant(v);
    setPickerQuery("");
    setPickerResults([]);
  }

  function closeTestPicker() {
    setPickerVariant(null);
    setPickerQuery("");
    setPickerResults([]);
    setTestingRow(null);
  }

  async function runProfileSearch(q: string) {
    setPickerQuery(q);
    const trimmed = q.trim();
    if (trimmed.length < 2) {
      setPickerResults([]);
      return;
    }
    setPickerSearching(true);
    try {
      const { data, error } = await supabase
        .from("profiles")
        .select("id, display_name")
        .ilike("display_name", `%${trimmed}%`)
        .limit(15);
      if (error) {
        setPickerResults([]);
      } else {
        setPickerResults(data ?? []);
      }
    } finally {
      setPickerSearching(false);
    }
  }

  async function sendTestToUser(targetUserId: string, targetLabel: string) {
    if (!pickerVariant) return;
    setTestingRow(pickerVariant.id);
    try {
      const { data: sessionData, error: sessErr } =
        await supabase.auth.getSession();
      if (sessErr || !sessionData.session) {
        setToast({
          kind: "error",
          msg: "No active session — please sign in again.",
        });
        return;
      }
      const accessToken = sessionData.session.access_token;
      const adminUid = sessionData.session.user.id;

      const body = {
        user_id: targetUserId,
        admin_user_id: adminUid,
        // `variant_id` pins the test to the exact row the admin clicked
        // (especially needed when verifying an image). `notification_type`
        // stays for logging + as a fallback if the variant lookup fails.
        variant_id: pickerVariant.id,
        notification_type: pickerVariant.notification_type,
        vars: DUMMY_VARS[pickerVariant.notification_type],
      };
      const res = await fetch(`${FUNCTIONS_BASE}/admin-test-push`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify(body),
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) {
        setToast({
          kind: "error",
          msg:
            (json && (json.error as string)) ??
            `Test send failed (${res.status}).`,
        });
        return;
      }
      setToast({ kind: "success", msg: `Test push sent to ${targetLabel}.` });
      closeTestPicker();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : "Test send failed.";
      setToast({ kind: "error", msg });
    } finally {
      setTestingRow(null);
    }
  }

  // ── Render ───────────────────────────────────────────────────────────────

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-rose-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  const placeholderList = PLACEHOLDERS[form.notification_type];

  return (
    <div className="max-w-5xl">
      <div className="flex items-start justify-between gap-4 mb-6 flex-wrap">
        <div>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Manage the per-notification copy pool. The push functions pick a
            random active variant matching the recipient's locale and substitute{" "}
            <code className="px-1 py-0.5 rounded bg-slate-100 dark:bg-slate-800 text-rose-700 dark:text-rose-300 text-[12px]">
              {"{token}"}
            </code>{" "}
            placeholders at send time.
          </p>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-1">
            {variants.length} variant{variants.length === 1 ? "" : "s"} across{" "}
            {NOTIFICATION_TYPES.length} notification types.
          </p>
        </div>

        {/* Locale filter — defaults to English to keep the list short. */}
        <div className="flex items-center gap-2">
          <label
            htmlFor="locale-filter"
            className="text-xs font-medium text-slate-500 dark:text-slate-400"
          >
            Language:
          </label>
          <select
            id="locale-filter"
            value={localeFilter}
            onChange={(e) => setLocaleFilter(e.target.value as Locale | "all")}
            className="px-3 py-1.5 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-sm text-slate-700 dark:text-slate-200 cursor-pointer focus:outline-none focus:ring-2 focus:ring-rose-500/40"
          >
            {LOCALES.map((l) => (
              <option key={l} value={l}>
                {LOCALE_LABEL[l]}
              </option>
            ))}
            <option value="all">All languages</option>
          </select>
        </div>
      </div>

      {errorMsg && (
        <div className="mb-4 px-4 py-3 rounded-xl bg-red-50 dark:bg-red-900/30 text-red-700 dark:text-red-300 text-sm border border-red-200 dark:border-red-800">
          {errorMsg}
        </div>
      )}

      {/* Placeholder reference */}
      <div className="mb-6 rounded-xl border border-rose-100 dark:border-rose-500/30 bg-rose-50/40 dark:bg-rose-500/10 overflow-hidden">
        <button
          onClick={() => setReferenceOpen((v) => !v)}
          className="w-full flex items-center justify-between px-4 py-3 text-left cursor-pointer hover:bg-rose-50/80 dark:hover:bg-rose-500/15 transition"
        >
          <div className="flex items-center gap-2">
            <span className="w-1.5 h-1.5 rounded-full bg-rose-500" />
            <span className="text-sm font-semibold text-rose-700 dark:text-rose-300">
              Placeholder reference
            </span>
            <span className="text-xs text-slate-500 dark:text-slate-400">
              tokens you can use in title and body
            </span>
          </div>
          <svg
            className={`w-4 h-4 text-rose-700 dark:text-rose-300 transition-transform ${
              referenceOpen ? "rotate-180" : ""
            }`}
            fill="none"
            stroke="currentColor"
            strokeWidth={2}
            viewBox="0 0 24 24"
          >
            <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7" />
          </svg>
        </button>
        {referenceOpen && (
          <div className="px-4 pb-4 pt-1 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
            {NOTIFICATION_TYPES.map((t) => (
              <div
                key={t}
                className="rounded-lg bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 px-3 py-2"
              >
                <p className="text-xs font-semibold text-slate-700 dark:text-slate-200">
                  {TYPE_LABEL[t]}
                </p>
                <p className="mt-1 text-[11px] text-slate-500 dark:text-slate-400 leading-snug">
                  {PLACEHOLDERS[t].length === 0 ? (
                    <span className="italic text-slate-400 dark:text-slate-500">
                      no placeholders
                    </span>
                  ) : (
                    PLACEHOLDERS[t].map((p) => (
                      <code
                        key={p}
                        className="inline-block mr-1 mb-1 px-1.5 py-0.5 rounded bg-rose-50 dark:bg-rose-500/20 text-rose-700 dark:text-rose-300 font-mono"
                      >
                        {"{" + p + "}"}
                      </code>
                    ))
                  )}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Groups */}
      <div className="space-y-6">
        {NOTIFICATION_TYPES.map((type) => {
          const rows = grouped[type];
          return (
            <section
              key={type}
              className="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 overflow-hidden"
            >
              {/* Header */}
              <div className="px-5 py-4 flex items-center justify-between gap-3 border-b border-slate-100 dark:border-slate-700">
                <div className="min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <h2 className="text-base font-semibold text-slate-800 dark:text-slate-100">
                      {TYPE_LABEL[type]}
                    </h2>
                    <span className="px-2 py-0.5 rounded-full bg-rose-50 dark:bg-rose-500/20 text-rose-700 dark:text-rose-300 text-[11px] font-medium ring-1 ring-rose-200/70 dark:ring-rose-400/30">
                      {rows.length} variant{rows.length === 1 ? "" : "s"}
                    </span>
                  </div>
                  <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
                    {TYPE_DESCRIPTION[type]}
                  </p>
                </div>
                <button
                  onClick={() => openCreate(type)}
                  className="shrink-0 px-3.5 py-2 rounded-lg bg-rose-600 text-white text-xs font-medium hover:bg-rose-700 cursor-pointer transition"
                >
                  + Add variant
                </button>
              </div>

              {/* Rows */}
              {rows.length === 0 ? (
                <div className="px-5 py-8 text-center text-sm text-slate-400 dark:text-slate-500">
                  No variants yet. Add at least one so this notification can
                  fire.
                </div>
              ) : (
                <ul className="divide-y divide-slate-100 dark:divide-slate-700">
                  {rows.map((v) => {
                    const titleParts = renderWithTokens(
                      v.title,
                      PLACEHOLDERS[v.notification_type],
                    );
                    const bodyParts = renderWithTokens(
                      truncate(v.body, 140),
                      PLACEHOLDERS[v.notification_type],
                    );
                    const rowBusy = busyRow === v.id;
                    const rowTesting = testingRow === v.id;
                    return (
                      <li
                        key={v.id}
                        className="px-5 py-4 flex items-start gap-4 hover:bg-slate-50/60 dark:hover:bg-slate-700/30 transition"
                      >
                        {/* Image thumb */}
                        <div className="shrink-0">
                          {v.image_url ? (
                            // eslint-disable-next-line @next/next/no-img-element
                            <img
                              src={v.image_url}
                              alt=""
                              className="w-14 h-14 rounded-lg object-cover border border-slate-200 dark:border-slate-700"
                            />
                          ) : (
                            <div className="w-14 h-14 rounded-lg border border-dashed border-slate-200 dark:border-slate-700 flex items-center justify-center text-slate-300 dark:text-slate-600">
                              <svg
                                className="w-5 h-5"
                                fill="none"
                                stroke="currentColor"
                                strokeWidth={1.5}
                                viewBox="0 0 24 24"
                              >
                                <path
                                  strokeLinecap="round"
                                  strokeLinejoin="round"
                                  d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909M3.75 21h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v13.5A1.5 1.5 0 003.75 21z"
                                />
                              </svg>
                            </div>
                          )}
                        </div>

                        {/* Text */}
                        <button
                          onClick={() => openEdit(v)}
                          className="flex-1 min-w-0 text-left cursor-pointer group"
                        >
                          <div className="flex items-center gap-2 flex-wrap">
                            <span className="px-1.5 py-0.5 rounded text-[10px] font-semibold uppercase tracking-wide bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300">
                              {v.locale}
                            </span>
                            {v.route && (
                              <span className="text-[10px] text-slate-400 dark:text-slate-500 font-mono">
                                → {v.route}
                              </span>
                            )}
                            {!v.active && (
                              <span className="px-1.5 py-0.5 rounded text-[10px] font-semibold bg-slate-200 dark:bg-slate-700 text-slate-500 dark:text-slate-400">
                                inactive
                              </span>
                            )}
                          </div>
                          <p className="text-sm font-medium text-slate-800 dark:text-slate-100 mt-1 group-hover:text-rose-700 dark:group-hover:text-rose-300 transition">
                            {titleParts.map((p, i) =>
                              p.text.startsWith("{") ? (
                                <code
                                  key={i}
                                  className={`px-1 rounded font-mono text-[12px] ${
                                    p.valid
                                      ? "bg-rose-50 dark:bg-rose-500/20 text-rose-700 dark:text-rose-300"
                                      : "bg-red-100 dark:bg-red-900/40 text-red-700 dark:text-red-300"
                                  }`}
                                >
                                  {p.text}
                                </code>
                              ) : (
                                <span key={i}>{p.text}</span>
                              ),
                            )}
                          </p>
                          <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5 leading-relaxed">
                            {bodyParts.map((p, i) =>
                              p.text.startsWith("{") ? (
                                <code
                                  key={i}
                                  className={`px-1 rounded font-mono text-[11px] ${
                                    p.valid
                                      ? "bg-rose-50 dark:bg-rose-500/20 text-rose-700 dark:text-rose-300"
                                      : "bg-red-100 dark:bg-red-900/40 text-red-700 dark:text-red-300"
                                  }`}
                                >
                                  {p.text}
                                </code>
                              ) : (
                                <span key={i}>{p.text}</span>
                              ),
                            )}
                          </p>
                        </button>

                        {/* Controls */}
                        <div className="shrink-0 flex items-center gap-2">
                          {/* Active toggle */}
                          <button
                            onClick={() => handleToggleActive(v)}
                            disabled={rowBusy}
                            title={v.active ? "Deactivate" : "Activate"}
                            className={`relative w-[44px] h-[24px] rounded-full transition-colors cursor-pointer disabled:opacity-50 ${
                              v.active
                                ? "bg-rose-500"
                                : "bg-slate-200 dark:bg-slate-600"
                            }`}
                          >
                            <span
                              className={`absolute top-[2px] left-[2px] w-5 h-5 bg-white rounded-full shadow transition-transform ${
                                v.active ? "translate-x-5" : "translate-x-0"
                              }`}
                            />
                          </button>

                          <button
                            onClick={() => openTestPicker(v)}
                            disabled={rowTesting}
                            title="Send test push to a specific user"
                            className="px-2.5 py-1.5 rounded-lg bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-200 text-xs font-medium hover:bg-slate-200 dark:hover:bg-slate-600 disabled:opacity-50 cursor-pointer transition flex items-center gap-1"
                          >
                            {rowTesting ? (
                              <span className="w-3 h-3 border-2 border-slate-700 dark:border-slate-200 border-t-transparent rounded-full animate-spin" />
                            ) : (
                              <svg
                                className="w-3.5 h-3.5"
                                fill="none"
                                stroke="currentColor"
                                strokeWidth={1.8}
                                viewBox="0 0 24 24"
                              >
                                <path
                                  strokeLinecap="round"
                                  strokeLinejoin="round"
                                  d="M6 12L3.269 3.126A59.768 59.768 0 0121.485 12 59.77 59.77 0 013.27 20.876L5.999 12zm0 0h7.5"
                                />
                              </svg>
                            )}
                            Test
                          </button>

                          <button
                            onClick={() => handleDelete(v)}
                            disabled={rowBusy}
                            title="Delete"
                            className="w-8 h-8 rounded-lg text-red-500 hover:bg-red-50 dark:hover:bg-red-900/30 disabled:opacity-50 cursor-pointer flex items-center justify-center"
                          >
                            <svg
                              className="w-4 h-4"
                              fill="none"
                              stroke="currentColor"
                              strokeWidth={1.8}
                              viewBox="0 0 24 24"
                            >
                              <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0"
                              />
                            </svg>
                          </button>
                        </div>
                      </li>
                    );
                  })}
                </ul>
              )}
            </section>
          );
        })}
      </div>

      {/* ─── Modal ──────────────────────────────────────────────────────── */}
      {modalOpen && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50"
          onClick={closeModal}
        >
          <div
            className="bg-white dark:bg-slate-800 rounded-2xl shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Modal header */}
            <div className="px-6 py-4 border-b border-slate-100 dark:border-slate-700 flex items-center justify-between">
              <div>
                <h3 className="text-base font-semibold text-slate-800 dark:text-slate-100">
                  {editingId ? "Edit variant" : "New variant"}
                </h3>
                <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                  {TYPE_LABEL[form.notification_type]}
                </p>
              </div>
              <button
                onClick={closeModal}
                disabled={saving || uploadingImage}
                className="w-8 h-8 rounded-lg flex items-center justify-center text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-700 disabled:opacity-50 cursor-pointer"
              >
                ✕
              </button>
            </div>

            {/* Modal body */}
            <div className="px-6 py-5 space-y-5">
              {/* Type + locale row */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-slate-600 dark:text-slate-300 mb-1">
                    Notification type
                  </label>
                  <select
                    value={form.notification_type}
                    onChange={(e) =>
                      setForm((f) => ({
                        ...f,
                        notification_type: e.target.value as NotificationType,
                      }))
                    }
                    className="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-700 text-slate-800 dark:text-slate-100 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-rose-500"
                  >
                    {NOTIFICATION_TYPES.map((t) => (
                      <option key={t} value={t}>
                        {TYPE_LABEL[t]}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-600 dark:text-slate-300 mb-1">
                    Locale
                  </label>
                  <select
                    value={form.locale}
                    onChange={(e) =>
                      setForm((f) => ({
                        ...f,
                        locale: e.target.value as Locale,
                      }))
                    }
                    className="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-700 text-slate-800 dark:text-slate-100 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-rose-500"
                  >
                    {LOCALES.map((l) => (
                      <option key={l} value={l}>
                        {l.toUpperCase()} — {LOCALE_LABEL[l]}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Placeholder hint */}
              <div className="text-[11px] text-slate-500 dark:text-slate-400 -mt-2">
                {placeholderList.length === 0 ? (
                  <>This notification type has no placeholders.</>
                ) : (
                  <>
                    Available tokens:{" "}
                    {placeholderList.map((p) => (
                      <code
                        key={p}
                        className="inline-block mx-0.5 px-1.5 py-0.5 rounded bg-rose-50 dark:bg-rose-500/20 text-rose-700 dark:text-rose-300 font-mono"
                      >
                        {"{" + p + "}"}
                      </code>
                    ))}
                  </>
                )}
              </div>

              {/* Title */}
              <div>
                <label className="block text-xs font-medium text-slate-600 dark:text-slate-300 mb-1">
                  Title
                </label>
                <input
                  type="text"
                  value={form.title}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, title: e.target.value }))
                  }
                  placeholder="Keep the chain alive 🔥"
                  className="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-700 text-slate-800 dark:text-slate-100 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-rose-500"
                />
              </div>

              {/* Body */}
              <div>
                <label className="block text-xs font-medium text-slate-600 dark:text-slate-300 mb-1">
                  Body
                </label>
                <textarea
                  value={form.body}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, body: e.target.value }))
                  }
                  rows={3}
                  placeholder="Your {type} streak hit {streak} days. One more tap before midnight locks it in."
                  className="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-700 text-slate-800 dark:text-slate-100 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-rose-500"
                />
              </div>

              {/* Route */}
              <div>
                <label className="block text-xs font-medium text-slate-600 dark:text-slate-300 mb-1">
                  Route (optional)
                </label>
                <input
                  type="text"
                  value={form.route}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, route: e.target.value }))
                  }
                  placeholder="quran, home, morning, evening, profile, akhirah…"
                  className="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-700 text-slate-800 dark:text-slate-100 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-rose-500"
                />
              </div>

              {/* Image */}
              <div>
                <label className="block text-xs font-medium text-slate-600 dark:text-slate-300 mb-1">
                  Image (optional, ≤ 2 MB, PNG / JPEG / WebP)
                </label>
                {form.image_url ? (
                  <div className="flex items-center gap-3">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={form.image_url}
                      alt=""
                      className="w-24 h-24 rounded-lg object-cover border border-slate-200 dark:border-slate-700"
                    />
                    <div className="flex-1 min-w-0">
                      <p className="text-xs text-slate-500 dark:text-slate-400 truncate font-mono">
                        {form.image_url}
                      </p>
                      <div className="mt-2 flex items-center gap-2">
                        <button
                          onClick={() => fileInputRef.current?.click()}
                          disabled={uploadingImage}
                          className="px-3 py-1.5 rounded-lg bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-200 text-xs font-medium hover:bg-slate-200 dark:hover:bg-slate-600 disabled:opacity-50 cursor-pointer"
                        >
                          {uploadingImage ? "Uploading…" : "Replace"}
                        </button>
                        <button
                          onClick={clearImage}
                          disabled={uploadingImage}
                          className="px-3 py-1.5 rounded-lg bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-300 text-xs font-medium hover:bg-red-100 dark:hover:bg-red-900/50 disabled:opacity-50 cursor-pointer"
                        >
                          Remove
                        </button>
                      </div>
                    </div>
                  </div>
                ) : (
                  <button
                    onClick={() => fileInputRef.current?.click()}
                    disabled={uploadingImage}
                    className="w-full px-4 py-6 rounded-lg border-2 border-dashed border-slate-200 dark:border-slate-600 text-center text-sm text-slate-500 dark:text-slate-400 hover:border-rose-300 dark:hover:border-rose-500/50 disabled:opacity-50 cursor-pointer"
                  >
                    {uploadingImage
                      ? "Uploading…"
                      : "Click to upload an image"}
                  </button>
                )}
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/png,image/jpeg,image/webp"
                  onChange={handleImageUpload}
                  className="hidden"
                />
              </div>

              {/* Active toggle */}
              <label className="flex items-center gap-3 cursor-pointer">
                <button
                  type="button"
                  onClick={() =>
                    setForm((f) => ({ ...f, active: !f.active }))
                  }
                  className={`relative w-[44px] h-[24px] rounded-full transition-colors ${
                    form.active
                      ? "bg-rose-500"
                      : "bg-slate-200 dark:bg-slate-600"
                  }`}
                >
                  <span
                    className={`absolute top-[2px] left-[2px] w-5 h-5 bg-white rounded-full shadow transition-transform ${
                      form.active ? "translate-x-5" : "translate-x-0"
                    }`}
                  />
                </button>
                <span className="text-sm text-slate-700 dark:text-slate-200">
                  Active
                  <span className="block text-xs text-slate-400 dark:text-slate-500">
                    Inactive variants are skipped at send time but kept for
                    history.
                  </span>
                </span>
              </label>
            </div>

            {/* Modal footer */}
            <div className="px-6 py-4 border-t border-slate-100 dark:border-slate-700 flex items-center justify-end gap-3 bg-slate-50/60 dark:bg-slate-900/30">
              <button
                onClick={closeModal}
                disabled={saving || uploadingImage}
                className="px-4 py-2 rounded-lg text-sm text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700 disabled:opacity-50 cursor-pointer"
              >
                Cancel
              </button>
              <button
                onClick={handleSave}
                disabled={saving || uploadingImage || !form.title.trim() || !form.body.trim()}
                className="px-5 py-2 rounded-lg bg-rose-600 text-white text-sm font-medium hover:bg-rose-700 disabled:opacity-50 cursor-pointer transition flex items-center gap-2"
              >
                {saving && (
                  <span className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                )}
                {editingId ? "Save changes" : "Create variant"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ─── Test-send picker modal ──────────────────────────────────────── */}
      {pickerVariant && (
        <div
          className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm flex items-center justify-center p-4"
          onClick={closeTestPicker}
        >
          <div
            className="bg-white dark:bg-slate-800 rounded-2xl shadow-xl max-w-md w-full overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="px-5 py-4 border-b border-slate-200 dark:border-slate-700 flex items-center justify-between">
              <div>
                <h3 className="text-sm font-semibold text-slate-800 dark:text-white">
                  Send test push
                </h3>
                <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                  {TYPE_LABEL[pickerVariant.notification_type]} ·{" "}
                  {LOCALE_LABEL[pickerVariant.locale as Locale] ??
                    pickerVariant.locale}
                </p>
              </div>
              <button
                onClick={closeTestPicker}
                className="text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 cursor-pointer text-xl leading-none"
              >
                ×
              </button>
            </div>

            <div className="p-5 space-y-4">
              {/* Quick: send to self */}
              <button
                onClick={async () => {
                  const { data } = await supabase.auth.getSession();
                  const uid = data.session?.user.id;
                  if (uid) sendTestToUser(uid, "yourself");
                }}
                disabled={testingRow === pickerVariant.id}
                className="w-full px-4 py-2.5 rounded-lg bg-rose-500 hover:bg-rose-600 disabled:opacity-50 text-white text-sm font-medium cursor-pointer transition"
              >
                Send to myself
              </button>

              <div className="flex items-center gap-2">
                <div className="flex-1 h-px bg-slate-200 dark:bg-slate-700" />
                <span className="text-[10px] uppercase tracking-wider text-slate-400">
                  Or pick a user
                </span>
                <div className="flex-1 h-px bg-slate-200 dark:bg-slate-700" />
              </div>

              <input
                type="text"
                value={pickerQuery}
                onChange={(e) => runProfileSearch(e.target.value)}
                placeholder="Search by display name (min 2 chars)…"
                autoFocus
                className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-sm text-slate-800 dark:text-white placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-rose-500/40"
              />

              <div className="max-h-64 overflow-y-auto -mx-1">
                {pickerSearching && (
                  <div className="px-3 py-2 text-xs text-slate-400">
                    Searching…
                  </div>
                )}
                {!pickerSearching &&
                  pickerQuery.trim().length >= 2 &&
                  pickerResults.length === 0 && (
                    <div className="px-3 py-2 text-xs text-slate-400">
                      No users found.
                    </div>
                  )}
                {pickerResults.map((p) => (
                  <button
                    key={p.id}
                    onClick={() =>
                      sendTestToUser(p.id, p.display_name ?? p.id.slice(0, 8))
                    }
                    disabled={testingRow === pickerVariant.id}
                    className="w-full flex items-center justify-between gap-3 px-3 py-2 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700 disabled:opacity-50 cursor-pointer text-left transition"
                  >
                    <div className="min-w-0 flex-1">
                      <div className="text-sm font-medium text-slate-800 dark:text-white truncate">
                        {p.display_name ?? "(no name)"}
                      </div>
                      <div className="text-[10px] text-slate-400 truncate font-mono">
                        {p.id}
                      </div>
                    </div>
                    <span className="text-[11px] text-rose-500 font-medium">
                      Send →
                    </span>
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ─── Toast ──────────────────────────────────────────────────────── */}
      {toast && (
        <div
          className={`fixed bottom-6 right-6 z-50 px-4 py-3 rounded-xl shadow-lg text-sm font-medium max-w-sm ${
            toast.kind === "success"
              ? "bg-emerald-600 text-white"
              : "bg-red-600 text-white"
          }`}
        >
          {toast.msg}
        </div>
      )}
    </div>
  );
}
