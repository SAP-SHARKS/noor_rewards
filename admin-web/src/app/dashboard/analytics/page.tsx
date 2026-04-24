"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";

type CountryStat = {
  country: string;
  active_users: number;
  total_coins: number;
};

type DeviceStat = {
  device_type: string;
  user_count: number;
};

function countryFlag(iso: string): string {
  if (!iso || iso.length !== 2) return "--";
  const codePoints = [...iso.toUpperCase()].map(
    (c) => 0x1f1e6 - 65 + c.charCodeAt(0)
  );
  return String.fromCodePoint(...codePoints);
}

export default function AnalyticsPage() {
  const [countries, setCountries] = useState<CountryStat[]>([]);
  const [devices, setDevices] = useState<DeviceStat[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      const [{ data: c }, { data: d }] = await Promise.all([
        supabase
          .from("analytics_country_summary")
          .select("*")
          .order("active_users", { ascending: false })
          .limit(10),
        supabase.from("analytics_device_summary").select("*"),
      ]);
      setCountries(c ?? []);
      setDevices(d ?? []);
      setLoading(false);
    }
    load();
  }, []);

  if (loading)
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );

  const totalUsers = countries.reduce((s, c) => s + (c.active_users ?? 0), 0);
  const totalCoins = countries.reduce((s, c) => s + (c.total_coins ?? 0), 0);
  const totalDeviceUsers = devices.reduce(
    (s, d) => s + (d.user_count ?? 0),
    0
  );

  return (
    <div className="space-y-6">
      <p className="text-sm text-slate-500">
        30-day aggregated analytics. No personal user data.
      </p>

      {/* Summary cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white rounded-xl border border-slate-200 p-5">
          <p className="text-2xl font-bold text-slate-800">
            {totalUsers.toLocaleString()}
          </p>
          <p className="text-sm text-slate-500">Active Users (30d)</p>
        </div>
        <div className="bg-white rounded-xl border border-slate-200 p-5">
          <p className="text-2xl font-bold text-slate-800">
            {totalCoins.toLocaleString()}
          </p>
          <p className="text-sm text-slate-500">Coins Generated</p>
        </div>
        <div className="bg-white rounded-xl border border-slate-200 p-5">
          <p className="text-2xl font-bold text-slate-800">
            {countries.length}
          </p>
          <p className="text-sm text-slate-500">Countries</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Country table */}
        <div className="bg-white rounded-xl border border-slate-200 p-5">
          <h3 className="text-base font-semibold text-slate-800 mb-4">
            Users by Country
          </h3>
          <div className="space-y-2">
            {countries.map((c) => {
              const pct =
                totalUsers > 0
                  ? ((c.active_users / totalUsers) * 100).toFixed(1)
                  : "0";
              return (
                <div key={c.country} className="flex items-center gap-3">
                  <span className="text-lg">{countryFlag(c.country)}</span>
                  <span className="text-sm text-slate-700 flex-1">
                    {c.country || "Unknown"}
                  </span>
                  <span className="text-sm font-semibold text-slate-800">
                    {c.active_users}
                  </span>
                  <div className="w-24 bg-slate-100 rounded-full h-2">
                    <div
                      className="bg-teal-500 rounded-full h-2"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                  <span className="text-xs text-slate-400 w-10 text-right">
                    {pct}%
                  </span>
                </div>
              );
            })}
          </div>
        </div>

        {/* Device breakdown */}
        <div className="bg-white rounded-xl border border-slate-200 p-5">
          <h3 className="text-base font-semibold text-slate-800 mb-4">
            Users by Device
          </h3>
          <div className="space-y-3">
            {devices.map((d) => {
              const pct =
                totalDeviceUsers > 0
                  ? ((d.user_count / totalDeviceUsers) * 100).toFixed(1)
                  : "0";
              return (
                <div key={d.device_type}>
                  <div className="flex justify-between text-sm mb-1">
                    <span className="text-slate-700">
                      {d.device_type || "Unknown"}
                    </span>
                    <span className="font-semibold text-slate-800">
                      {d.user_count} ({pct}%)
                    </span>
                  </div>
                  <div className="w-full bg-slate-100 rounded-full h-3">
                    <div
                      className="bg-indigo-500 rounded-full h-3 transition-all"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                </div>
              );
            })}
            {devices.length === 0 && (
              <p className="text-sm text-slate-400">
                No device data available yet.
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
