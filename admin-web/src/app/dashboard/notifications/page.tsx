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
  // ── Server-driven (FCM) ────────────────────────────────────────────
  "streak_at_risk",
  "nightly_checkin",
  "community_momentum",
  "resume_reading",
  "level_up",
  "monthly_quran",
  "monthly_milestone",
  "validate_seeds",
  "habit_gap_quran",
  "habit_gap_dhikr",
  "featured_dua",
  "project_funded",
  "akhirah_milestone",
  "streak_milestone",
  "disengagement_pause",
  // ── Locally-scheduled (Flutter AlarmManager) — variants live in the
  // same table so the rotation logic + admin test-send still work, but
  // the production firings happen on-device, not via these Edge Functions.
  "morning_azkaar",
  "evening_azkaar",
  "sleep_azkar",
  "surah_kahf_friday",
  "salawat_friday",
  "daily_astaghfir",
] as const;
type NotificationType = (typeof NOTIFICATION_TYPES)[number];

const TYPE_LABEL: Record<NotificationType, string> = {
  streak_at_risk: "Streak at Risk",
  nightly_checkin: "Nightly Check-in",
  community_momentum: "Community Momentum",
  resume_reading: "Resume Reading",
  level_up: "Level Up",
  monthly_quran: "Monthly Quran",
  monthly_milestone: "Monthly Milestone",
  validate_seeds: "Validate Seeds (Donate)",
  habit_gap_quran: "Habit Gap — Read Quran",
  habit_gap_dhikr: "Habit Gap — Do Dhikr",
  featured_dua: "Featured Du'a",
  project_funded: "Project Funded",
  akhirah_milestone: "Akhirah Milestone",
  streak_milestone: "Streak Milestone",
  disengagement_pause: "Disengagement Pause",
  morning_azkaar: "Morning Azkar (local)",
  evening_azkaar: "Evening Azkar (local)",
  sleep_azkar: "Sleep Azkar (local)",
  surah_kahf_friday: "Surah Al-Kahf — Friday (local)",
  salawat_friday: "Friday Salawat (local)",
  daily_astaghfir: "Daily Astaghfir (local)",
};

const TYPE_DESCRIPTION: Record<NotificationType, string> = {
  streak_at_risk: "Sent when a user's Quran or dhikr streak is about to break.",
  nightly_checkin: "Late-evening reminder to validate the day's Seeds before midnight.",
  community_momentum: "Live count of believers currently reading the Quran.",
  resume_reading: "Bookmark nudge — pick up where the user left off in the mushaf.",
  level_up: "Almost-there nudge when the user is close to the next level.",
  monthly_quran: "Start-of-month invitation to set a Quran intention.",
  monthly_milestone: "End-of-month recap of ayahs read and dhikr completed.",
  validate_seeds: "Daily ~18:00 nudge to donate accumulated Sabiq Seeds to a Cause.",
  habit_gap_quran: "Sent to users who do dhikr but haven't opened the Quran in 7 days.",
  habit_gap_dhikr: "Sent to users who read Quran but haven't done dhikr in 7 days.",
  featured_dua: "Daily ~13:00 — rotates a random azkar from the library; body is its hadith/benefit text.",
  project_funded: "Fires when a community project completes — notifies every donor with the project name.",
  akhirah_milestone: "Celebrates crossing Seeds thresholds (1k, 5k, 10k, 25k, 50k, 100k, 250k, 500k, 1M). Once per threshold per user.",
  streak_milestone: "Celebrates hitting day 3 / 7 / 14 / 30 / 60 / 100 on any of the 3 streaks (login / dhikr / quran).",
  disengagement_pause: "Goodbye push sent when a user has ignored ≥7 pushes over 14 inactive days. Pauses their reminders until they return.",
  morning_azkaar: "Morning remembrance (08:00 local) — scheduled on-device by Flutter AlarmManager.",
  evening_azkaar: "Evening remembrance (15:30 local, Asr window) — scheduled on-device.",
  sleep_azkar: "Bedtime adhkar (21:00 local) — scheduled on-device.",
  surah_kahf_friday: "Friday Surah Al-Kahf reminder (07:00 + 16:00 Fri local) — scheduled on-device.",
  salawat_friday: "Friday Salawat upon the Prophet ﷺ (12:00 Fri local) — scheduled on-device.",
  daily_astaghfir: "Daily istighfar reminder (11:00 local) — scheduled on-device.",
};

const PLACEHOLDERS: Record<NotificationType, string[]> = {
  streak_at_risk: ["streak", "type"],
  nightly_checkin: ["seeds"],
  community_momentum: ["count"],
  resume_reading: ["surahName", "ayah"],
  level_up: ["ptsNeeded", "nextLevel", "nextTitle"],
  monthly_quran: ["monthName", "verses", "hasanat"],
  monthly_milestone: ["monthName", "ayahs", "dhikrSets"],
  validate_seeds: [],
  habit_gap_quran: [],
  habit_gap_dhikr: [],
  featured_dua: [],
  project_funded: ["projectName"],
  akhirah_milestone: ["milestone"],
  streak_milestone: ["streak", "streakType"],
  disengagement_pause: [],
  morning_azkaar: [],
  evening_azkaar: [],
  sleep_azkar: [],
  surah_kahf_friday: [],
  salawat_friday: [],
  daily_astaghfir: [],
};

const DUMMY_VARS: Record<NotificationType, Record<string, string | number>> = {
  streak_at_risk: { streak: 7, type: "Quran" },
  nightly_checkin: { seeds: 50 },
  community_momentum: { count: 1234 },
  resume_reading: { surahName: "Al-Baqarah", ayah: 23 },
  level_up: { ptsNeeded: 150, nextLevel: 5, nextTitle: "Champion" },
  monthly_quran: { monthName: "November", verses: 234, hasanat: "15K" },
  monthly_milestone: { monthName: "November", ayahs: 234, dhikrSets: 45 },
  validate_seeds: {},
  habit_gap_quran: {},
  habit_gap_dhikr: {},
  featured_dua: {},
  project_funded: { projectName: "Water Well — Yemen" },
  akhirah_milestone: { milestone: "10,000" },
  streak_milestone: { streak: 30, streakType: "dhikr" },
  disengagement_pause: {},
  morning_azkaar: {},
  evening_azkaar: {},
  sleep_azkar: {},
  surah_kahf_friday: {},
  salawat_friday: {},
  daily_astaghfir: {},
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

  // ── Bulk CSV (Google-Sheet / AI round-trip) ────────────────────────────────
  // Download the whole variants table as CSV, edit externally, upload back.
  // Upload first runs `mode: dry_run` so the admin can review a diff before
  // committing anything. Backed by two Edge Functions:
  //   admin-notifications-export  → returns CSV
  //   admin-notifications-import  → dry_run | apply, returns per-row diff
  const csvInputRef = useRef<HTMLInputElement>(null);
  const [csvBusy, setCsvBusy] = useState<null | "download" | "upload" | "apply">(null);
  // Cached last-uploaded CSV so "Confirm & Apply" doesn't need a re-upload.
  const [pendingCsv, setPendingCsv] = useState<string | null>(null);
  const [pendingFileName, setPendingFileName] = useState<string>("");
  const [dryRunResult, setDryRunResult] = useState<
    | null
    | {
        summary: {
          updated: number;
          inserted: number;
          unchanged: number;
          rejected: number;
        };
        changes: Array<{
          row: number;
          action: "update" | "insert" | "unchanged" | "reject";
          id: string | null;
          type: string;
          locale: string;
          before: Record<string, unknown> | null;
          after: Record<string, unknown> | null;
          diff: string[];
          reason?: string;
        }>;
      }
  >(null);

  async function handleCsvDownload() {
    setCsvBusy("download");
    try {
      const { data: sessionData, error: sessErr } =
        await supabase.auth.getSession();
      if (sessErr || !sessionData.session) {
        setToast({ kind: "error", msg: "No active session — please sign in again." });
        return;
      }
      const accessToken = sessionData.session.access_token;
      const adminUid = sessionData.session.user.id;
      const res = await fetch(`${FUNCTIONS_BASE}/admin-notifications-export`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({ admin_user_id: adminUid }),
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        setToast({
          kind: "error",
          msg: (err && (err.error as string)) ?? `Export failed (${res.status}).`,
        });
        return;
      }
      const csv = await res.text();
      // Prompt a native download.
      const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      const stamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
      a.href = url;
      a.download = `notification_variants_${stamp}.csv`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      setToast({ kind: "success", msg: "CSV downloaded." });
    } catch (e) {
      setToast({ kind: "error", msg: (e as Error).message ?? String(e) });
    } finally {
      setCsvBusy(null);
    }
  }

  async function handleCsvSelect(ev: React.ChangeEvent<HTMLInputElement>) {
    const file = ev.target.files?.[0];
    ev.target.value = ""; // allow re-selecting the same file
    if (!file) return;
    setCsvBusy("upload");
    setDryRunResult(null);
    setPendingCsv(null);
    setPendingFileName(file.name);
    try {
      const csv = await file.text();
      const { data: sessionData, error: sessErr } =
        await supabase.auth.getSession();
      if (sessErr || !sessionData.session) {
        setToast({ kind: "error", msg: "No active session — please sign in again." });
        return;
      }
      const accessToken = sessionData.session.access_token;
      const adminUid = sessionData.session.user.id;
      const res = await fetch(`${FUNCTIONS_BASE}/admin-notifications-import`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          admin_user_id: adminUid,
          csv,
          mode: "dry_run",
        }),
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) {
        setToast({
          kind: "error",
          msg: (json && (json.error as string)) ?? `Preview failed (${res.status}).`,
        });
        return;
      }
      setPendingCsv(csv);
      setDryRunResult(json);
    } catch (e) {
      setToast({ kind: "error", msg: (e as Error).message ?? String(e) });
    } finally {
      setCsvBusy(null);
    }
  }

  async function handleCsvApply() {
    if (!pendingCsv || !dryRunResult) return;
    // If literally nothing would change, don't fire the request.
    const { summary } = dryRunResult;
    if (summary.updated === 0 && summary.inserted === 0) {
      setToast({ kind: "success", msg: "Nothing to apply — every row is unchanged or rejected." });
      setDryRunResult(null);
      setPendingCsv(null);
      return;
    }
    setCsvBusy("apply");
    try {
      const { data: sessionData, error: sessErr } =
        await supabase.auth.getSession();
      if (sessErr || !sessionData.session) {
        setToast({ kind: "error", msg: "No active session — please sign in again." });
        return;
      }
      const accessToken = sessionData.session.access_token;
      const adminUid = sessionData.session.user.id;
      const res = await fetch(`${FUNCTIONS_BASE}/admin-notifications-import`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          admin_user_id: adminUid,
          csv: pendingCsv,
          mode: "apply",
        }),
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) {
        setToast({
          kind: "error",
          msg: (json && (json.error as string)) ?? `Apply failed (${res.status}).`,
        });
        return;
      }
      setToast({
        kind: "success",
        msg: `Applied — updated ${summary.updated}, inserted ${summary.inserted}.`,
      });
      setDryRunResult(null);
      setPendingCsv(null);
      setPendingFileName("");
      // Reload the visible table so the new rows show up immediately.
      await loadVariants();
    } catch (e) {
      setToast({ kind: "error", msg: (e as Error).message ?? String(e) });
    } finally {
      setCsvBusy(null);
    }
  }

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
    // Build the empty map programmatically from NOTIFICATION_TYPES so adding
    // a new type only requires editing the constant arrays above — no need
    // to remember to update this initializer too.
    const map = Object.fromEntries(
      NOTIFICATION_TYPES.map((t) => [t, [] as Variant[]]),
    ) as Record<NotificationType, Variant[]>;
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

      {/* ── Bulk CSV (spreadsheet round-trip for AI-assisted editing) ── */}
      <div className="mb-6 rounded-xl border border-emerald-100 dark:border-emerald-500/30 bg-emerald-50/40 dark:bg-emerald-500/10 overflow-hidden">
        <div className="px-4 py-3 flex items-center justify-between gap-3 flex-wrap">
          <div className="min-w-0">
            <div className="text-sm font-semibold text-slate-800 dark:text-slate-100">
              Bulk edit via CSV
            </div>
            <div className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Download the whole table, edit / translate in a spreadsheet, then upload to preview a diff before applying.
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              disabled={csvBusy !== null}
              onClick={handleCsvDownload}
              className="px-3 py-1.5 rounded-lg text-sm font-medium bg-emerald-600 hover:bg-emerald-700 text-white disabled:opacity-60 disabled:cursor-not-allowed transition"
            >
              {csvBusy === "download" ? "Downloading…" : "Download CSV"}
            </button>
            <button
              type="button"
              disabled={csvBusy !== null}
              onClick={() => csvInputRef.current?.click()}
              className="px-3 py-1.5 rounded-lg text-sm font-medium bg-white dark:bg-slate-800 border border-emerald-300 dark:border-emerald-500/50 text-emerald-700 dark:text-emerald-300 hover:bg-emerald-50 dark:hover:bg-emerald-500/20 disabled:opacity-60 disabled:cursor-not-allowed transition"
            >
              {csvBusy === "upload" ? "Uploading…" : "Upload CSV"}
            </button>
            <input
              ref={csvInputRef}
              type="file"
              accept=".csv,text/csv"
              className="hidden"
              onChange={handleCsvSelect}
            />
          </div>
        </div>

        {/* Diff preview after a dry-run */}
        {dryRunResult && (
          <div className="px-4 pb-4 pt-1 border-t border-emerald-100 dark:border-emerald-500/30">
            <div className="text-xs text-slate-500 dark:text-slate-400 mb-2">
              Preview of <span className="font-mono">{pendingFileName}</span>:
            </div>
            <div className="flex flex-wrap gap-2 text-xs mb-3">
              <span className="px-2 py-1 rounded bg-blue-100 dark:bg-blue-500/20 text-blue-700 dark:text-blue-300">
                {dryRunResult.summary.updated} updated
              </span>
              <span className="px-2 py-1 rounded bg-emerald-100 dark:bg-emerald-500/20 text-emerald-700 dark:text-emerald-300">
                {dryRunResult.summary.inserted} inserted
              </span>
              <span className="px-2 py-1 rounded bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300">
                {dryRunResult.summary.unchanged} unchanged
              </span>
              <span className="px-2 py-1 rounded bg-red-100 dark:bg-red-500/20 text-red-700 dark:text-red-300">
                {dryRunResult.summary.rejected} rejected
              </span>
            </div>

            {/* Only surface the interesting rows — hide `unchanged` since the
                whole point of the review is to eyeball what would actually
                change. Cap at 100 rows so the panel stays scannable. */}
            <div className="max-h-80 overflow-y-auto rounded-lg border border-slate-200 dark:border-slate-700 divide-y divide-slate-100 dark:divide-slate-700 bg-white dark:bg-slate-900">
              {dryRunResult.changes
                .filter((c) => c.action !== "unchanged")
                .slice(0, 100)
                .map((c) => {
                  const badge =
                    c.action === "insert"
                      ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-500/20 dark:text-emerald-300"
                      : c.action === "update"
                        ? "bg-blue-100 text-blue-700 dark:bg-blue-500/20 dark:text-blue-300"
                        : "bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-300";
                  return (
                    <div
                      key={`${c.row}-${c.id ?? "new"}`}
                      className="px-3 py-2 text-xs"
                    >
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className={`px-1.5 py-0.5 rounded font-medium ${badge}`}>
                          {c.action}
                        </span>
                        <span className="font-mono text-slate-500 dark:text-slate-400">
                          row {c.row}
                        </span>
                        <span className="font-medium text-slate-700 dark:text-slate-200">
                          {c.type}
                        </span>
                        <span className="text-slate-500 dark:text-slate-400">
                          · {c.locale}
                        </span>
                        {c.diff.length > 0 && c.action === "update" && (
                          <span className="text-slate-400 dark:text-slate-500">
                            → {c.diff.join(", ")}
                          </span>
                        )}
                      </div>
                      {c.reason && (
                        <div className="mt-1 text-red-600 dark:text-red-400">
                          {c.reason}
                        </div>
                      )}
                      {c.action === "update" && c.before && c.after && (
                        <div className="mt-1 grid grid-cols-1 sm:grid-cols-2 gap-2 text-[11px]">
                          <div className="px-2 py-1 rounded bg-red-50 dark:bg-red-500/10 text-slate-700 dark:text-slate-300">
                            <div className="text-red-500 dark:text-red-400 font-medium mb-0.5">
                              before
                            </div>
                            <div className="line-clamp-2">
                              {(c.before.title as string) ?? ""}
                            </div>
                            <div className="line-clamp-2 text-slate-500 dark:text-slate-400">
                              {(c.before.body as string) ?? ""}
                            </div>
                          </div>
                          <div className="px-2 py-1 rounded bg-emerald-50 dark:bg-emerald-500/10 text-slate-700 dark:text-slate-300">
                            <div className="text-emerald-600 dark:text-emerald-400 font-medium mb-0.5">
                              after
                            </div>
                            <div className="line-clamp-2">
                              {(c.after.title as string) ?? ""}
                            </div>
                            <div className="line-clamp-2 text-slate-500 dark:text-slate-400">
                              {(c.after.body as string) ?? ""}
                            </div>
                          </div>
                        </div>
                      )}
                    </div>
                  );
                })}
              {dryRunResult.changes.filter((c) => c.action !== "unchanged").length === 0 && (
                <div className="px-3 py-4 text-xs text-slate-400 text-center">
                  No changes vs. the current database.
                </div>
              )}
            </div>

            <div className="flex items-center gap-2 mt-3">
              <button
                type="button"
                disabled={csvBusy !== null}
                onClick={handleCsvApply}
                className="px-3 py-1.5 rounded-lg text-sm font-medium bg-rose-600 hover:bg-rose-700 text-white disabled:opacity-60 disabled:cursor-not-allowed transition"
              >
                {csvBusy === "apply" ? "Applying…" : "Confirm & Apply"}
              </button>
              <button
                type="button"
                disabled={csvBusy !== null}
                onClick={() => {
                  setDryRunResult(null);
                  setPendingCsv(null);
                  setPendingFileName("");
                }}
                className="px-3 py-1.5 rounded-lg text-sm font-medium bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-700 transition"
              >
                Cancel
              </button>
            </div>
          </div>
        )}
      </div>

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
