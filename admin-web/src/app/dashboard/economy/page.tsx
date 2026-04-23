"use client";

import { useEffect, useState, useRef } from "react";
import {
  supabase,
  fetchAllConfig,
  updateConfigKey,
  type AppConfigRow,
} from "@/lib/supabase";

const ECONOMY_KEYS = [
  {
    key: "coins_per_ayah",
    label: "Coins per Ayah",
    desc: "Coins earned for each Quran ayah read",
  },
  {
    key: "coins_per_dhikr",
    label: "Coins per Dhikr",
    desc: "Coins earned for completing a dhikr set",
  },
  {
    key: "coins_per_tafsir_10min",
    label: "Coins per 10min Tafsir",
    desc: "Coins earned for 10 minutes of Tafsir listening",
  },
  {
    key: "coins_per_dua",
    label: "Coins per Dua",
    desc: "Coins earned per dua completion",
  },
  {
    key: "xp_per_ayah",
    label: "XP per Ayah",
    desc: "XP earned for each Quran ayah",
  },
  {
    key: "xp_per_dhikr",
    label: "XP per Dhikr",
    desc: "XP for completing a dhikr set",
  },
  {
    key: "xp_per_tafsir_10min",
    label: "XP per 10min Tafsir",
    desc: "XP for 10 minutes of Tafsir",
  },
  {
    key: "xp_daily_login",
    label: "XP Daily Login",
    desc: "XP bonus for daily login",
  },
  {
    key: "xp_validate_coins",
    label: "XP Validate Coins",
    desc: "XP for coin validation",
  },
  {
    key: "daily_free_cap",
    label: "Daily Free Cap",
    desc: "Max free coins per day",
  },
  {
    key: "weekly_xp_cap",
    label: "Weekly XP Cap",
    desc: "Max XP earnable per week",
  },
];

export default function EconomyPage() {
  const [config, setConfig] = useState<Record<string, string>>({});
  const [editing, setEditing] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const emailRef = useRef("");

  useEffect(() => {
    Promise.all([
      fetchAllConfig(),
      supabase.auth.getUser(),
    ]).then(([rows, { data }]) => {
      const map: Record<string, string> = {};
      for (const r of rows) map[r.key] = r.value;
      setConfig(map);
      setEditing(map);
      emailRef.current = data.user?.email ?? "admin";
      setLoading(false);
    });
  }, []);

  async function handleSave(key: string) {
    setSaving(key);
    await updateConfigKey(key, editing[key], emailRef.current);
    setConfig((prev) => ({ ...prev, [key]: editing[key] }));
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
        Control earning rates for coins and XP across the app. Changes propagate
        to all users in real-time.
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
                  className="px-4 py-2 bg-teal-600 text-white text-sm rounded-lg hover:bg-teal-700 disabled:opacity-30 transition cursor-pointer"
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
