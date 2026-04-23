"use client";

import { useConfig } from "@/lib/config-context";

const THEME_PRESETS = [
  {
    name: "Noor Classic",
    colors: {
      primary_color: "0xFF2BAE99",
      secondary_color: "0xFF0F172A",
      donation_accent: "0xFF10B981",
    },
  },
  {
    name: "Midnight",
    colors: {
      primary_color: "0xFF6366F1",
      secondary_color: "0xFF1E1B4B",
      donation_accent: "0xFF818CF8",
    },
  },
  {
    name: "Rose Garden",
    colors: {
      primary_color: "0xFFE11D48",
      secondary_color: "0xFF1C1917",
      donation_accent: "0xFFFB7185",
    },
  },
  {
    name: "Ocean",
    colors: {
      primary_color: "0xFF0EA5E9",
      secondary_color: "0xFF0C4A6E",
      donation_accent: "0xFF38BDF8",
    },
  },
];

const COLOR_KEYS = [
  { key: "primary_color", label: "Primary Color" },
  { key: "secondary_color", label: "Secondary Color" },
  { key: "donation_accent", label: "Donation Accent" },
  { key: "banner_color", label: "Banner Color" },
  { key: "azkar_accent", label: "Azkar Accent" },
  { key: "azkar_gradient_start", label: "Azkar Gradient Start" },
  { key: "azkar_gradient_end", label: "Azkar Gradient End" },
  { key: "azkar_highlight", label: "Azkar Highlight" },
  { key: "azkar_card_bg", label: "Azkar Card BG" },
  { key: "quran_bg", label: "Quran Background" },
  { key: "quran_accent", label: "Quran Accent" },
  { key: "quran_gold", label: "Quran Gold" },
  { key: "quran_text_color", label: "Quran Text" },
  { key: "dashboard_bg", label: "Dashboard BG" },
  { key: "dashboard_text", label: "Dashboard Text" },
  { key: "dashboard_teal", label: "Dashboard Teal" },
];

function flutterColorToHex(fc: string): string {
  if (fc && fc.startsWith("0x") && fc.length >= 10) {
    return "#" + fc.slice(4);
  }
  return fc || "#000000";
}

function hexToFlutterColor(hex: string): string {
  return "0xFF" + hex.replace("#", "").toUpperCase();
}

export default function ThemePage() {
  const { config, loading, save, saveBatch } = useConfig();

  if (loading)
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );

  return (
    <div className="max-w-4xl space-y-8">
      {/* Presets */}
      <div>
        <h2 className="text-base font-semibold text-slate-800 mb-3">
          Quick Theme Presets
        </h2>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {THEME_PRESETS.map((preset) => (
            <button
              key={preset.name}
              onClick={() => saveBatch(preset.colors)}
              className="bg-white border border-slate-200 rounded-xl p-4 text-left hover:border-teal-400 transition cursor-pointer"
            >
              <div className="flex gap-1 mb-2">
                {Object.values(preset.colors).map((c, i) => (
                  <div
                    key={i}
                    className="w-6 h-6 rounded-full border border-slate-200"
                    style={{ backgroundColor: flutterColorToHex(c) }}
                  />
                ))}
              </div>
              <p className="text-sm font-medium text-slate-700">
                {preset.name}
              </p>
            </button>
          ))}
        </div>
      </div>

      {/* Individual Colors */}
      <div>
        <h2 className="text-base font-semibold text-slate-800 mb-3">
          Individual Colors
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          {COLOR_KEYS.map(({ key, label }) => {
            const hex = flutterColorToHex(config[key] ?? "");
            return (
              <div
                key={key}
                className="bg-white border border-slate-200 rounded-xl p-4 flex items-center gap-3"
              >
                <input
                  type="color"
                  value={hex.length === 7 ? hex : "#000000"}
                  onChange={(e) =>
                    save(key, hexToFlutterColor(e.target.value))
                  }
                  className="w-10 h-10 rounded-lg border border-slate-200 cursor-pointer p-0"
                />
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-slate-700">{label}</p>
                  <p className="text-xs text-slate-400 font-mono">
                    {config[key] ?? "—"}
                  </p>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
