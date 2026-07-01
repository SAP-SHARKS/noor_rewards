"use client";

// Theme & Branding
//
// Full replacement of the old "Theme & Colors" tab. Three-part layout:
//   1. Theme Presets Gallery (top row) — one-click theme packages
//   2. Control Panel (left column) — granular color pickers, font, radius
//   3. Live Mobile Preview (right column, sticky) — a mock phone that
//      updates in real time as the draft theme changes
//
// State model:
//   liveTheme  — what's currently in Supabase (read via useConfig)
//   draft      — unsaved edits that drive the preview + pickers
//   presets    — hardcoded theme packages (each maps 1:1 to draft)
//
// Storage: values are written back into the existing app_config table using
// keys the Flutter AppConfig already recognizes (primary_color, dash_bg…)
// plus a few new keys (on_primary_color, font_family, border_radius).
// Colours are stored in the app's ARGB-hex format ("FFxxxxxx" — no prefix).

import { useMemo, useState } from "react";
import { useConfig } from "@/lib/config-context";

// ── ARGB hex helpers ───────────────────────────────────────────────────────

function toHex(db?: string): string {
  if (!db || db.length < 6) return "#000000";
  let c = db.replace(/^0x/i, "").replace("#", "");
  if (c.length === 8) c = c.slice(2);
  return "#" + c.toUpperCase();
}
function toDb(hex: string): string {
  return "FF" + hex.replace("#", "").toUpperCase();
}

// ── Theme shape (mirrors Flutter Material 3 ColorScheme) ──────────────────

type ThemeShape = {
  primary: string;         // #RRGGBB — buttons, active accents
  secondary: string;       // secondary accent
  surface: string;         // cards, sheets
  background: string;      // full-page bg
  onPrimary: string;       // text/icons on primary
  onSurface: string;       // text/icons on surface
  fontFamily: string;      // 'Inter' | 'Poppins' | 'Amiri' | ...
  borderRadius: number;    // 0..32 px
};

const DEFAULT_THEME: ThemeShape = {
  primary: "#7A8C3A",
  secondary: "#D89A1E",
  surface: "#FFFFFF",
  background: "#FFF4D2",
  onPrimary: "#FFFFFF",
  onSurface: "#2A2410",
  fontFamily: "Outfit",
  borderRadius: 14,
};

// ── Storage keys (mapped from ThemeShape to existing app_config columns) ──

const KEY_MAP = {
  primary: "primary_color",
  secondary: "secondary_color",
  surface: "surface_color",
  background: "dash_bg",
  onPrimary: "on_primary_color",
  onSurface: "dash_text",
  fontFamily: "font_family",
  borderRadius: "border_radius",
} as const;

function themeFromConfig(config: Record<string, string>): ThemeShape {
  return {
    primary: toHex(config[KEY_MAP.primary]) || DEFAULT_THEME.primary,
    secondary: toHex(config[KEY_MAP.secondary]) || DEFAULT_THEME.secondary,
    surface: toHex(config[KEY_MAP.surface]) || DEFAULT_THEME.surface,
    background: toHex(config[KEY_MAP.background]) || DEFAULT_THEME.background,
    onPrimary: toHex(config[KEY_MAP.onPrimary]) || DEFAULT_THEME.onPrimary,
    onSurface: toHex(config[KEY_MAP.onSurface]) || DEFAULT_THEME.onSurface,
    fontFamily: config[KEY_MAP.fontFamily] || DEFAULT_THEME.fontFamily,
    borderRadius:
      parseInt(config[KEY_MAP.borderRadius] ?? "", 10) ||
      DEFAULT_THEME.borderRadius,
  };
}

function themeToConfig(t: ThemeShape): Record<string, string> {
  return {
    [KEY_MAP.primary]: toDb(t.primary),
    [KEY_MAP.secondary]: toDb(t.secondary),
    [KEY_MAP.surface]: toDb(t.surface),
    [KEY_MAP.background]: toDb(t.background),
    [KEY_MAP.onPrimary]: toDb(t.onPrimary),
    [KEY_MAP.onSurface]: toDb(t.onSurface),
    [KEY_MAP.fontFamily]: t.fontFamily,
    [KEY_MAP.borderRadius]: String(t.borderRadius),
  };
}

// ── Theme presets ─────────────────────────────────────────────────────────

// Preset id === the `app_theme_mode` key in Flutter's theme_modes.dart.
// Clicking a preset writes both the mode (drives ~15 hardcoded accent
// palettes) AND the six M3 base colours (per-key overrides).
type Preset = {
  id: string;
  name: string;
  desc: string;
  theme: ThemeShape;
};

const PRESETS: Preset[] = [
  {
    id: "honey",
    name: "Honey",
    desc: "Warm sage + gold (default)",
    theme: {
      primary: "#7A8C3A",
      secondary: "#D89A1E",
      surface: "#FFFFFF",
      background: "#FFF4D2",
      onPrimary: "#FFFFFF",
      onSurface: "#2A2410",
      fontFamily: "Outfit",
      borderRadius: 16,
    },
  },
  {
    id: "mint",
    name: "Mint",
    desc: "Cool green throughout",
    theme: {
      primary: "#4E9F7A",
      secondary: "#6BC49A",
      surface: "#FFFFFF",
      background: "#EAF7EF",
      onPrimary: "#FFFFFF",
      onSurface: "#0F3D28",
      fontFamily: "Outfit",
      borderRadius: 16,
    },
  },
  {
    id: "sky",
    name: "Sky",
    desc: "Serene blue palette",
    theme: {
      primary: "#2E7CB8",
      secondary: "#4EA0E5",
      surface: "#FFFFFF",
      background: "#E8F3FB",
      onPrimary: "#FFFFFF",
      onSurface: "#103A5C",
      fontFamily: "Inter",
      borderRadius: 14,
    },
  },
  {
    id: "rose",
    name: "Rose",
    desc: "Warm pink + coral",
    theme: {
      primary: "#C87A94",
      secondary: "#E5A088",
      surface: "#FFFFFF",
      background: "#FBEEEE",
      onPrimary: "#FFFFFF",
      onSurface: "#4C1E28",
      fontFamily: "Fraunces",
      borderRadius: 18,
    },
  },
  {
    id: "gray",
    name: "Gray",
    desc: "Editorial neutral",
    theme: {
      primary: "#4A4A4A",
      secondary: "#7A7A7A",
      surface: "#FFFFFF",
      background: "#F5F5F5",
      onPrimary: "#FFFFFF",
      onSurface: "#1F1F1F",
      fontFamily: "Inter",
      borderRadius: 10,
    },
  },
  {
    id: "black",
    name: "Black",
    desc: "Dark mode",
    theme: {
      primary: "#FFC83D",
      secondary: "#D89A1E",
      surface: "#1F1F22",
      background: "#0F0F12",
      onPrimary: "#0F0F12",
      onSurface: "#F0F0F0",
      fontFamily: "Outfit",
      borderRadius: 16,
    },
  },
];

const FONT_OPTIONS = ["Inter", "Poppins", "Outfit", "Fraunces", "Amiri"];

// ── Page ───────────────────────────────────────────────────────────────────

export default function ThemeBrandingPage() {
  const { config, loading, saveBatch } = useConfig();

  // liveTheme derived from Supabase, draftTheme is the working copy.
  const liveTheme = useMemo(() => themeFromConfig(config), [config]);
  const liveMode = config["app_theme_mode"] ?? "honey";
  const [draft, setDraft] = useState<ThemeShape | null>(null);
  const [draftMode, setDraftMode] = useState<string | null>(null);
  const active = draft ?? liveTheme;
  const activeMode = draftMode ?? liveMode;

  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);

  const isDirty =
    (draft !== null && JSON.stringify(draft) !== JSON.stringify(liveTheme)) ||
    (draftMode !== null && draftMode !== liveMode);

  function patch<K extends keyof ThemeShape>(key: K, value: ThemeShape[K]) {
    setDraft((prev) => ({ ...(prev ?? liveTheme), [key]: value }));
  }

  function applyPreset(preset: Preset) {
    setDraft({ ...preset.theme });
    setDraftMode(preset.id); // drives the ~15 hardcoded accent palettes
  }

  function revert() {
    setDraft(null);
    setDraftMode(null);
  }

  async function publish() {
    if (!isDirty) return;
    setSaving(true);
    try {
      const payload: Record<string, string> = {
        ...(draft ? themeToConfig(draft) : {}),
      };
      if (draftMode !== null) payload["app_theme_mode"] = draftMode;
      await saveBatch(payload);
      setToast({ msg: "Theme published to live app.", ok: true });
      setDraft(null);
      setDraftMode(null);
    } catch (e) {
      setToast({
        msg: `Publish failed: ${e instanceof Error ? e.message : e}`,
        ok: false,
      });
    } finally {
      setSaving(false);
      setTimeout(() => setToast(null), 4000);
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-slate-300 border-t-slate-800 rounded-full" />
      </div>
    );
  }

  return (
    <div className="max-w-6xl space-y-6">
      {/* ── Header ─────────────────────────────────────────────────── */}
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-xl font-semibold text-slate-800">
            Theme &amp; Branding
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Pick a preset or fine-tune the palette, typography, and shape.
            Preview updates live — nothing ships until you press{" "}
            <span className="font-medium">Save &amp; Publish</span>.
          </p>
        </div>
        {toast && (
          <div
            className={`text-sm font-medium px-4 py-2 rounded-lg shrink-0 ${
              toast.ok
                ? "bg-emerald-50 text-emerald-700 border border-emerald-200"
                : "bg-red-50 text-red-700 border border-red-200"
            }`}
          >
            {toast.msg}
          </div>
        )}
      </div>

      {/* ── Section 1: Presets Gallery ─────────────────────────────── */}
      <section>
        <h2 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">
          Theme Packages
        </h2>
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
          {PRESETS.map((p) => (
            <PresetCard
              key={p.id}
              preset={p}
              active={p.id === activeMode}
              onClick={() => applyPreset(p)}
            />
          ))}
        </div>
      </section>

      {/* ── Section 2+3: Control Panel + Live Preview ─────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-[1fr_360px] gap-6">
        {/* Left: Controls */}
        <div className="space-y-5">
          {/* Revert / Publish bar */}
          <div className="bg-white border border-slate-200 rounded-2xl p-4 flex items-center justify-between gap-3">
            <div className="text-sm">
              {isDirty ? (
                <span className="text-amber-700">
                  <span className="font-semibold">Unsaved changes</span> —
                  preview reflects your draft.
                </span>
              ) : (
                <span className="text-slate-500">
                  You&apos;re viewing the live theme.
                </span>
              )}
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <button
                onClick={revert}
                disabled={!isDirty || saving}
                className="px-3 py-2 text-sm text-slate-600 border border-slate-200 rounded-lg hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer"
              >
                Revert to Live
              </button>
              <button
                onClick={publish}
                disabled={!isDirty || saving}
                className="px-4 py-2 text-sm font-medium bg-slate-800 text-white rounded-lg hover:bg-slate-900 disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer inline-flex items-center gap-2"
              >
                {saving && (
                  <span className="w-3.5 h-3.5 border-2 border-white/60 border-t-transparent rounded-full animate-spin" />
                )}
                Save &amp; Publish
              </button>
            </div>
          </div>

          {/* Color pickers */}
          <div className="bg-white border border-slate-200 rounded-2xl p-5">
            <h3 className="text-sm font-semibold text-slate-800 mb-1">
              Colors
            </h3>
            <p className="text-xs text-slate-400 mb-4">
              Maps to Flutter Material 3 <code>ColorScheme</code> — Primary,
              Secondary, Surface, Background, and their <code>on…</code>{" "}
              foreground pairs.
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <ColorField
                label="Primary"
                hint="Buttons, active tabs, accents"
                value={active.primary}
                onChange={(v) => patch("primary", v)}
              />
              <ColorField
                label="On-Primary"
                hint="Text/icons on Primary"
                value={active.onPrimary}
                onChange={(v) => patch("onPrimary", v)}
              />
              <ColorField
                label="Secondary"
                hint="Alt accent, chips, secondary CTAs"
                value={active.secondary}
                onChange={(v) => patch("secondary", v)}
              />
              <ColorField
                label="Surface"
                hint="Cards, sheets, panels"
                value={active.surface}
                onChange={(v) => patch("surface", v)}
              />
              <ColorField
                label="Background"
                hint="Full-page background"
                value={active.background}
                onChange={(v) => patch("background", v)}
              />
              <ColorField
                label="On-Surface"
                hint="Body text/icons on Surface"
                value={active.onSurface}
                onChange={(v) => patch("onSurface", v)}
              />
            </div>
          </div>

          {/* Typography + Shape */}
          <div className="bg-white border border-slate-200 rounded-2xl p-5 space-y-5">
            <div>
              <h3 className="text-sm font-semibold text-slate-800 mb-1">
                Typography
              </h3>
              <p className="text-xs text-slate-400 mb-3">
                Primary font family used across UI copy.
              </p>
              <select
                value={active.fontFamily}
                onChange={(e) => patch("fontFamily", e.target.value)}
                className="w-full sm:w-72 px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-slate-400"
              >
                {FONT_OPTIONS.map((f) => (
                  <option key={f} value={f}>
                    {f}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <div className="flex items-center justify-between mb-1">
                <h3 className="text-sm font-semibold text-slate-800">
                  Global Border Radius
                </h3>
                <span className="text-xs font-mono text-slate-500">
                  {active.borderRadius}px
                </span>
              </div>
              <p className="text-xs text-slate-400 mb-3">
                Applies to buttons, cards, chips, sheets.
              </p>
              <input
                type="range"
                min={0}
                max={32}
                step={1}
                value={active.borderRadius}
                onChange={(e) =>
                  patch("borderRadius", parseInt(e.target.value, 10))
                }
                className="w-full accent-slate-800"
              />
            </div>
          </div>
        </div>

        {/* Right: Sticky live phone preview */}
        <div className="lg:sticky lg:top-6 h-fit">
          <h2 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">
            Live Preview
          </h2>
          <PhonePreview theme={active} />
          <p className="mt-3 text-xs text-slate-400 leading-relaxed">
            Approximate rendering. Fonts fall back to system if not loaded in
            the browser.
          </p>
        </div>
      </div>
    </div>
  );
}

// ── Preset card ────────────────────────────────────────────────────────────

function PresetCard({
  preset,
  active,
  onClick,
}: {
  preset: Preset;
  active: boolean;
  onClick: () => void;
}) {
  const { theme } = preset;
  return (
    <button
      type="button"
      onClick={onClick}
      className={`group bg-white rounded-2xl p-3 text-left hover:shadow-md transition cursor-pointer border-2 ${
        active
          ? "border-slate-800 shadow-md"
          : "border-slate-200 hover:border-slate-400"
      }`}
    >
      {/* Mini palette */}
      <div
        className="rounded-xl overflow-hidden border border-slate-100 mb-2.5"
        style={{ backgroundColor: theme.background }}
      >
        <div className="flex h-10">
          <div className="flex-1" style={{ backgroundColor: theme.primary }} />
          <div className="flex-1" style={{ backgroundColor: theme.secondary }} />
          <div className="flex-1" style={{ backgroundColor: theme.surface }} />
        </div>
      </div>
      <div className="flex items-center justify-between">
        <p className="text-sm font-semibold text-slate-800 leading-tight">
          {preset.name}
        </p>
        {active && (
          <span className="text-[9px] font-bold uppercase tracking-wider bg-slate-800 text-white px-1.5 py-0.5 rounded">
            Live
          </span>
        )}
      </div>
      <p className="text-[11px] text-slate-400 leading-tight mt-0.5">
        {preset.desc}
      </p>
    </button>
  );
}

// ── Color picker field ─────────────────────────────────────────────────────

function ColorField({
  label,
  hint,
  value,
  onChange,
}: {
  label: string;
  hint: string;
  value: string;
  onChange: (v: string) => void;
}) {
  return (
    <div className="rounded-xl border border-slate-100 bg-slate-50/60 p-3">
      <div className="flex items-start gap-3 mb-2.5">
        <label className="relative w-11 h-11 rounded-lg border border-slate-200 shadow-sm cursor-pointer overflow-hidden shrink-0">
          <span
            className="absolute inset-0"
            style={{ backgroundColor: value }}
          />
          <input
            type="color"
            value={value}
            onChange={(e) => onChange(e.target.value)}
            className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
          />
        </label>
        <div className="flex-1 min-w-0">
          <p className="text-xs font-semibold text-slate-700 leading-tight">
            {label}
          </p>
          <p className="text-[10px] text-slate-400 leading-tight mt-0.5">
            {hint}
          </p>
        </div>
      </div>
      <input
        type="text"
        value={value.toUpperCase()}
        onChange={(e) => {
          const v = e.target.value;
          if (/^#[0-9A-Fa-f]{6}$/.test(v)) onChange(v.toUpperCase());
        }}
        className="w-full px-2 py-1.5 border border-slate-200 rounded text-xs font-mono text-slate-600 focus:outline-none focus:ring-2 focus:ring-slate-400"
      />
    </div>
  );
}

// ── Live mobile preview (mock phone frame) ────────────────────────────────

function PhonePreview({ theme }: { theme: ThemeShape }) {
  return (
    <div
      className="mx-auto"
      style={{ fontFamily: `'${theme.fontFamily}', system-ui, sans-serif` }}
    >
      {/* Phone frame */}
      <div className="w-full max-w-[300px] mx-auto rounded-[36px] bg-slate-900 p-2 shadow-2xl">
        <div
          className="rounded-[28px] overflow-hidden border-4 border-slate-900"
          style={{ backgroundColor: theme.background, minHeight: 540 }}
        >
          {/* Status bar */}
          <div className="flex items-center justify-between px-5 pt-3 pb-2 text-[10px] font-semibold"
               style={{ color: theme.onSurface }}>
            <span>9:41</span>
            <span>●●●●</span>
          </div>

          {/* App bar */}
          <div
            className="px-5 py-3 flex items-center justify-between"
            style={{
              backgroundColor: theme.primary,
              color: theme.onPrimary,
            }}
          >
            <span className="text-sm font-semibold">Al-Quran</span>
            <span className="text-xs opacity-80">Lvl 12</span>
          </div>

          {/* Content */}
          <div className="p-4 space-y-3">
            {/* Zikr card */}
            <div
              className="p-3.5"
              style={{
                backgroundColor: theme.surface,
                color: theme.onSurface,
                borderRadius: theme.borderRadius,
                boxShadow: "0 4px 12px rgba(0,0,0,0.06)",
              }}
            >
              <p className="text-[10px] uppercase tracking-wide opacity-60 font-semibold mb-1">
                Morning Dhikr
              </p>
              <p className="text-sm font-semibold mb-2">
                Subhanallahi wa bi-hamdihi
              </p>
              <div className="flex items-center justify-between text-xs">
                <span className="opacity-70">33 / 33</span>
                <span
                  className="px-2 py-1 text-[10px] font-bold"
                  style={{
                    backgroundColor: theme.secondary,
                    color: theme.onPrimary,
                    borderRadius: Math.min(theme.borderRadius, 12),
                  }}
                >
                  Done
                </span>
              </div>
            </div>

            {/* Sample text */}
            <p className="text-[13px] leading-relaxed opacity-80" style={{ color: theme.onSurface }}>
              Whoever remembers Allah in solitude and his eyes overflow…
            </p>

            {/* Primary button */}
            <button
              type="button"
              className="w-full py-2.5 text-sm font-semibold"
              style={{
                backgroundColor: theme.primary,
                color: theme.onPrimary,
                borderRadius: theme.borderRadius,
              }}
            >
              Continue Reading
            </button>

            {/* Secondary chip row */}
            <div className="flex gap-2 pt-1">
              <span
                className="text-[11px] px-3 py-1 font-medium"
                style={{
                  backgroundColor: theme.secondary,
                  color: theme.onPrimary,
                  borderRadius: theme.borderRadius,
                }}
              >
                Bookmarks
              </span>
              <span
                className="text-[11px] px-3 py-1 font-medium border"
                style={{
                  color: theme.onSurface,
                  borderColor: theme.onSurface + "33",
                  borderRadius: theme.borderRadius,
                }}
              >
                Tafsir
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
