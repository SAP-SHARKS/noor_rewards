"use client";

import { useState, useEffect } from "react";
import { useConfig } from "@/lib/config-context";
import { supabase } from "@/lib/supabase";

// ── DB format: "FF2BAE99" (ARGB hex, no prefix) ─────────────────────────────

function toHex(db: string): string {
  if (!db || db.length < 6) return "#000000";
  let c = db.replace(/^0x/i, "").replace("#", "");
  if (c.length === 8) c = c.slice(2);
  return "#" + c;
}
function toDb(hex: string): string {
  return "FF" + hex.replace("#", "").toUpperCase();
}

// ── All color keys grouped by what they control in the app ──────────────────

const SECTIONS = [
  {
    id: "brand",
    title: "Brand & App-wide",
    desc: "These colors define the overall look of the app — buttons, accent colors, and Material theme.",
    keys: [
      { key: "primary_color", label: "Primary Color", hint: "Buttons, active tabs, links, and main accent throughout the entire app" },
      { key: "secondary_color", label: "Secondary Color", hint: "Secondary accent used by Material components" },
      { key: "donation_color", label: "Donation / CTA Color", hint: "Donate buttons, progress bars, and call-to-action highlights" },
      { key: "banner_color", label: "Banner Color", hint: "Background color of the top announcement banner" },
    ],
  },
  {
    id: "home",
    title: "Home Screen",
    desc: "Background and text colors for the main dashboard / home tab.",
    keys: [
      { key: "dash_bg", label: "Page Background", hint: "The background color of the entire home screen" },
      { key: "dash_text", label: "Text Color", hint: "Headings and body text on the home screen" },
      { key: "dash_teal", label: "Accent / Teal", hint: "Icons, highlights, and interactive elements on home" },
    ],
  },
  {
    id: "azkar",
    title: "Dhikr / Azkar Screen",
    desc: "Gradients and accents for the morning and evening azkar reading screens.",
    keys: [
      { key: "azkar_accent", label: "Accent", hint: "Counter button, progress indicators, active elements" },
      { key: "azkar_morning_grad1", label: "Morning — Top Gradient", hint: "Top gradient color for morning azkar screen" },
      { key: "azkar_morning_grad2", label: "Morning — Bottom Gradient", hint: "Bottom gradient color for morning azkar screen" },
      { key: "azkar_evening_grad1", label: "Evening — Top Gradient", hint: "Top gradient color for evening azkar screen" },
      { key: "azkar_evening_grad2", label: "Evening — Bottom Gradient", hint: "Bottom gradient color for evening azkar screen" },
      { key: "azkar_bottom_grad1", label: "General — Gradient 1", hint: "General dhikr screen gradient color 1" },
      { key: "azkar_bottom_grad2", label: "General — Gradient 2", hint: "General dhikr screen gradient color 2" },
      { key: "azkar_highlight", label: "Highlight Text", hint: "Color for Bismillah and special highlighted text" },
    ],
  },
  {
    id: "quran",
    title: "Quran Reader",
    desc: "Colors for the Quran mushaf reading experience.",
    keys: [
      { key: "quran_bg", label: "Page Background", hint: "Background of the Quran reading area" },
      { key: "quran_text", label: "Arabic Text", hint: "Color of the Quran Arabic text" },
      { key: "quran_accent", label: "Accent", hint: "Surah headers, selection highlights, controls" },
      { key: "quran_gold", label: "Gold / Ornaments", hint: "Bismillah banner, ayah markers, bookmark stars" },
    ],
  },
];

// ── Built-in presets ─────────────────────────────────────────────────────────

const BUILT_IN_PRESETS = [
  {
    name: "Noor Classic",
    desc: "Original teal and cream",
    colors: {
      primary_color: "FF2BAE99", secondary_color: "FF6B4EBB", donation_color: "FFF5A623",
      banner_color: "FF2BAE99",
      dash_bg: "FFF7F3EE", dash_text: "FF1C1C1E", dash_teal: "FF2BAE99",
      azkar_accent: "FF0D9488", azkar_morning_grad1: "FF0C4A3E", azkar_morning_grad2: "FF0D9488",
      azkar_evening_grad1: "FF1E1B4B", azkar_evening_grad2: "FF4338CA",
      azkar_bottom_grad1: "FF0A6B52", azkar_bottom_grad2: "FF0C4A3E", azkar_highlight: "FF1A7A5C",
      quran_bg: "FFEDF7F4", quran_text: "FF1C1C1E", quran_accent: "FF2BAE99", quran_gold: "FFFFAA00",
    },
  },
  {
    name: "Ocean Breeze",
    desc: "Cool blues and sky tones",
    colors: {
      primary_color: "FF0EA5E9", secondary_color: "FF0C4A6E", donation_color: "FF38BDF8",
      banner_color: "FF0EA5E9",
      dash_bg: "FFF0F9FF", dash_text: "FF0C4A6E", dash_teal: "FF0EA5E9",
      azkar_accent: "FF0EA5E9", azkar_morning_grad1: "FF075985", azkar_morning_grad2: "FF0EA5E9",
      azkar_evening_grad1: "FF1E3A5F", azkar_evening_grad2: "FF3B82F6",
      azkar_bottom_grad1: "FF0369A1", azkar_bottom_grad2: "FF075985", azkar_highlight: "FF0284C7",
      quran_bg: "FFF0F9FF", quran_text: "FF0C4A6E", quran_accent: "FF0EA5E9", quran_gold: "FFD4A843",
    },
  },
  {
    name: "Royal Indigo",
    desc: "Deep purple and violet",
    colors: {
      primary_color: "FF6366F1", secondary_color: "FF1E1B4B", donation_color: "FF818CF8",
      banner_color: "FF6366F1",
      dash_bg: "FFF5F3FF", dash_text: "FF1E1B4B", dash_teal: "FF6366F1",
      azkar_accent: "FF6366F1", azkar_morning_grad1: "FF312E81", azkar_morning_grad2: "FF6366F1",
      azkar_evening_grad1: "FF1E1B4B", azkar_evening_grad2: "FF4338CA",
      azkar_bottom_grad1: "FF3730A3", azkar_bottom_grad2: "FF312E81", azkar_highlight: "FF4F46E5",
      quran_bg: "FFF5F3FF", quran_text: "FF1E1B4B", quran_accent: "FF6366F1", quran_gold: "FFD4A843",
    },
  },
  {
    name: "Rose Warmth",
    desc: "Warm rose and soft pinks",
    colors: {
      primary_color: "FFE11D48", secondary_color: "FF4C0519", donation_color: "FFFB7185",
      banner_color: "FFE11D48",
      dash_bg: "FFFFF1F2", dash_text: "FF4C0519", dash_teal: "FFE11D48",
      azkar_accent: "FFE11D48", azkar_morning_grad1: "FF881337", azkar_morning_grad2: "FFE11D48",
      azkar_evening_grad1: "FF4C0519", azkar_evening_grad2: "FF881337",
      azkar_bottom_grad1: "FF9F1239", azkar_bottom_grad2: "FF881337", azkar_highlight: "FFBE123C",
      quran_bg: "FFFFF1F2", quran_text: "FF4C0519", quran_accent: "FFE11D48", quran_gold: "FFD4A843",
    },
  },
  {
    name: "Forest Green",
    desc: "Natural greens and earth tones",
    colors: {
      primary_color: "FF059669", secondary_color: "FF064E3B", donation_color: "FF34D399",
      banner_color: "FF059669",
      dash_bg: "FFECFDF5", dash_text: "FF064E3B", dash_teal: "FF059669",
      azkar_accent: "FF059669", azkar_morning_grad1: "FF065F46", azkar_morning_grad2: "FF059669",
      azkar_evening_grad1: "FF064E3B", azkar_evening_grad2: "FF065F46",
      azkar_bottom_grad1: "FF047857", azkar_bottom_grad2: "FF065F46", azkar_highlight: "FF059669",
      quran_bg: "FFECFDF5", quran_text: "FF064E3B", quran_accent: "FF059669", quran_gold: "FFD4A843",
    },
  },
  {
    name: "Midnight Dark",
    desc: "Dark mode feel, muted tones",
    colors: {
      primary_color: "FF94A3B8", secondary_color: "FF0F172A", donation_color: "FF64748B",
      banner_color: "FF475569",
      dash_bg: "FF1E293B", dash_text: "FFE2E8F0", dash_teal: "FF94A3B8",
      azkar_accent: "FF94A3B8", azkar_morning_grad1: "FF0F172A", azkar_morning_grad2: "FF334155",
      azkar_evening_grad1: "FF0F172A", azkar_evening_grad2: "FF1E293B",
      azkar_bottom_grad1: "FF1E293B", azkar_bottom_grad2: "FF0F172A", azkar_highlight: "FF64748B",
      quran_bg: "FF1E293B", quran_text: "FFE2E8F0", quran_accent: "FF94A3B8", quran_gold: "FFFFAA00",
    },
  },
];

// ── Saved custom themes type ─────────────────────────────────────────────────

type SavedTheme = {
  name: string;
  colors: Record<string, string>;
  created_at: string;
};

// ── Component ────────────────────────────────────────────────────────────────

export default function ThemePage() {
  const { config, loading, saveBatch } = useConfig();
  const [draft, setDraft] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [customThemes, setCustomThemes] = useState<SavedTheme[]>([]);
  const [showSaveAs, setShowSaveAs] = useState(false);
  const [customName, setCustomName] = useState("");

  // Load saved custom themes from localStorage
  useEffect(() => {
    const raw = localStorage.getItem("noor-admin-custom-themes");
    if (raw) setCustomThemes(JSON.parse(raw));
  }, []);

  function getColor(key: string): string {
    return draft[key] ?? config[key] ?? "";
  }

  function setColor(key: string, hex: string) {
    setSaved(false);
    setDraft((prev) => ({ ...prev, [key]: toDb(hex) }));
  }

  function loadPreset(colors: Record<string, string>) {
    setSaved(false);
    setDraft((prev) => ({ ...prev, ...colors }));
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
    setTimeout(() => setSaved(false), 4000);
  }

  function saveAsCustom() {
    if (!customName.trim()) return;
    // Collect all current colors (draft merged with config)
    const allKeys = SECTIONS.flatMap((s) => s.keys.map((k) => k.key));
    const colors: Record<string, string> = {};
    for (const key of allKeys) {
      colors[key] = draft[key] ?? config[key] ?? "";
    }
    const theme: SavedTheme = {
      name: customName.trim(),
      colors,
      created_at: new Date().toISOString(),
    };
    const updated = [...customThemes, theme];
    setCustomThemes(updated);
    localStorage.setItem("noor-admin-custom-themes", JSON.stringify(updated));
    setShowSaveAs(false);
    setCustomName("");
  }

  function deleteCustomTheme(index: number) {
    const updated = customThemes.filter((_, i) => i !== index);
    setCustomThemes(updated);
    localStorage.setItem("noor-admin-custom-themes", JSON.stringify(updated));
  }

  const hasChanges = Object.keys(draft).length > 0;
  const changedCount = Object.keys(draft).length;

  if (loading)
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );

  return (
    <div className="max-w-5xl space-y-8">

      {/* ── Sticky Save Bar ─────────────────────────────────────────────── */}
      {(hasChanges || saved) && (
        <div className="sticky top-[73px] z-10 bg-white border border-slate-200 rounded-xl shadow-lg px-5 py-3 flex items-center justify-between gap-4">
          {saved ? (
            <p className="text-sm font-medium text-green-600">
              Theme saved and pushed to all app users.
            </p>
          ) : (
            <p className="text-sm text-slate-600">
              <span className="font-semibold">{changedCount}</span> color{changedCount !== 1 ? "s" : ""} changed — preview below, then save to apply to the app.
            </p>
          )}
          {hasChanges && (
            <div className="flex items-center gap-2 shrink-0">
              <button onClick={discardChanges} className="px-3 py-2 text-sm text-slate-500 hover:text-slate-700 cursor-pointer">
                Discard
              </button>
              <button onClick={() => setShowSaveAs(true)} className="px-3 py-2 text-sm text-slate-600 border border-slate-200 rounded-lg hover:bg-slate-50 cursor-pointer">
                Save as Custom
              </button>
              <button onClick={handleSave} disabled={saving} className="px-5 py-2 bg-slate-800 text-white text-sm font-medium rounded-lg hover:bg-slate-900 disabled:opacity-50 transition cursor-pointer">
                {saving ? "Saving..." : "Apply to App"}
              </button>
            </div>
          )}
        </div>
      )}

      {/* ── Save As Dialog ──────────────────────────────────────────────── */}
      {showSaveAs && (
        <div className="bg-white border border-slate-200 rounded-xl shadow-lg p-5">
          <h3 className="text-sm font-semibold text-slate-800 mb-3">Save as Custom Theme</h3>
          <div className="flex items-center gap-3">
            <input
              type="text"
              value={customName}
              onChange={(e) => setCustomName(e.target.value)}
              placeholder="e.g. My Blue Theme"
              className="flex-1 px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-400"
              onKeyDown={(e) => e.key === "Enter" && saveAsCustom()}
            />
            <button onClick={saveAsCustom} disabled={!customName.trim()} className="px-4 py-2 bg-slate-800 text-white text-sm rounded-lg hover:bg-slate-900 disabled:opacity-30 cursor-pointer">
              Save
            </button>
            <button onClick={() => setShowSaveAs(false)} className="px-3 py-2 text-sm text-slate-400 hover:text-slate-600 cursor-pointer">
              Cancel
            </button>
          </div>
        </div>
      )}

      {/* ── Built-in Presets ────────────────────────────────────────────── */}
      <div>
        <h2 className="text-sm font-semibold text-slate-800 mb-1">Theme Presets</h2>
        <p className="text-xs text-slate-400 mb-4">
          Click a preset to load all its colors. Customize individual colors below, then click "Apply to App".
        </p>
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
          {BUILT_IN_PRESETS.map((preset) => (
            <button
              key={preset.name}
              onClick={() => loadPreset(preset.colors)}
              className="bg-white border border-slate-200 rounded-xl p-3 text-left hover:border-slate-400 hover:shadow-sm transition cursor-pointer group"
            >
              <div className="flex gap-1 mb-2">
                {["primary_color", "secondary_color", "donation_color"].map((k) => (
                  <div key={k} className="w-6 h-6 rounded-md border border-slate-100" style={{ backgroundColor: toHex((preset.colors as Record<string, string>)[k]) }} />
                ))}
              </div>
              <div className="flex gap-0.5 mb-2">
                {["dash_bg", "quran_bg", "azkar_morning_grad1"].map((k) => (
                  <div key={k} className="w-6 h-3 rounded-sm border border-slate-100" style={{ backgroundColor: toHex((preset.colors as Record<string, string>)[k]) }} />
                ))}
              </div>
              <p className="text-xs font-semibold text-slate-700">{preset.name}</p>
              <p className="text-[10px] text-slate-400 leading-tight mt-0.5">{preset.desc}</p>
            </button>
          ))}
        </div>
      </div>

      {/* ── Custom Saved Themes ────────────────────────────────────────── */}
      {customThemes.length > 0 && (
        <div>
          <h2 className="text-sm font-semibold text-slate-800 mb-1">Your Custom Themes</h2>
          <p className="text-xs text-slate-400 mb-3">Themes you saved. Click to load.</p>
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
            {customThemes.map((theme, i) => (
              <div key={i} className="bg-white border border-slate-200 rounded-xl p-3 relative group">
                <button
                  onClick={() => loadPreset(theme.colors)}
                  className="w-full text-left cursor-pointer"
                >
                  <div className="flex gap-1 mb-2">
                    {["primary_color", "secondary_color", "donation_color"].map((k) => (
                      <div key={k} className="w-6 h-6 rounded-md border border-slate-100" style={{ backgroundColor: toHex(theme.colors[k] ?? "") }} />
                    ))}
                  </div>
                  <p className="text-xs font-semibold text-slate-700">{theme.name}</p>
                </button>
                <button
                  onClick={() => deleteCustomTheme(i)}
                  className="absolute top-2 right-2 w-5 h-5 rounded-full bg-slate-100 text-slate-400 hover:bg-red-100 hover:text-red-500 text-[10px] flex items-center justify-center opacity-0 group-hover:opacity-100 transition cursor-pointer"
                >
                  x
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ── Color Sections ─────────────────────────────────────────────── */}
      {SECTIONS.map((section) => (
        <div key={section.id} className="bg-white rounded-2xl border border-slate-200 overflow-hidden">
          <div className="px-6 py-4 border-b border-slate-100">
            <h3 className="text-sm font-semibold text-slate-800">{section.title}</h3>
            <p className="text-xs text-slate-400">{section.desc}</p>
          </div>
          <div className="p-5">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {section.keys.map(({ key, label, hint }) => {
                const hex = toHex(getColor(key));
                const changed = draft[key] !== undefined;
                return (
                  <div key={key} className={`rounded-xl border p-3 transition ${changed ? "border-blue-300 bg-blue-50/30" : "border-slate-100 bg-slate-50/50"}`}>
                    <div className="flex items-start gap-3 mb-2.5">
                      <div
                        className="w-11 h-11 rounded-lg border border-slate-200 shrink-0 shadow-sm"
                        style={{ backgroundColor: hex.length === 7 ? hex : "#000" }}
                      />
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-semibold text-slate-700 leading-tight">{label}</p>
                        <p className="text-[10px] text-slate-400 leading-tight mt-0.5">{hint}</p>
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
                    {changed && <p className="text-[10px] text-blue-500 font-medium mt-1.5">Unsaved</p>}
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      ))}

      {/* ── Bottom Save ────────────────────────────────────────────────── */}
      {hasChanges && (
        <div className="bg-white border border-slate-200 rounded-xl p-5 flex items-center justify-between">
          <p className="text-sm text-slate-600">{changedCount} unsaved change{changedCount !== 1 ? "s" : ""}</p>
          <div className="flex items-center gap-2">
            <button onClick={discardChanges} className="px-4 py-2 text-sm text-slate-500 hover:text-slate-700 cursor-pointer">Discard</button>
            <button onClick={() => setShowSaveAs(true)} className="px-3 py-2 text-sm text-slate-600 border border-slate-200 rounded-lg hover:bg-slate-50 cursor-pointer">Save as Custom</button>
            <button onClick={handleSave} disabled={saving} className="px-6 py-2.5 bg-slate-800 text-white text-sm font-medium rounded-lg hover:bg-slate-900 disabled:opacity-50 transition cursor-pointer">
              {saving ? "Saving..." : "Apply to App"}
            </button>
          </div>
        </div>
      )}

      <div className="bg-slate-50 rounded-xl border border-slate-200 p-4">
        <p className="text-xs text-slate-500">
          All changes are staged locally until you click "Apply to App". Once applied,
          every connected app user sees the new theme within seconds via Supabase Realtime.
          Use "Save as Custom" to keep your favorite color combinations for later.
        </p>
      </div>
    </div>
  );
}
