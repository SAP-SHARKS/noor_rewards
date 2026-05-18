"use client";

import { useEffect, useState, useRef } from "react";
import { supabase } from "@/lib/supabase";

// ── Slot metadata ────────────────────────────────────────────────────────────
// Mirror the slot list the Flutter app reads. Edit here AND in
// _onboarding_images_migration.sql + lib/services/onboarding_assets_service.dart
// if you add new slots.

type Slot = {
  key: string;
  phase: "Phase 1" | "Phase 2";
  screen: string;
  title: string;
  guidance: string;
  /** Recommended aspect ratio shown to the admin (cosmetic only). */
  aspect: string;
};

const SLOTS: Slot[] = [
  {
    key: "onb_hero_1",
    phase: "Phase 1",
    screen: "S1 — The Hook",
    title: "Hero photograph",
    guidance:
      "A dignified, eye-level photo of a family or community receiving aid. Used full-bleed across the top 55% of the screen.",
    aspect: "9:11 portrait",
  },
  {
    key: "onb_aid_2",
    phase: "Phase 1",
    screen: "S2 — The Mechanism",
    title: "Aid photo (small)",
    guidance:
      "Close-up of hands receiving aid. Renders inside an 88×170 card on the right side of the seed-flow box.",
    aspect: "1:2 portrait",
  },
  {
    key: "onb_quran_2",
    phase: "Phase 1",
    screen: "S2 — The Mechanism",
    title: "Quran mini-screenshot",
    guidance:
      "Tiny screenshot of the Noor Quran reading screen. Renders inside an 88×170 card on the left side. Leave empty to use the built-in mock.",
    aspect: "1:2 portrait",
  },
  {
    key: "onb_quran_3",
    phase: "Phase 1",
    screen: "S3 — Quran Earns Seeds",
    title: "Quran screenshot with seed banner",
    guidance:
      "Full screenshot of the Quran screen with the +Seeds banner overlaid. Leave empty to use the built-in mock with the pulsing gold banner.",
    aspect: "1:2 portrait",
  },
  {
    key: "onb_step_quran",
    phase: "Phase 1",
    screen: "S3 — Three-step flow",
    title: "Step 1 image — Read Quran",
    guidance:
      "Image for the first step of the Read → Earn → Feed journey. Renders as a large rounded card (~188×108).",
    aspect: "16:9 landscape",
  },
  {
    key: "onb_step_orphans",
    phase: "Phase 1",
    screen: "S3 — Three-step flow",
    title: "Step 3 image — Feed Orphans",
    guidance:
      "Image for the third step of the journey. The middle step uses the in-app Sabiq Seed coin, so no upload is needed there.",
    aspect: "16:9 landscape",
  },
  {
    key: "onb_zikr_4",
    phase: "Phase 1",
    screen: "S4 — Azkaar",
    title: "Zikr screen artwork",
    guidance:
      "Image or screenshot for the azkaar moment. Replaces the built-in door↔scales animation when uploaded.",
    aspect: "Wide 3:2",
  },
  {
    key: "onb_impact_5",
    phase: "Phase 1",
    screen: "S5 — Real-World Impact",
    title: "Impact photograph",
    guidance:
      "Emotional peak photo — close-up, dignified, full-bleed across the top 60% of the screen.",
    aspect: "9:11 portrait",
  },
  {
    key: "onb_akhirah_7",
    phase: "Phase 1",
    screen: "S7 — Akhirah Account",
    title: "Akhirah screen screenshot",
    guidance:
      "Screenshot of the in-app Akhirah account view. Leave empty to use the built-in mock with teal sparkles.",
    aspect: "1:2 portrait",
  },
  {
    key: "cause_orphans",
    phase: "Phase 2",
    screen: "S9 — Causes",
    title: "Orphans card photo",
    guidance:
      "Photo for the Orphans cause card. Renders at ~16:11 aspect inside the 2×2 grid.",
    aspect: "16:11",
  },
  {
    key: "cause_water",
    phase: "Phase 2",
    screen: "S9 — Causes",
    title: "Water Wells card photo",
    guidance: "Photo for the Water Wells cause card.",
    aspect: "16:11",
  },
  {
    key: "cause_war",
    phase: "Phase 2",
    screen: "S9 — Causes",
    title: "War-Impacted Areas card photo",
    guidance: "Photo for the War-Impacted Areas card.",
    aspect: "16:11",
  },
  {
    key: "cause_disaster",
    phase: "Phase 2",
    screen: "S9 — Causes",
    title: "Natural Disasters card photo",
    guidance: "Photo for the Natural Disasters card.",
    aspect: "16:11",
  },
];

const BUCKET = "onboarding-images";

type Row = {
  slot_key: string;
  image_url: string | null;
  image_fit: string | null;
  updated_at: string;
};

// Crop / fit options the admin can pick per slot. Value "" = let the app
// decide (its built-in default for that slot).
const FIT_OPTIONS: { value: string; label: string }[] = [
  { value: "", label: "Auto (app default)" },
  { value: "cover_center", label: "Cover · center" },
  { value: "cover_top", label: "Cover · top" },
  { value: "cover_bottom", label: "Cover · bottom" },
  { value: "contain", label: "Contain · no crop" },
  { value: "fill", label: "Fill · stretch" },
];

// Tailwind object-* classes mirroring each fit, for the live preview.
const FIT_PREVIEW_CLASS: Record<string, string> = {
  "": "object-cover object-center",
  cover_center: "object-cover object-center",
  cover_top: "object-cover object-top",
  cover_bottom: "object-cover object-bottom",
  contain: "object-contain",
  fill: "object-fill",
};

export default function OnboardingImagesPage() {
  const [rows, setRows] = useState<Record<string, Row>>({});
  const [loading, setLoading] = useState(true);
  const [uploadingKey, setUploadingKey] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string>("");

  // Each row owns its own file input
  const fileRefs = useRef<Record<string, HTMLInputElement | null>>({});

  useEffect(() => {
    void load();
  }, []);

  async function load() {
    setLoading(true);
    setErrorMsg("");
    const { data, error } = await supabase
      .from("onboarding_images")
      .select("slot_key, image_url, image_fit, updated_at");
    if (error) {
      setErrorMsg(error.message);
      setLoading(false);
      return;
    }
    const map: Record<string, Row> = {};
    for (const r of (data ?? []) as Row[]) map[r.slot_key] = r;
    setRows(map);
    setLoading(false);
  }

  async function handleUpload(slotKey: string, file: File) {
    setUploadingKey(slotKey);
    setErrorMsg("");
    try {
      const ext = file.name.split(".").pop()?.toLowerCase() ?? "jpg";
      const mime =
        ext === "png"
          ? "image/png"
          : ext === "webp"
            ? "image/webp"
            : ext === "gif"
              ? "image/gif"
              : "image/jpeg";
      // Unique path per upload so CDN never serves a stale image after replace.
      const path = `${slotKey}/${crypto.randomUUID()}.${ext}`;
      const { error: upErr } = await supabase.storage
        .from(BUCKET)
        .upload(path, file, { contentType: mime, upsert: true });
      if (upErr) throw upErr;
      const { data } = supabase.storage.from(BUCKET).getPublicUrl(path);
      const url = data.publicUrl;
      const { error: dbErr } = await supabase
        .from("onboarding_images")
        .upsert(
          {
            slot_key: slotKey,
            image_url: url,
            updated_at: new Date().toISOString(),
          },
          { onConflict: "slot_key" }
        );
      if (dbErr) throw dbErr;
      await load();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      setErrorMsg(`Upload failed: ${msg}`);
    } finally {
      setUploadingKey(null);
    }
  }

  async function handleFitChange(slotKey: string, fit: string) {
    // Optimistic update so the preview reflects the choice instantly.
    setRows((prev) => ({
      ...prev,
      [slotKey]: {
        slot_key: slotKey,
        image_url: prev[slotKey]?.image_url ?? null,
        image_fit: fit || null,
        updated_at: new Date().toISOString(),
      },
    }));
    const { error } = await supabase.from("onboarding_images").upsert(
      {
        slot_key: slotKey,
        image_fit: fit || null,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "slot_key" }
    );
    if (error) setErrorMsg(`Could not save image fit: ${error.message}`);
  }

  async function handleReset(slotKey: string) {
    if (!confirm("Remove the uploaded image and fall back to the built-in default?")) return;
    setUploadingKey(slotKey);
    try {
      const { error } = await supabase
        .from("onboarding_images")
        .update({
          image_url: null,
          updated_at: new Date().toISOString(),
        })
        .eq("slot_key", slotKey);
      if (error) throw error;
      await load();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      setErrorMsg(`Reset failed: ${msg}`);
    } finally {
      setUploadingKey(null);
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="animate-spin w-6 h-6 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <header>
        <h2 className="text-2xl font-semibold text-slate-800 dark:text-white">
          Onboarding images
        </h2>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1 max-w-2xl">
          Upload the photo or screenshot for each onboarding slot. Slots
          marked &ldquo;mock&rdquo; have a built-in fallback so it&apos;s safe
          to leave them empty until you&apos;re ready. Recommended formats:
          JPEG, PNG, WebP, or GIF (animated supported) up to 10 MB.
        </p>
      </header>

      {errorMsg && (
        <div className="rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700 dark:bg-red-900/30 dark:border-red-800 dark:text-red-300">
          {errorMsg}
        </div>
      )}

      {(["Phase 1", "Phase 2"] as const).map((phase) => (
        <section key={phase} className="space-y-3">
          <h3 className="text-sm font-semibold tracking-wider uppercase text-slate-500 dark:text-slate-400">
            {phase}
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
            {SLOTS.filter((s) => s.phase === phase).map((slot) => {
              const row = rows[slot.key];
              const url = row?.image_url ?? null;
              const isUploading = uploadingKey === slot.key;
              return (
                <article
                  key={slot.key}
                  className="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 overflow-hidden flex flex-col"
                >
                  <div className="aspect-[4/3] bg-slate-100 dark:bg-slate-900 relative">
                    {url ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={url}
                        alt={slot.title}
                        className={`w-full h-full ${
                          FIT_PREVIEW_CLASS[row?.image_fit ?? ""] ??
                          "object-cover"
                        }`}
                      />
                    ) : (
                      <div className="absolute inset-0 flex flex-col items-center justify-center text-slate-400 dark:text-slate-500 gap-1.5 px-4 text-center">
                        <svg
                          className="w-8 h-8"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth={1.4}
                          viewBox="0 0 24 24"
                        >
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5zm10.5-11.25h.008v.008h-.008V8.25zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z"
                          />
                        </svg>
                        <p className="text-xs">No upload yet · built-in mock will show</p>
                      </div>
                    )}
                    {isUploading && (
                      <div className="absolute inset-0 bg-black/40 flex items-center justify-center">
                        <div className="animate-spin w-6 h-6 border-4 border-white border-t-transparent rounded-full" />
                      </div>
                    )}
                  </div>
                  <div className="p-4 flex-1 flex flex-col">
                    <div className="flex items-baseline justify-between gap-2">
                      <h4 className="text-sm font-semibold text-slate-800 dark:text-white">
                        {slot.title}
                      </h4>
                      <span className="text-[10px] font-medium uppercase tracking-wider text-slate-400 dark:text-slate-500">
                        {slot.aspect}
                      </span>
                    </div>
                    <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                      {slot.screen}
                    </p>
                    <p className="text-xs text-slate-500 dark:text-slate-400 mt-2 leading-relaxed flex-1">
                      {slot.guidance}
                    </p>
                    <p className="text-[10px] text-slate-400 dark:text-slate-600 mt-2 font-mono">
                      {slot.key}
                    </p>
                    <div className="flex gap-2 mt-3">
                      <input
                        ref={(el) => {
                          fileRefs.current[slot.key] = el;
                        }}
                        type="file"
                        accept="image/jpeg,image/png,image/webp,image/gif"
                        className="hidden"
                        onChange={(e) => {
                          const f = e.target.files?.[0];
                          if (f) void handleUpload(slot.key, f);
                          if (fileRefs.current[slot.key]) {
                            fileRefs.current[slot.key]!.value = "";
                          }
                        }}
                      />
                      <button
                        onClick={() => fileRefs.current[slot.key]?.click()}
                        disabled={isUploading}
                        className="flex-1 px-3 py-2 rounded-lg text-xs font-semibold bg-teal-600 hover:bg-teal-700 text-white disabled:opacity-50 transition cursor-pointer"
                      >
                        {url ? "Replace" : "Upload"}
                      </button>
                      {url && (
                        <button
                          onClick={() => void handleReset(slot.key)}
                          disabled={isUploading}
                          className="px-3 py-2 rounded-lg text-xs font-semibold border border-slate-200 dark:border-slate-600 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 disabled:opacity-50 transition cursor-pointer"
                        >
                          Reset
                        </button>
                      )}
                    </div>
                    {/* Crop / fit control — applies in the app and to the
                        preview thumbnail above. */}
                    <div className="flex items-center gap-2 mt-2.5">
                      <label className="text-[11px] font-medium text-slate-500 dark:text-slate-400 whitespace-nowrap">
                        Image fit
                      </label>
                      <select
                        value={row?.image_fit ?? ""}
                        onChange={(e) =>
                          void handleFitChange(slot.key, e.target.value)
                        }
                        className="flex-1 text-xs rounded-lg border border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-900 text-slate-700 dark:text-slate-200 px-2 py-1.5 cursor-pointer"
                      >
                        {FIT_OPTIONS.map((o) => (
                          <option key={o.value} value={o.value}>
                            {o.label}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>
                </article>
              );
            })}
          </div>
        </section>
      ))}
    </div>
  );
}
