"use client";

import { useState } from "react";
import { useConfig } from "@/lib/config-context";

const FEATURE_FLAGS = [
  { key: "feature_cause", label: "Cause Tab", desc: "Show the Cause tab in the app's bottom navigation" },
  { key: "feature_journey", label: "Journey Tab", desc: "Show the Journey tab in the app's bottom navigation" },
  { key: "feature_akhirah", label: "Akhirah Tab", desc: "Show the Akhirah tab in the app's bottom navigation" },
  { key: "feature_challenges", label: "Challenges Tab", desc: "Show the Challenges tab inside the Journey screen" },
  { key: "feature_leaderboard", label: "Leaderboard", desc: "Show rankings screen" },
  { key: "feature_badges", label: "Badges", desc: "Show badges/achievements" },
  { key: "feature_tafsir", label: "Tafsir", desc: "Enable Tafsir audio screen" },
  { key: "feature_invite", label: "Invite Friends", desc: "Enable friend invites" },
  { key: "maintenance_mode", label: "Maintenance Mode", desc: "Block ALL users from app (emergency only!)", danger: true },
];

export default function FeaturesPage() {
  const { config, loading, save } = useConfig();
  const [toggling, setToggling] = useState<string | null>(null);

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

    setToggling(key);
    await save(key, current ? "false" : "true");
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
              <div className={`w-9 h-9 rounded-lg shrink-0 flex items-center justify-center text-xs font-bold ${
                isDanger ? "bg-red-50 text-red-600" : "bg-teal-50 text-teal-600"
              }`}>
                {flag.label.charAt(0)}
              </div>
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
