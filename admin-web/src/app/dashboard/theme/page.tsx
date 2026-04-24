"use client";

import { useState } from "react";
import { useConfig } from "@/lib/config-context";

// ── Presets ──────────────────────────────────────────────────────────────────

const PRESETS = [
  {
    name: "Noor Classic",
    desc: "Default teal and dark navy",
    colors: {
      primary_color: "0xFF2BAE99", secondary_color: "0xFF0F172A", donation_accent: "0xFF10B981",
      dashboard_bg: "0xFF0F172A", dashboard_text: "0xFFFFFFFF", dashboard_teal: "0xFF2BAE99",
      azkar_accent: "0xFF2BAE99", azkar_gradient_start: "0xFF065F53", azkar_gradient_end: "0xFF0C4A3E",
      quran_bg: "0xFFF5F0E8", quran_accent: "0xFF2BAE99", quran_gold: "0xFFD4A843",
    },
  },
  {
    name: "Midnight",
    desc: "Deep indigo with violet accents",
    colors: {
      primary_color: "0xFF6366F1", secondary_color: "0xFF1E1B4B", donation_accent: "0xFF818CF8",
      dashboard_bg: "0xFF1E1B4B", dashboard_text: "0xFFFFFFFF", dashboard_teal: "0xFF6366F1",
      azkar_accent: "0xFF6366F1", azkar_gradient_start: "0xFF312E81", azkar_gradient_end: "0xFF1E1B4B",
      quran_bg: "0xFFF0EEFF", quran_accent: "0xFF6366F1", quran_gold: "0xFFD4A843",
    },
  },
  {
    name: "Rose Garden",
    desc: "Warm rose with crimson tones",
    colors: {
      primary_color: "0xFFE11D48", secondary_color: "0xFF1C1917", donation_accent: "0xFFFB7185",
      dashboard_bg: "0xFF1C1917", dashboard_text: "0xFFFFFFFF", dashboard_teal: "0xFFE11D48",
      azkar_accent: "0xFFE11D48", azkar_gradient_start: "0xFF881337", azkar_gradient_end: "0xFF4C0519",
      quran_bg: "0xFFFFF1F2", quran_accent: "0xFFE11D48", quran_gold: "0xFFD4A843",
    },
  },
  {
    name: "Ocean",
    desc: "Cool sky blue and deep teal",
    colors: {
      primary_color: "0xFF0EA5E9", secondary_color: "0xFF0C4A6E", donation_accent: "0xFF38BDF8",
      dashboard_bg: "0xFF0C4A6E", dashboard_text: "0xFFFFFFFF", dashboard_teal: "0xFF0EA5E9",
      azkar_accent: "0xFF0EA5E9", azkar_gradient_start: "0xFF075985", azkar_gradient_end: "0xFF0C4A6E",
      quran_bg: "0xFFF0F9FF", quran_accent: "0xFF0EA5E9", quran_gold: "0xFFD4A843",
    },
  },
  {
    name: "Emerald",
    desc: "Rich green with nature tones",
    colors: {
      primary_color: "0xFF059669", secondary_color: "0xFF064E3B", donation_accent: "0xFF34D399",
      dashboard_bg: "0xFF064E3B", dashboard_text: "0xFFFFFFFF", dashboard_teal: "0xFF059669",
      azkar_accent: "0xFF059669", azkar_gradient_start: "0xFF065F46", azkar_gradient_end: "0xFF064E3B",
      quran_bg: "0xFFECFDF5", quran_accent: "0xFF059669", quran_gold: "0xFFD4A843",
    },
  },
  {
    name: "Monochrome",
    desc: "Clean grayscale, minimal",
    colors: {
      primary_color: "0xFF475569", secondary_color: "0xFF0F172A", donation_accent: "0xFF64748B",
      dashboard_bg: "0xFF0F172A", dashboard_text: "0xFFFFFFFF", dashboard_teal: "0xFF475569",
      azkar_accent: "0xFF475569", azkar_gradient_start: "0xFF1E293B", azkar_gradient_end: "0xFF0F172A",
      quran_bg: "0xFFF8FAFC", quran_accent: "0xFF475569", quran_gold: "0xFFD4A843",
    },
  },
];

// ── Color groups ─────────────────────────────────────────────────────────────

const COLOR_GROUPS = [
  {
    title: "Global Colors",
    desc: "Primary brand colors used throughout the app",
    keys: [
      { key: "primary_color", label: "Primary", hint: "Main brand color, buttons, active states" },
      { key: "secondary_color", label: "Secondary", hint: "Dark backgrounds, navigation bar" },
      { key: "donation_accent", label: "Donation Accent", hint: "Donate buttons, progress bars" },
      { key: "banner_color", label: "Banner", hint: "Home screen announcement banner" },
    ],
  },
  {
    title: "Home Screen",
    desc: "Colors for the main dashboard/home screen",
    keys: [
      { key: "dashboard_bg", label: "Background", hint: "Home screen background" },
      { key: "dashboard_text", label: "Text", hint: "Home screen text color" },
      { key: "dashboard_teal", label: "Accent", hint: "Highlights and icons on home screen" },
    ],
  },
  {
    title: "Dhikr / Azkar Screen",
    desc: "Colors for the dhikr reading experience",
    keys: [
      { key: "azkar_accent", label: "Accent", hint: "Counter, buttons, active states" },
      { key: "azkar_gradient_start", label: "Gradient Top", hint: "Background gradient start" },
      { key: "azkar_gradient_end", label: "Gradient Bottom", hint: "Background gradient end" },
      { key: "azkar_highlight", label: "Highlight", hint: "Bismillah and special text color" },
      { key: "azkar_card_bg", label: "Card Background", hint: "Azkar text card background" },
    ],
  },
  {
    title: "Quran Reader",
    desc: "Colors for the Quran reading screen",
    keys: [
      { key: "quran_bg", label: "Page Background", hint: "Mushaf reading background" },
      { key: "quran_accent", label: "Accent", hint: "Surah headers, controls" },
      { key: "quran_gold", label: "Gold / Bismillah", hint: "Bismillah banner and ornaments" },
      { key: "quran_text_color", label: "Arabic Text", hint: "Quran Arabic text color" },
    ],
  },
];

// ── Helpers ──────────────────────────────────────────────────────────────────

function toHex(fc: string): string {
  if (fc?.startsWith("0x") && fc.length >= 10) return "#" + fc.slice(4);
  return fc || "#000000";
}

function toFlutter(hex: string): string {
  return "0xFF" + hex.replace("#", "").toUpperCase();
}

// ── Component ────────────────────────────────────────────────────────────────

export default function ThemePage() {
  const { config, loading, saveBatch } = useConfig();
  const [draft, setDraft] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  // Merged view: draft overrides config
  function getColor(key: string): string {
    return draft[key] ?? config[key] ?? "";
  }

  function setColor(key: string, hex: string) {
    setSaved(false);
    setDraft((prev) => ({ ...prev, [key]: toFlutter(hex) }));
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

  const primary = toHex(getColor("primary_color"));
  const secondary = toHex(getColor("secondary_color"));
  const accent = toHex(getColor("donation_accent"));

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
              <button
                onClick={discardChanges}
                className="px-4 py-2 text-sm text-slate-500 hover:text-slate-700 cursor-pointer"
              >
                Discard
              </button>
              <button
                onClick={handleSave}
                disabled={saving}
                className="px-5 py-2 bg-slate-800 text-white text-sm font-medium rounded-lg hover:bg-slate-900 disabled:opacity-50 transition cursor-pointer"
              >
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
          <p className="text-xs text-slate-400">
            Shows how your selected colors will look in the app
          </p>
        </div>
        <div className="p-6 flex gap-6 flex-wrap">
          {/* Mini phone mockup */}
          <div
            className="w-52 h-[340px] rounded-2xl overflow-hidden shadow-lg border border-slate-200 flex flex-col shrink-0"
            style={{ backgroundColor: secondary }}
          >
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
              <div
                className="w-full py-1.5 rounded-lg text-center text-[9px] font-medium text-white"
                style={{ backgroundColor: accent }}
              >
                Donate
              </div>
            </div>
            <div className="mt-auto px-4 py-2.5 flex justify-around border-t border-white/10">
              {[1, 2, 3, 4].map((i) => (
                <div
                  key={i}
                  className={`w-5 h-5 rounded-full ${i === 1 ? "" : "bg-white/15"}`}
                  style={i === 1 ? { backgroundColor: primary } : {}}
                />
              ))}
            </div>
          </div>

          {/* Current colors summary */}
          <div className="flex-1 min-w-[240px]">
            <p className="text-xs font-medium text-slate-500 mb-3">Active Colors</p>
            <div className="grid grid-cols-3 gap-3">
              {[
                { label: "Primary", key: "primary_color" },
                { label: "Secondary", key: "secondary_color" },
                { label: "Accent", key: "donation_accent" },
                { label: "Azkar", key: "azkar_accent" },
                { label: "Quran BG", key: "quran_bg" },
                { label: "Quran Gold", key: "quran_gold" },
              ].map((s) => {
                const hex = toHex(getColor(s.key));
                const changed = draft[s.key] !== undefined;
                return (
                  <div key={s.label} className="text-center">
                    <div
                      className={`w-full h-12 rounded-lg border mb-1.5 ${changed ? "border-blue-400 ring-2 ring-blue-100" : "border-slate-200"}`}
                      style={{ backgroundColor: hex }}
                    />
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
        <h2 className="text-sm font-semibold text-slate-800 mb-1">
          Theme Presets
        </h2>
        <p className="text-xs text-slate-400 mb-4">
          Select a preset to load its colors into the editor. You can customize
          individual colors below, then click Save to push to the app.
        </p>
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
          {PRESETS.map((preset) => {
            const p = toHex(preset.colors.primary_color);
            const s = toHex(preset.colors.secondary_color);
            const a = toHex(preset.colors.donation_accent);
            return (
              <button
                key={preset.name}
                onClick={() => applyPreset(preset)}
                className="bg-white border border-slate-200 rounded-xl p-3 text-left hover:border-slate-400 hover:shadow-sm transition cursor-pointer group"
              >
                <div className="flex gap-1 mb-2.5">
                  <div className="w-7 h-7 rounded-lg border border-slate-100" style={{ backgroundColor: p }} />
                  <div className="w-7 h-7 rounded-lg border border-slate-100" style={{ backgroundColor: s }} />
                  <div className="w-7 h-7 rounded-lg border border-slate-100" style={{ backgroundColor: a }} />
                </div>
                <p className="text-xs font-semibold text-slate-700">{preset.name}</p>
                <p className="text-[10px] text-slate-400 leading-tight mt-0.5">{preset.desc}</p>
              </button>
            );
          })}
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
                const hex = toHex(getColor(key));
                const changed = draft[key] !== undefined;
                return (
                  <div key={key} className={`rounded-xl border p-3 ${changed ? "border-blue-300 bg-blue-50/30" : "border-slate-100 bg-slate-50/50"}`}>
                    <div className="flex items-center gap-3 mb-2">
                      <div
                        className="w-10 h-10 rounded-lg border border-slate-200 shrink-0"
                        style={{ backgroundColor: hex.length === 7 ? hex : "#000" }}
                      />
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-semibold text-slate-700">{label}</p>
                        <p className="text-[10px] text-slate-400 leading-tight">{hint}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <input
                        type="color"
                        value={hex.length === 7 ? hex : "#000000"}
                        onChange={(e) => setColor(key, e.target.value)}
                        className="w-8 h-8 rounded border border-slate-200 cursor-pointer p-0 shrink-0"
                      />
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
                    {changed && (
                      <p className="text-[10px] text-blue-500 font-medium mt-1.5">Unsaved change</p>
                    )}
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
          <p className="text-sm text-slate-600">
            {changedCount} unsaved change{changedCount !== 1 ? "s" : ""}
          </p>
          <div className="flex items-center gap-2">
            <button
              onClick={discardChanges}
              className="px-4 py-2 text-sm text-slate-500 hover:text-slate-700 cursor-pointer"
            >
              Discard
            </button>
            <button
              onClick={handleSave}
              disabled={saving}
              className="px-6 py-2.5 bg-slate-800 text-white text-sm font-medium rounded-lg hover:bg-slate-900 disabled:opacity-50 transition cursor-pointer"
            >
              {saving ? "Saving..." : "Save Changes"}
            </button>
          </div>
        </div>
      )}

      {/* Info */}
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
