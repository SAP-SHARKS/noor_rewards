"use client";

import { useState } from "react";
import { useConfig } from "@/lib/config-context";

// ── Presets (keys match Flutter AppConfig exactly) ───────────────────────────

const PRESETS = [
  {
    name: "Noor Classic",
    desc: "Default teal and dark navy",
    colors: {
      primary_color: "FF2BAE99", secondary_color: "FF0F172A", donation_color: "FF10B981",
      dash_bg: "FF0F172A", dash_text: "FFFFFFFF", dash_teal: "FF2BAE99",
      azkar_accent: "FF2BAE99", azkar_morning_grad1: "FF065F53", azkar_morning_grad2: "FF0D9488",
      azkar_evening_grad1: "FF1E1B4B", azkar_evening_grad2: "FF4338CA",
      azkar_highlight: "FF1A7A5C",
      quran_bg: "FFF5F0E8", quran_accent: "FF2BAE99", quran_gold: "FFD4A843", quran_text: "FF1C1C1E",
    },
  },
  {
    name: "Midnight",
    desc: "Deep indigo with violet accents",
    colors: {
      primary_color: "FF6366F1", secondary_color: "FF1E1B4B", donation_color: "FF818CF8",
      dash_bg: "FF1E1B4B", dash_text: "FFFFFFFF", dash_teal: "FF6366F1",
      azkar_accent: "FF6366F1", azkar_morning_grad1: "FF312E81", azkar_morning_grad2: "FF6366F1",
      azkar_evening_grad1: "FF1E1B4B", azkar_evening_grad2: "FF6366F1",
      azkar_highlight: "FF4F46E5",
      quran_bg: "FFF0EEFF", quran_accent: "FF6366F1", quran_gold: "FFD4A843", quran_text: "FF1C1C1E",
    },
  },
  {
    name: "Rose Garden",
    desc: "Warm rose with crimson tones",
    colors: {
      primary_color: "FFE11D48", secondary_color: "FF1C1917", donation_color: "FFFB7185",
      dash_bg: "FF1C1917", dash_text: "FFFFFFFF", dash_teal: "FFE11D48",
      azkar_accent: "FFE11D48", azkar_morning_grad1: "FF881337", azkar_morning_grad2: "FFE11D48",
      azkar_evening_grad1: "FF4C0519", azkar_evening_grad2: "FF881337",
      azkar_highlight: "FFE11D48",
      quran_bg: "FFFFF1F2", quran_accent: "FFE11D48", quran_gold: "FFD4A843", quran_text: "FF1C1C1E",
    },
  },
  {
    name: "Ocean",
    desc: "Cool sky blue and deep teal",
    colors: {
      primary_color: "FF0EA5E9", secondary_color: "FF0C4A6E", donation_color: "FF38BDF8",
      dash_bg: "FF0C4A6E", dash_text: "FFFFFFFF", dash_teal: "FF0EA5E9",
      azkar_accent: "FF0EA5E9", azkar_morning_grad1: "FF075985", azkar_morning_grad2: "FF0EA5E9",
      azkar_evening_grad1: "FF0C4A6E", azkar_evening_grad2: "FF075985",
      azkar_highlight: "FF0EA5E9",
      quran_bg: "FFF0F9FF", quran_accent: "FF0EA5E9", quran_gold: "FFD4A843", quran_text: "FF1C1C1E",
    },
  },
  {
    name: "Emerald",
    desc: "Rich green with nature tones",
    colors: {
      primary_color: "FF059669", secondary_color: "FF064E3B", donation_color: "FF34D399",
      dash_bg: "FF064E3B", dash_text: "FFFFFFFF", dash_teal: "FF059669",
      azkar_accent: "FF059669", azkar_morning_grad1: "FF065F46", azkar_morning_grad2: "FF059669",
      azkar_evening_grad1: "FF064E3B", azkar_evening_grad2: "FF065F46",
      azkar_highlight: "FF059669",
      quran_bg: "FFECFDF5", quran_accent: "FF059669", quran_gold: "FFD4A843", quran_text: "FF1C1C1E",
    },
  },
  {
    name: "Monochrome",
    desc: "Clean grayscale, minimal",
    colors: {
      primary_color: "FF475569", secondary_color: "FF0F172A", donation_color: "FF64748B",
      dash_bg: "FF0F172A", dash_text: "FFFFFFFF", dash_teal: "FF475569",
      azkar_accent: "FF475569", azkar_morning_grad1: "FF1E293B", azkar_morning_grad2: "FF475569",
      azkar_evening_grad1: "FF0F172A", azkar_evening_grad2: "FF1E293B",
      azkar_highlight: "FF475569",
      quran_bg: "FFF8FAFC", quran_accent: "FF475569", quran_gold: "FFD4A843", quran_text: "FF1C1C1E",
    },
  },
];

// ── Color groups (keys match Flutter AppConfig) ──────────────────────────────

const COLOR_GROUPS = [
  {
    title: "Global Colors",
    desc: "Primary brand colors used throughout the app",
    keys: [
      { key: "primary_color", label: "Primary", hint: "Main brand color, buttons, active states" },
      { key: "secondary_color", label: "Secondary", hint: "Dark backgrounds, navigation bar" },
      { key: "donation_color", label: "Donation Accent", hint: "Donate buttons, progress bars" },
      { key: "banner_color", label: "Banner", hint: "Home screen announcement banner" },
    ],
  },
  {
    title: "Home Screen",
    desc: "Colors for the main dashboard/home screen",
    keys: [
      { key: "dash_bg", label: "Background", hint: "Home screen background" },
      { key: "dash_text", label: "Text", hint: "Home screen text color" },
      { key: "dash_teal", label: "Accent", hint: "Highlights and icons on home" },
    ],
  },
  {
    title: "Dhikr / Azkar Screen",
    desc: "Colors for the dhikr reading experience",
    keys: [
      { key: "azkar_accent", label: "Accent", hint: "Counter, buttons, active states" },
      { key: "azkar_morning_grad1", label: "Morning Gradient Top", hint: "Morning azkar gradient start" },
      { key: "azkar_morning_grad2", label: "Morning Gradient Bottom", hint: "Morning azkar gradient end" },
      { key: "azkar_evening_grad1", label: "Evening Gradient Top", hint: "Evening azkar gradient start" },
      { key: "azkar_evening_grad2", label: "Evening Gradient Bottom", hint: "Evening azkar gradient end" },
      { key: "azkar_highlight", label: "Highlight", hint: "Bismillah and special text color" },
    ],
  },
  {
    title: "Quran Reader",
    desc: "Colors for the Quran reading screen",
    keys: [
      { key: "quran_bg", label: "Page Background", hint: "Mushaf reading background" },
      { key: "quran_accent", label: "Accent", hint: "Surah headers, controls" },
      { key: "quran_gold", label: "Gold / Bismillah", hint: "Bismillah banner and ornaments" },
      { key: "quran_text", label: "Arabic Text", hint: "Quran Arabic text color" },
    ],
  },
];

// ── Helpers ──────────────────────────────────────────────────────────────────

// DB stores: "FF2BAE99" (no 0x, no #)
// Browser color picker uses: "#2BAE99"
function dbToHex(db: string): string {
  if (!db || db.length < 6) return "#000000";
  // strip 0x prefix if present (legacy)
  let clean = db.replace(/^0x/i, "").replace("#", "");
  // if 8 chars (with alpha), take last 6
  if (clean.length === 8) clean = clean.slice(2);
  return "#" + clean;
}

function hexToDb(hex: string): string {
  // "#2BAE99" → "FF2BAE99"
  return "FF" + hex.replace("#", "").toUpperCase();
}

// ── Component ────────────────────────────────────────────────────────────────

export default function ThemePage() {
  const { config, loading, saveBatch } = useConfig();
  const [draft, setDraft] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  function getColor(key: string): string {
    return draft[key] ?? config[key] ?? "";
  }

  function setColor(key: string, hex: string) {
    setSaved(false);
    setDraft((prev) => ({ ...prev, [key]: hexToDb(hex) }));
  }

  function applyPreset(preset: (typeof PRESETS)[0]) {
    setSaved(false);
    setDraft((prev) => ({ ...prev, ...preset.colors }));
  }

  function discardChanges() {
    setDraft({});
    setSaved(false);
  }

  async function handleSave() {
    if (Object.keys(draft).length === 0) return;
    setSaving(true);
    await saveBatch(draft);
    setDraft({});
    setSaving(false);
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  }

  const hasChanges = Object.keys(draft).length > 0;
  const changedCount = Object.keys(draft).length;

  if (loading)
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );

  const primary = dbToHex(getColor("primary_color"));
  const secondary = dbToHex(getColor("secondary_color"));
  const accent = dbToHex(getColor("donation_color"));

  return (
    <div className="max-w-5xl space-y-8">

      {/* Sticky Save Bar */}
      {(hasChanges || saved) && (
        <div className="sticky top-[73px] z-10 bg-white border border-slate-200 rounded-xl shadow-lg px-5 py-3 flex items-center justify-between">
          <div>
            {saved ? (
              <p className="text-sm font-medium text-green-600">
                Changes saved and pushed to all users.
              </p>
            ) : (
              <p className="text-sm text-slate-600">
                <span className="font-semibold">{changedCount} color{changedCount !== 1 ? "s" : ""}</span> modified. Preview below, then save to push to the app.
              </p>
            )}
          </div>
          {hasChanges && (
            <div className="flex items-center gap-2">
              <button onClick={discardChanges} className="px-4 py-2 text-sm text-slate-500 hover:text-slate-700 cursor-pointer">
                Discard
              </button>
              <button onClick={handleSave} disabled={saving} className="px-5 py-2 bg-slate-800 text-white text-sm font-medium rounded-lg hover:bg-slate-900 disabled:opacity-50 transition cursor-pointer">
                {saving ? "Saving..." : "Save Changes"}
              </button>
            </div>
          )}
        </div>
      )}

      {/* Live Preview */}
      <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-100">
          <h2 className="text-sm font-semibold text-slate-800">Live Preview</h2>
          <p className="text-xs text-slate-400">Shows how your selected colors will look in the app</p>
        </div>
        <div className="p-6 flex gap-6 flex-wrap">
          <div className="w-52 h-[340px] rounded-2xl overflow-hidden shadow-lg border border-slate-200 flex flex-col shrink-0" style={{ backgroundColor: secondary }}>
            <div className="px-3 py-2 flex items-center justify-between">
              <span className="text-[10px] text-white/60">9:41</span>
              <span className="text-[10px] text-white/60 font-medium">Noor Rewards</span>
            </div>
            <div className="px-4 py-3">
              <div className="w-20 h-2 rounded-full bg-white/20 mb-2" />
              <div className="w-32 h-3 rounded-full bg-white/40 mb-1" />
              <div className="w-24 h-2 rounded-full bg-white/20" />
            </div>
            <div className="mx-3 p-3 rounded-xl bg-white/10">
              <div className="flex items-center gap-2 mb-3">
                <div className="w-8 h-8 rounded-full" style={{ backgroundColor: primary }} />
                <div>
                  <div className="w-16 h-2 rounded-full bg-white/30 mb-1" />
                  <div className="w-10 h-1.5 rounded-full bg-white/15" />
                </div>
              </div>
              <div className="w-full h-1.5 rounded-full bg-white/10 mb-2">
                <div className="h-full rounded-full" style={{ backgroundColor: primary, width: "65%" }} />
              </div>
              <div className="w-full py-1.5 rounded-lg text-center text-[9px] font-medium text-white" style={{ backgroundColor: accent }}>
                Donate
              </div>
            </div>
            <div className="mt-auto px-4 py-2.5 flex justify-around border-t border-white/10">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className={`w-5 h-5 rounded-full ${i === 1 ? "" : "bg-white/15"}`} style={i === 1 ? { backgroundColor: primary } : {}} />
              ))}
            </div>
          </div>
          <div className="flex-1 min-w-[240px]">
            <p className="text-xs font-medium text-slate-500 mb-3">Active Colors</p>
            <div className="grid grid-cols-3 gap-3">
              {[
                { label: "Primary", key: "primary_color" },
                { label: "Secondary", key: "secondary_color" },
                { label: "Donation", key: "donation_color" },
                { label: "Azkar", key: "azkar_accent" },
                { label: "Quran BG", key: "quran_bg" },
                { label: "Quran Gold", key: "quran_gold" },
              ].map((s) => {
                const hex = dbToHex(getColor(s.key));
                const changed = draft[s.key] !== undefined;
                return (
                  <div key={s.label} className="text-center">
                    <div className={`w-full h-12 rounded-lg border mb-1.5 ${changed ? "border-blue-400 ring-2 ring-blue-100" : "border-slate-200"}`} style={{ backgroundColor: hex }} />
                    <p className="text-[11px] text-slate-500">{s.label}</p>
                    {changed && <p className="text-[9px] text-blue-500 font-medium">Modified</p>}
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>

      {/* Presets */}
      <div>
        <h2 className="text-sm font-semibold text-slate-800 mb-1">Theme Presets</h2>
        <p className="text-xs text-slate-400 mb-4">Select a preset to load its colors. Customize below, then click Save.</p>
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
          {PRESETS.map((preset) => (
            <button key={preset.name} onClick={() => applyPreset(preset)} className="bg-white border border-slate-200 rounded-xl p-3 text-left hover:border-slate-400 hover:shadow-sm transition cursor-pointer group">
              <div className="flex gap-1 mb-2.5">
                {[preset.colors.primary_color, preset.colors.secondary_color, preset.colors.donation_color].map((c, i) => (
                  <div key={i} className="w-7 h-7 rounded-lg border border-slate-100" style={{ backgroundColor: dbToHex(c) }} />
                ))}
              </div>
              <p className="text-xs font-semibold text-slate-700">{preset.name}</p>
              <p className="text-[10px] text-slate-400 leading-tight mt-0.5">{preset.desc}</p>
            </button>
          ))}
        </div>
      </div>

      {/* Color Groups */}
      {COLOR_GROUPS.map((group) => (
        <div key={group.title} className="bg-white rounded-2xl border border-slate-200 overflow-hidden">
          <div className="px-6 py-4 border-b border-slate-100">
            <h3 className="text-sm font-semibold text-slate-800">{group.title}</h3>
            <p className="text-xs text-slate-400">{group.desc}</p>
          </div>
          <div className="p-5">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {group.keys.map(({ key, label, hint }) => {
                const hex = dbToHex(getColor(key));
                const changed = draft[key] !== undefined;
                return (
                  <div key={key} className={`rounded-xl border p-3 ${changed ? "border-blue-300 bg-blue-50/30" : "border-slate-100 bg-slate-50/50"}`}>
                    <div className="flex items-center gap-3 mb-2">
                      <div className="w-10 h-10 rounded-lg border border-slate-200 shrink-0" style={{ backgroundColor: hex.length === 7 ? hex : "#000" }} />
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-semibold text-slate-700">{label}</p>
                        <p className="text-[10px] text-slate-400 leading-tight">{hint}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <input type="color" value={hex.length === 7 ? hex : "#000000"} onChange={(e) => setColor(key, e.target.value)} className="w-8 h-8 rounded border border-slate-200 cursor-pointer p-0 shrink-0" />
                      <input
                        type="text"
                        value={hex.toUpperCase()}
                        onChange={(e) => {
                          const v = e.target.value;
                          if (/^#[0-9A-Fa-f]{6}$/.test(v)) setColor(key, v);
                        }}
                        className="flex-1 px-2 py-1.5 border border-slate-200 rounded text-xs font-mono text-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-400"
                      />
                    </div>
                    {changed && <p className="text-[10px] text-blue-500 font-medium mt-1.5">Unsaved change</p>}
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      ))}

      {/* Bottom Save */}
      {hasChanges && (
        <div className="bg-white border border-slate-200 rounded-xl p-5 flex items-center justify-between">
          <p className="text-sm text-slate-600">{changedCount} unsaved change{changedCount !== 1 ? "s" : ""}</p>
          <div className="flex items-center gap-2">
            <button onClick={discardChanges} className="px-4 py-2 text-sm text-slate-500 hover:text-slate-700 cursor-pointer">Discard</button>
            <button onClick={handleSave} disabled={saving} className="px-6 py-2.5 bg-slate-800 text-white text-sm font-medium rounded-lg hover:bg-slate-900 disabled:opacity-50 transition cursor-pointer">
              {saving ? "Saving..." : "Save Changes"}
            </button>
          </div>
        </div>
      )}

      <div className="bg-slate-50 rounded-xl border border-slate-200 p-4">
        <p className="text-xs text-slate-500">
          Pick colors using the color picker or type hex values directly. Changes
          are staged locally until you click Save. Once saved, all connected app
          users see the new theme within seconds via Supabase Realtime.
        </p>
      </div>
    </div>
  );
}
