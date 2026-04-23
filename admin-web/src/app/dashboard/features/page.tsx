"use client";

import { useEffect, useState, useRef } from "react";
import { supabase, fetchAllConfig, updateConfigKey } from "@/lib/supabase";

const FEATURE_FLAGS = [
  {
    key: "feature_leaderboard",
    label: "Leaderboard",
    desc: "Show rankings screen",
    icon: "🏆",
  },
  {
    key: "feature_challenges",
    label: "Challenges",
    desc: "Enable challenges system",
    icon: "🎯",
  },
  {
    key: "feature_badges",
    label: "Badges",
    desc: "Show badges/achievements",
    icon: "🏅",
  },
  {
    key: "feature_tafsir",
    label: "Tafsir",
    desc: "Enable Tafsir audio screen",
    icon: "📖",
  },
  {
    key: "feature_invite",
    label: "Invite Friends",
    desc: "Enable friend invites",
    icon: "💌",
  },
  {
    key: "maintenance_mode",
    label: "Maintenance Mode",
    desc: "Block ALL users from app (emergency only!)",
    icon: "🚨",
    danger: true,
  },
];

export default function FeaturesPage() {
  const [config, setConfig] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [toggling, setToggling] = useState<string | null>(null);
  const emailRef = useRef("");

  useEffect(() => {
    Promise.all([
      fetchAllConfig(),
      supabase.auth.getUser(),
    ]).then(([rows, { data }]) => {
      const map: Record<string, string> = {};
      for (const r of rows) map[r.key] = r.value;
      setConfig(map);
      emailRef.current = data.user?.email ?? "admin";
      setLoading(false);
    });
  }, []);

  async function handleToggle(key: string) {
    const current = config[key] === "true";
    if (
      key === "maintenance_mode" &&
      !current &&
      !confirm(
        "This will BLOCK ALL USERS from the app. Are you absolutely sure?"
      )
    )
      return;

    const newVal = current ? "false" : "true";
    setConfig((prev) => ({ ...prev, [key]: newVal }));
    setToggling(key);
    await updateConfigKey(key, newVal, emailRef.current);
    setToggling(null);
  }

  if (loading)
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );

  return (
    <div className="max-w-2xl">
      <p className="text-sm text-slate-500 mb-6">
        Toggle app features on/off. Changes apply to all users instantly.
      </p>

      <div className="space-y-3">
        {FEATURE_FLAGS.map((flag) => {
          const enabled = config[flag.key] === "true";
          const isDanger = flag.danger;
          return (
            <div
              key={flag.key}
              className={`bg-white rounded-xl border px-5 py-4 flex items-center gap-4 min-h-[72px] ${
                isDanger && enabled
                  ? "border-red-300 bg-red-50"
                  : "border-slate-200"
              }`}
            >
              <span className="text-2xl shrink-0">{flag.icon}</span>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-slate-800">
                  {flag.label}
                </p>
                <p className="text-xs text-slate-400">{flag.desc}</p>
              </div>
              <div className="shrink-0 pl-3">
                <button
                  onClick={() => handleToggle(flag.key)}
                  disabled={toggling === flag.key}
                  className={`relative w-[52px] h-[28px] rounded-full transition-colors cursor-pointer ${
                    enabled
                      ? isDanger
                        ? "bg-red-500"
                        : "bg-teal-500"
                      : "bg-slate-200"
                  }`}
                >
                  <span
                    className={`absolute top-[2px] left-[2px] w-6 h-6 bg-white rounded-full shadow transition-transform ${
                      enabled ? "translate-x-6" : "translate-x-0"
                    }`}
                  />
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
