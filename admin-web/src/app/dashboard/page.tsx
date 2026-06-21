"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { useConfig } from "@/lib/config-context";
import { TONE_LIGHT, TONE_DARK, type Tone } from "@/lib/admin-tones";

// Each stat card gets its own tone so the Overview reads at a glance.
// Pairs roughly: people/community → indigo, money → amber, mission → emerald,
// achievements → fuchsia.
type Card = {
  label: string;
  value: string;
  tone: Tone;
  icon: React.ReactNode;
  hint?: string;
};

// Heroicons (outline) — kept tiny and inline so we don't pull a library.
const Icons = {
  users: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.7} className="w-5 h-5">
      <path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
    </svg>
  ),
  coins: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.7} className="w-5 h-5">
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v12m-3-2.818l.879.659c1.171.879 3.07.879 4.242 0 1.172-.879 1.172-2.303 0-3.182C13.536 12.219 12.768 12 12 12c-2.121-.464-3.879-1.061-3.879-2.561 0-1.5 1.518-2.121 3.879-2.121.768 0 1.536.219 2.121.659l.879.659M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  ),
  projects: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.7} className="w-5 h-5">
      <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 3.75h.008v.008h-.008v-.008zm0 3h.008v.008h-.008v-.008zm0 3h.008v.008h-.008v-.008z" />
    </svg>
  ),
  trophy: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.7} className="w-5 h-5">
      <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 18.75h-9m9 0a3 3 0 013 3h-15a3 3 0 013-3m9 0v-3.375c0-.621-.503-1.125-1.125-1.125h-.871M7.5 18.75v-3.375c0-.621.504-1.125 1.125-1.125h.872m5.007 0H9.497m5.007 0a7.454 7.454 0 01-.982-3.172M9.497 14.25a7.454 7.454 0 00.981-3.172M5.25 4.236c-.982.143-1.954.317-2.916.52A6.003 6.003 0 007.73 9.728M5.25 4.236V4.5c0 2.108.966 3.99 2.48 5.228M5.25 4.236V2.721C7.456 2.41 9.71 2.25 12 2.25c2.291 0 4.545.16 6.75.47v1.516M7.73 9.728a6.726 6.726 0 002.748 1.35m8.272-6.842V4.5c0 2.108-.966 3.99-2.48 5.228m2.48-5.492a46.32 46.32 0 012.916.52 6.003 6.003 0 01-5.395 4.972m0 0a6.726 6.726 0 01-2.749 1.35m0 0a6.772 6.772 0 01-3.044 0" />
    </svg>
  ),
  flag: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.7} className="w-4 h-4">
      <path strokeLinecap="round" strokeLinejoin="round" d="M3 3v1.5M3 21v-6m0 0l2.77-.693a9 9 0 016.208.682l.108.054a9 9 0 006.086.71l3.114-.732a48.524 48.524 0 01-.005-10.499l-3.11.732a9 9 0 01-6.085-.711l-.108-.054a9 9 0 00-6.208-.682L3 4.5M3 15V4.5" />
    </svg>
  ),
  bolt: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.7} className="w-4 h-4">
      <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
    </svg>
  ),
  shield: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.7} className="w-4 h-4">
      <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12c0 1.268-.63 2.39-1.593 3.068a3.745 3.745 0 01-1.043 3.296 3.745 3.745 0 01-3.296 1.043A3.745 3.745 0 0112 21c-1.268 0-2.39-.63-3.068-1.593a3.746 3.746 0 01-3.296-1.043 3.745 3.745 0 01-1.043-3.296A3.745 3.745 0 013 12c0-1.268.63-2.39 1.593-3.068a3.745 3.745 0 011.043-3.296 3.746 3.746 0 013.296-1.043A3.746 3.746 0 0112 3c1.268 0 2.39.63 3.068 1.593a3.746 3.746 0 013.296 1.043 3.746 3.746 0 011.043 3.296A3.745 3.745 0 0121 12z" />
    </svg>
  ),
};

// Each config snapshot key gets a tone + icon based on its semantic role.
// Lets the admin scan the snapshot grid and tell economy from system at a
// glance without reading every label.
const KEY_META: Record<string, { tone: Tone; icon: React.ReactNode; pretty: string }> = {
  coins_per_ayah:   { tone: "amber",   icon: Icons.coins,  pretty: "Coins / Ayah" },
  coins_per_dhikr:  { tone: "amber",   icon: Icons.coins,  pretty: "Coins / Dhikr" },
  coins_per_dua:    { tone: "amber",   icon: Icons.coins,  pretty: "Coins / Dua" },
  daily_free_cap:   { tone: "sky",     icon: Icons.bolt,   pretty: "Daily Free Cap" },
  maintenance_mode: { tone: "rose",    icon: Icons.shield, pretty: "Maintenance Mode" },
  banner_enabled:   { tone: "fuchsia", icon: Icons.flag,   pretty: "Banner Enabled" },
};

export default function OverviewPage() {
  const { config, loading: configLoading } = useConfig();
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalPoints: 0,
    activeProjects: 0,
    badgesAwarded: 0,
  });
  const [loading, setLoading] = useState(true);
  const [dark, setDark] = useState(false);

  useEffect(() => {
    // Read the dark flag the layout writes, so pages can pick the matching
    // tone variant without re-implementing the toggle logic.
    const update = () =>
      setDark(document.documentElement.classList.contains("dark"));
    update();
    const obs = new MutationObserver(update);
    obs.observe(document.documentElement, { attributes: true, attributeFilter: ["class"] });
    return () => obs.disconnect();
  }, []);

  useEffect(() => {
    async function load() {
      const [
        { count: userCount },
        { data: pointsData },
        { count: projectCount },
        { count: badgeCount },
      ] = await Promise.all([
        // Exclude merged-out anon profiles from counts everywhere (rows
        // with `merged_into_id IS NOT NULL` are throwaway anon users
        // produced by re-login churn — see qf_auth_service).
        supabase
          .from("profiles")
          .select("*", { count: "exact", head: true })
          .is("merged_into_id", null),
        supabase
          .from("profiles")
          .select("noor_points")
          .is("merged_into_id", null),
        supabase
          .from("community_projects")
          .select("*", { count: "exact", head: true })
          .eq("is_active", true),
        supabase
          .from("user_badges")
          .select("*", { count: "exact", head: true }),
      ]);

      const totalPoints =
        pointsData?.reduce((sum, r) => sum + (r.noor_points ?? 0), 0) ?? 0;

      setStats({
        totalUsers: userCount ?? 0,
        totalPoints,
        activeProjects: projectCount ?? 0,
        badgesAwarded: badgeCount ?? 0,
      });
      setLoading(false);
    }
    load();
  }, []);

  if (loading || configLoading)
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );

  const cards: Card[] = [
    { label: "Total Users",         value: stats.totalUsers.toLocaleString(),    tone: "indigo",  icon: Icons.users,    hint: "Profiles in the app" },
    { label: "Total Points Earned", value: stats.totalPoints.toLocaleString(),   tone: "amber",   icon: Icons.coins,    hint: "Sum of all Noor points" },
    { label: "Active Projects",     value: stats.activeProjects.toString(),      tone: "emerald", icon: Icons.projects, hint: "Visible to donors" },
    { label: "Badges Awarded",      value: stats.badgesAwarded.toLocaleString(), tone: "fuchsia", icon: Icons.trophy,   hint: "Across all users" },
  ];

  const importantKeys = [
    "coins_per_ayah",
    "coins_per_dhikr",
    "coins_per_dua",
    "daily_free_cap",
    "maintenance_mode",
    "banner_enabled",
  ];

  return (
    <div className="space-y-6">
      {/* Stats grid — colored icon chip on the left, large value, hint underneath. */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {cards.map((c) => {
          const t = dark ? TONE_DARK[c.tone] : TONE_LIGHT[c.tone];
          return (
            <div
              key={c.label}
              className={`relative overflow-hidden rounded-xl border p-5 shadow-sm transition hover:shadow-md ${
                dark
                  ? `bg-slate-800/80 ${t.border}`
                  : `bg-white ${TONE_LIGHT[c.tone].border}`
              }`}
            >
              {/* Soft tinted bloom in the corner — adds color without
                  fighting the white card body for readability. */}
              <div
                className={`absolute -top-10 -right-10 w-28 h-28 rounded-full ${t.bg} opacity-70 blur-2xl pointer-events-none`}
              />
              <div className="relative flex items-start gap-3">
                <div
                  className={`w-10 h-10 rounded-lg flex items-center justify-center ring-1 ${t.bg} ${t.text} ${t.ring}`}
                >
                  {c.icon}
                </div>
                <div className="min-w-0">
                  <p className={`text-2xl font-bold leading-tight ${dark ? "text-white" : "text-slate-800"}`}>
                    {c.value}
                  </p>
                  <p className={`text-sm font-medium ${t.text}`}>{c.label}</p>
                  {c.hint && (
                    <p className={`text-xs mt-1 ${dark ? "text-slate-500" : "text-slate-400"}`}>
                      {c.hint}
                    </p>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Config snapshot — each pill takes the semantic tone of its key. */}
      <div
        className={`rounded-xl border p-6 shadow-sm ${
          dark
            ? "bg-slate-800/80 border-slate-700"
            : "bg-white border-slate-200"
        }`}
      >
        <div className="flex items-center justify-between mb-4">
          <h2 className={`text-base font-semibold ${dark ? "text-white" : "text-slate-800"}`}>
            Current Config Snapshot
          </h2>
          <span className={`text-xs ${dark ? "text-slate-500" : "text-slate-400"}`}>
            Live values
          </span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {importantKeys.map((key) => {
            const meta = KEY_META[key] ?? { tone: "slate" as Tone, icon: null, pretty: key };
            const t = dark ? TONE_DARK[meta.tone] : TONE_LIGHT[meta.tone];
            const rawValue = config[key];
            const displayValue =
              rawValue === undefined || rawValue === null || rawValue === ""
                ? "—"
                : String(rawValue);
            // For booleans, render an explicit on/off chip rather than "true"/"false".
            const isBool = displayValue === "true" || displayValue === "false";
            const boolOn = displayValue === "true";
            return (
              <div
                key={key}
                className={`rounded-lg p-3 ring-1 ${t.bg} ${t.ring}`}
              >
                <div className="flex items-center gap-2 mb-1">
                  {meta.icon && <span className={t.text}>{meta.icon}</span>}
                  <p className={`text-xs font-medium font-mono ${t.text}`}>{key}</p>
                </div>
                {isBool ? (
                  <span
                    className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-semibold ${
                      boolOn
                        ? dark
                          ? "bg-emerald-500/20 text-emerald-300"
                          : "bg-emerald-100 text-emerald-700"
                        : dark
                          ? "bg-slate-700 text-slate-400"
                          : "bg-slate-200 text-slate-600"
                    }`}
                  >
                    <span
                      className={`w-1.5 h-1.5 rounded-full ${
                        boolOn ? "bg-emerald-500" : "bg-slate-400"
                      }`}
                    />
                    {boolOn ? "ON" : "OFF"}
                  </span>
                ) : (
                  <p className={`text-base font-semibold ${dark ? "text-white" : "text-slate-800"}`}>
                    {displayValue}
                  </p>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
