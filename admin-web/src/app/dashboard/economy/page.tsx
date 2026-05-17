"use client";

import { useState } from "react";
import { useConfig } from "@/lib/config-context";

const ECONOMY_KEYS = [
  {
    key: "coins_per_ayah",
    label: "Points per Ayah",
    desc: "Points earned for each Quran ayah read",
  },
  {
    key: "coins_per_dhikr",
    label: "Points per Dhikr",
    desc: "Points earned for completing a dhikr set",
  },
  {
    key: "coins_per_tafsir_10min",
    label: "Points per 10min Tafsir",
    desc: "Points earned for 10 minutes of Tafsir listening",
  },
  {
    key: "coins_per_dua",
    label: "Points per Dua",
    desc: "Points earned per dua completion",
  },
  {
    key: "daily_free_cap",
    label: "Daily Free Cap",
    desc: "Max free points per day",
  },
  {
    key: "dhikr_advance_delay_seconds",
    label: "Dhikr Auto-Advance Delay (sec)",
    desc: "Seconds to hold a completed dhikr before sliding to the next. 0 = quick advance (current). e.g. 3 = hold 3 seconds. Users can always swipe manually.",
  },
];

export default function EconomyPage() {
  const { config, loading, save } = useConfig();
  const [editing, setEditing] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState<string | null>(null);
  const [initialized, setInitialized] = useState(false);

  // Sync editing state from config on first load
  if (!initialized && !loading) {
    const map: Record<string, string> = {};
    for (const { key } of ECONOMY_KEYS) map[key] = config[key] ?? "";
    setEditing(map);
    setInitialized(true);
  }

  async function handleSave(key: string) {
    setSaving(key);
    await save(key, editing[key]);
    setSaving(null);
  }

  if (loading)
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );

  return (
    <div className="max-w-3xl">
      <p className="text-sm text-slate-500 mb-6">
        Control earning rates for points across the app. Changes propagate to
        all users in real-time.
      </p>

      <div className="space-y-3">
        {ECONOMY_KEYS.map(({ key, label, desc }) => {
          const changed = editing[key] !== config[key];
          return (
            <div
              key={key}
              className="bg-white rounded-xl border border-slate-200 p-4 flex flex-col sm:flex-row sm:items-center gap-3"
            >
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-slate-800">{label}</p>
                <p className="text-xs text-slate-400">{desc}</p>
              </div>
              <div className="flex items-center gap-2">
                <input
                  type="number"
                  value={editing[key] ?? ""}
                  onChange={(e) =>
                    setEditing((prev) => ({ ...prev, [key]: e.target.value }))
                  }
                  className="w-28 px-3 py-2 border border-slate-200 rounded-lg text-sm text-right focus:outline-none focus:ring-2 focus:ring-teal-500"
                />
                <button
                  onClick={() => handleSave(key)}
                  disabled={!changed || saving === key}
                  className="px-4 py-2 bg-slate-800 text-white text-sm rounded-lg hover:bg-slate-900 disabled:opacity-30 transition cursor-pointer"
                >
                  {saving === key ? "..." : "Save"}
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
