"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { useConfig } from "@/lib/config-context";

export default function OverviewPage() {
  const { config, loading: configLoading } = useConfig();
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalPoints: 0,
    activeProjects: 0,
    badgesAwarded: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      const [
        { count: userCount },
        { data: pointsData },
        { count: projectCount },
        { count: badgeCount },
      ] = await Promise.all([
        supabase.from("profiles").select("*", { count: "exact", head: true }),
        supabase.from("profiles").select("noor_points"),
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

  const cards = [
    { label: "Total Users", value: stats.totalUsers.toLocaleString() },
    { label: "Total Points Earned", value: stats.totalPoints.toLocaleString() },
    { label: "Active Projects", value: stats.activeProjects.toString() },
    { label: "Badges Awarded", value: stats.badgesAwarded.toLocaleString() },
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
      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {cards.map((c) => (
          <div
            key={c.label}
            className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm"
          >
            <div>
              <p className="text-2xl font-bold text-slate-800">{c.value}</p>
              <p className="text-sm text-slate-500">{c.label}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Config Snapshot */}
      <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-sm">
        <h2 className="text-base font-semibold text-slate-800 mb-4">
          Current Config Snapshot
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {importantKeys.map((key) => (
            <div key={key} className="bg-slate-50 rounded-lg p-3">
              <p className="text-xs text-slate-500 font-mono">{key}</p>
              <p className="text-sm font-semibold text-slate-800 mt-0.5">
                {config[key] ?? "—"}
              </p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
