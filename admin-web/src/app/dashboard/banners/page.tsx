"use client";

import { useState } from "react";
import { useConfig } from "@/lib/config-context";

const BANNER_FIELDS = [
  { key: "banner_enabled", label: "Banner Enabled", type: "toggle" as const },
  { key: "banner_text", label: "Banner Text", type: "text" as const },
  { key: "banner_color", label: "Banner Color", type: "color" as const },
  { key: "support_email", label: "Support Email", type: "text" as const },
  { key: "app_store_url", label: "iOS App Store URL", type: "text" as const },
  {
    key: "play_store_url",
    label: "Android Play Store URL",
    type: "text" as const,
  },
];

function flutterToHex(fc: string): string {
  if (fc?.startsWith("0x") && fc.length >= 10) return "#" + fc.slice(4);
  return fc || "#000000";
}
function hexToFlutter(hex: string): string {
  return "0xFF" + hex.replace("#", "").toUpperCase();
}

export default function BannersPage() {
  const { config, loading, save } = useConfig();
  const [editing, setEditing] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState<string | null>(null);
  const [initialized, setInitialized] = useState(false);

  if (!initialized && !loading) {
    const map: Record<string, string> = {};
    for (const f of BANNER_FIELDS) map[f.key] = config[f.key] ?? "";
    setEditing(map);
    setInitialized(true);
  }

  async function handleSave(key: string, value: string) {
    setSaving(key);
    await save(key, value);
    setEditing((prev) => ({ ...prev, [key]: value }));
    setSaving(null);
  }

  if (loading)
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );

  const bannerOn = config.banner_enabled === "true";

  return (
    <div className="max-w-2xl">
      <p className="text-sm text-slate-500 mb-6">
        Control the home screen banner and app store links.
      </p>

      {/* Banner Preview */}
      {bannerOn && config.banner_text && (
        <div
          className="rounded-xl p-4 mb-6 text-white text-sm font-medium text-center"
          style={{ backgroundColor: flutterToHex(config.banner_color) }}
        >
          {config.banner_text}
        </div>
      )}

      <div className="space-y-3">
        {BANNER_FIELDS.map((field) => (
          <div
            key={field.key}
            className="bg-white rounded-xl border border-slate-200 px-5 py-4 flex items-center gap-4 min-h-[72px]"
          >
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-slate-800">
                {field.label}
              </p>
            </div>

            <div className="shrink-0 pl-3">
              {field.type === "toggle" ? (
                <button
                  onClick={() =>
                    handleSave(field.key, bannerOn ? "false" : "true")
                  }
                  className={`relative w-[52px] h-[28px] rounded-full transition-colors cursor-pointer ${
                    bannerOn ? "bg-teal-500" : "bg-slate-200"
                  }`}
                >
                  <span
                    className={`absolute top-[2px] left-[2px] w-6 h-6 bg-white rounded-full shadow transition-transform ${
                      bannerOn ? "translate-x-6" : "translate-x-0"
                    }`}
                  />
                </button>
              ) : field.type === "color" ? (
                <input
                  type="color"
                  value={
                    flutterToHex(config[field.key] ?? "").length === 7
                      ? flutterToHex(config[field.key] ?? "")
                      : "#000000"
                  }
                  onChange={(e) =>
                    handleSave(field.key, hexToFlutter(e.target.value))
                  }
                  className="w-10 h-10 rounded-lg border border-slate-200 cursor-pointer p-0"
                />
              ) : (
                <div className="flex items-center gap-2">
                  <input
                    type="text"
                    value={editing[field.key] ?? ""}
                    onChange={(e) =>
                      setEditing((prev) => ({
                        ...prev,
                        [field.key]: e.target.value,
                      }))
                    }
                    className="w-56 px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
                  />
                  <button
                    onClick={() => handleSave(field.key, editing[field.key])}
                    disabled={
                      editing[field.key] === config[field.key] ||
                      saving === field.key
                    }
                    className="px-4 py-2 bg-teal-600 text-white text-sm rounded-lg hover:bg-teal-700 disabled:opacity-30 transition cursor-pointer"
                  >
                    {saving === field.key ? "..." : "Save"}
                  </button>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
