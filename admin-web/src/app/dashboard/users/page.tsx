"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

// ─── Types ──────────────────────────────────────────────────────────────────
type Profile = {
  id: string;
  display_name: string | null;
  email: string | null;
  noor_points: number;
  level: number;
  day_streak: number;
  country: string | null;
  created_at: string;
};

type Analytics = {
  user_id: string;
  country_code: string | null;
  device_type: string | null;
  last_active_at: string | null;
};

type MonthlyAgg = {
  user_id: string;
  ayahs_read: number | null;
  dhikr_count: number | null;
};

type Row = Profile & {
  ayahs_read: number;
  dhikr_count: number;
  last_active_at: string | null;
  device_type: string | null;
  country_code: string | null;
};

type SortKey =
  | "name"
  | "email"
  | "country"
  | "device"
  | "level"
  | "points"
  | "streak"
  | "ayahs"
  | "azkar"
  | "lastActive"
  | "joined";

type SortDir = "asc" | "desc";

// ─── Helpers ────────────────────────────────────────────────────────────────
// Always render dates as MM/DD/YYYY regardless of browser locale.
function fmtMDY(iso: string | null | undefined): string {
  if (!iso) return "—";
  const d = new Date(iso);
  if (isNaN(d.getTime())) return "—";
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  const yyyy = d.getFullYear();
  return `${mm}/${dd}/${yyyy}`;
}

function fmtAgo(iso: string | null): string {
  if (!iso) return "—";
  const t = new Date(iso).getTime();
  if (isNaN(t)) return "—";
  const ms = Date.now() - t;
  const days = Math.floor(ms / 86_400_000);
  if (days < 1) return "today";
  if (days === 1) return "1d ago";
  if (days < 7) return `${days}d ago`;
  if (days < 30) return `${Math.floor(days / 7)}w ago`;
  if (days < 365) return `${Math.floor(days / 30)}mo ago`;
  return fmtMDY(iso);
}

// ─── Page ───────────────────────────────────────────────────────────────────
export default function UsersPage() {
  const [profiles, setProfiles] = useState<Profile[]>([]);
  const [analyticsMap, setAnalyticsMap] = useState<Map<string, Analytics>>(
    new Map(),
  );
  const [aggMap, setAggMap] = useState<
    Map<string, { ayahs_read: number; dhikr_count: number }>
  >(new Map());
  const [loading, setLoading] = useState(true);

  const [search, setSearch] = useState("");
  const [deviceFilter, setDeviceFilter] = useState("");
  const [countryFilter, setCountryFilter] = useState("");

  const [sortKey, setSortKey] = useState<SortKey>("points");
  const [sortDir, setSortDir] = useState<SortDir>("desc");

  const [grantUserId, setGrantUserId] = useState<string | null>(null);
  const [grantAmount, setGrantAmount] = useState("");
  const [granting, setGranting] = useState(false);

  async function load() {
    setLoading(true);

    const { data: profileData } = await supabase
      .from("profiles")
      .select(
        "id, display_name, email, noor_points, level, day_streak, country, created_at",
      )
      // Hide rows that have been merged into another profile — they're
      // kept in the table for audit but should never appear in the user
      // list. `_merge_profile_into` stamps merged_into_id on the source.
      .is("merged_into_id", null)
      .order("noor_points", { ascending: false })
      .limit(500);

    const profs = (profileData ?? []) as Profile[];
    setProfiles(profs);

    if (profs.length === 0) {
      setAnalyticsMap(new Map());
      setAggMap(new Map());
      setLoading(false);
      return;
    }

    const ids = profs.map((p) => p.id);

    const [analyticsRes, monthlyRes] = await Promise.all([
      supabase
        .from("user_analytics")
        .select("user_id, country_code, device_type, last_active_at")
        .in("user_id", ids),
      supabase
        .from("user_monthly_stats")
        .select("user_id, ayahs_read, dhikr_count")
        .in("user_id", ids),
    ]);

    const aMap = new Map<string, Analytics>();
    for (const r of (analyticsRes.data ?? []) as Analytics[]) {
      aMap.set(r.user_id, r);
    }

    const agg = new Map<string, { ayahs_read: number; dhikr_count: number }>();
    for (const r of (monthlyRes.data ?? []) as MonthlyAgg[]) {
      const cur = agg.get(r.user_id) ?? { ayahs_read: 0, dhikr_count: 0 };
      cur.ayahs_read += r.ayahs_read ?? 0;
      cur.dhikr_count += r.dhikr_count ?? 0;
      agg.set(r.user_id, cur);
    }

    setAnalyticsMap(aMap);
    setAggMap(agg);
    setLoading(false);
  }

  useEffect(() => {
    load();
  }, []);

  async function handleGrant(userId: string) {
    const amount = parseInt(grantAmount);
    if (!amount || amount <= 0) return;
    setGranting(true);
    await supabase.rpc("grant_points", {
      p_user_id: userId,
      p_amount: amount,
    });
    await load();
    setGrantUserId(null);
    setGrantAmount("");
    setGranting(false);
  }

  const rows = useMemo<Row[]>(() => {
    return profiles.map((p) => {
      const a = analyticsMap.get(p.id);
      const agg = aggMap.get(p.id) ?? { ayahs_read: 0, dhikr_count: 0 };
      return {
        ...p,
        ayahs_read: agg.ayahs_read,
        dhikr_count: agg.dhikr_count,
        last_active_at: a?.last_active_at ?? null,
        device_type: a?.device_type ?? null,
        country_code: a?.country_code ?? p.country ?? null,
      };
    });
  }, [profiles, analyticsMap, aggMap]);

  const filtered = useMemo(() => {
    let list = rows;
    const q = search.trim().toLowerCase();
    if (q) {
      list = list.filter(
        (r) =>
          (r.display_name ?? "").toLowerCase().includes(q) ||
          (r.email ?? "").toLowerCase().includes(q),
      );
    }
    if (deviceFilter) {
      list = list.filter(
        (r) => (r.device_type ?? "").toLowerCase() === deviceFilter,
      );
    }
    if (countryFilter) {
      list = list.filter(
        (r) => (r.country_code ?? "").toLowerCase() === countryFilter,
      );
    }
    return list;
  }, [rows, search, deviceFilter, countryFilter]);

  const sorted = useMemo(() => {
    const dir = sortDir === "asc" ? 1 : -1;
    const arr = [...filtered];
    const get = (r: Row): string | number => {
      switch (sortKey) {
        case "name":
          return (r.display_name ?? "").toLowerCase();
        case "email":
          return (r.email ?? "").toLowerCase();
        case "country":
          return (r.country_code ?? r.country ?? "").toLowerCase();
        case "device":
          return (r.device_type ?? "").toLowerCase();
        case "level":
          return r.level ?? 0;
        case "points":
          return r.noor_points ?? 0;
        case "streak":
          return r.day_streak ?? 0;
        case "ayahs":
          return r.ayahs_read ?? 0;
        case "azkar":
          return r.dhikr_count ?? 0;
        case "lastActive":
          return r.last_active_at ? new Date(r.last_active_at).getTime() : 0;
        case "joined":
          return r.created_at ? new Date(r.created_at).getTime() : 0;
      }
    };
    arr.sort((a, b) => {
      const av = get(a);
      const bv = get(b);
      if (typeof av === "number" && typeof bv === "number") {
        return (av - bv) * dir;
      }
      return String(av).localeCompare(String(bv)) * dir;
    });
    return arr;
  }, [filtered, sortKey, sortDir]);

  function toggleSort(k: SortKey) {
    if (sortKey === k) {
      setSortDir(sortDir === "asc" ? "desc" : "asc");
    } else {
      setSortKey(k);
      // Text-y columns default to A→Z, numeric to high→low.
      const textCols: SortKey[] = ["name", "email", "country", "device"];
      setSortDir(textCols.includes(k) ? "asc" : "desc");
    }
  }

  function arrow(k: SortKey) {
    if (sortKey !== k)
      return <span className="text-slate-300 ml-1">↕</span>;
    return (
      <span className="text-teal-600 ml-1">
        {sortDir === "asc" ? "↑" : "↓"}
      </span>
    );
  }

  const allCountries = useMemo(
    () =>
      Array.from(
        new Set(
          rows
            .map((r) => (r.country_code ?? r.country ?? "").toLowerCase())
            .filter((x) => x.length > 0),
        ),
      ).sort(),
    [rows],
  );

  const allDevices = useMemo(
    () =>
      Array.from(
        new Set(
          rows
            .map((r) => (r.device_type ?? "").toLowerCase())
            .filter((x) => x.length > 0),
        ),
      ).sort(),
    [rows],
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <div>
      {/* Filter bar */}
      <div className="flex flex-wrap items-center gap-3 mb-5">
        <input
          type="text"
          placeholder="Search name or email…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="flex-1 min-w-[220px] max-w-sm px-4 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
        />
        <select
          value={deviceFilter}
          onChange={(e) => setDeviceFilter(e.target.value)}
          className="px-3 py-2 border border-slate-200 rounded-lg text-sm bg-white cursor-pointer"
        >
          <option value="">All devices</option>
          {allDevices.map((d) => (
            <option key={d} value={d}>
              {d}
            </option>
          ))}
        </select>
        <select
          value={countryFilter}
          onChange={(e) => setCountryFilter(e.target.value)}
          className="px-3 py-2 border border-slate-200 rounded-lg text-sm bg-white cursor-pointer"
        >
          <option value="">All countries</option>
          {allCountries.map((c) => (
            <option key={c} value={c}>
              {c.toUpperCase()}
            </option>
          ))}
        </select>
        <button
          onClick={() => {
            setSearch("");
            setDeviceFilter("");
            setCountryFilter("");
          }}
          className="text-xs text-slate-500 hover:text-slate-800 cursor-pointer underline-offset-2 hover:underline"
        >
          Reset
        </button>
        <p className="ml-auto text-sm text-slate-500">
          {sorted.length} of {profiles.length} users
        </p>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-x-auto">
        <table className="w-full text-sm min-w-[1200px]">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200">
              <Th>#</Th>
              <Th onClick={() => toggleSort("name")}>Name{arrow("name")}</Th>
              <Th onClick={() => toggleSort("email")}>
                Email{arrow("email")}
              </Th>
              <Th onClick={() => toggleSort("country")}>
                Country{arrow("country")}
              </Th>
              <Th onClick={() => toggleSort("device")}>
                Device{arrow("device")}
              </Th>
              <Th right onClick={() => toggleSort("level")}>
                Level{arrow("level")}
              </Th>
              <Th right onClick={() => toggleSort("points")}>
                Points{arrow("points")}
              </Th>
              <Th right onClick={() => toggleSort("streak")}>
                Streak{arrow("streak")}
              </Th>
              <Th right onClick={() => toggleSort("ayahs")}>
                Ayahs read{arrow("ayahs")}
              </Th>
              <Th right onClick={() => toggleSort("azkar")}>
                Azkar read{arrow("azkar")}
              </Th>
              <Th right onClick={() => toggleSort("lastActive")}>
                Last login{arrow("lastActive")}
              </Th>
              <Th right onClick={() => toggleSort("joined")}>
                Joined{arrow("joined")}
              </Th>
              <Th right>Actions</Th>
            </tr>
          </thead>
          <tbody>
            {sorted.map((u, i) => (
              <tr
                key={u.id}
                className="border-b border-slate-100 last:border-0 hover:bg-slate-50 transition"
              >
                <td className="px-4 py-3 text-slate-400">{i + 1}</td>
                <td className="px-4 py-3">
                  <Link
                    href={`/dashboard/users/${u.id}`}
                    className="block group"
                  >
                    <p
                      className={`font-medium group-hover:text-teal-700 ${
                        u.display_name?.trim()
                          ? "text-slate-800"
                          : "text-slate-400 italic"
                      }`}
                    >
                      {u.display_name?.trim() || "Anonymous"}
                    </p>
                  </Link>
                </td>
                <td
                  className="px-4 py-3 text-slate-600 max-w-[220px] truncate"
                  title={u.email ?? undefined}
                >
                  {u.email || "—"}
                </td>
                <td className="px-4 py-3 text-slate-600 uppercase">
                  {u.country_code || u.country || "—"}
                </td>
                <td className="px-4 py-3 text-slate-600 capitalize">
                  {u.device_type || "—"}
                </td>
                <td className="px-4 py-3 text-right text-slate-600">
                  {u.level}
                </td>
                <td className="px-4 py-3 text-right font-semibold text-slate-800 tabular-nums">
                  {u.noor_points?.toLocaleString() ?? 0}
                </td>
                <td className="px-4 py-3 text-right text-slate-600 tabular-nums">
                  {u.day_streak ?? 0}d
                </td>
                <td className="px-4 py-3 text-right text-slate-600 tabular-nums">
                  {u.ayahs_read.toLocaleString()}
                </td>
                <td className="px-4 py-3 text-right text-slate-600 tabular-nums">
                  {u.dhikr_count.toLocaleString()}
                </td>
                <td className="px-4 py-3 text-right text-slate-500 text-xs">
                  {fmtAgo(u.last_active_at)}
                </td>
                <td className="px-4 py-3 text-right text-slate-500 text-xs">
                  {fmtMDY(u.created_at)}
                </td>
                <td className="px-4 py-3 text-right">
                  {grantUserId === u.id ? (
                    <div className="flex items-center justify-end gap-1">
                      <input
                        type="number"
                        value={grantAmount}
                        onChange={(e) => setGrantAmount(e.target.value)}
                        placeholder="Pts"
                        className="w-20 px-2 py-1 border border-slate-200 rounded text-xs text-right"
                      />
                      <button
                        onClick={() => handleGrant(u.id)}
                        disabled={granting}
                        className="px-2 py-1 bg-slate-800 text-white text-xs rounded hover:bg-slate-900 cursor-pointer"
                      >
                        {granting ? "..." : "Grant"}
                      </button>
                      <button
                        onClick={() => setGrantUserId(null)}
                        className="px-2 py-1 text-xs text-slate-400 hover:text-slate-600 cursor-pointer"
                      >
                        X
                      </button>
                    </div>
                  ) : (
                    <div className="flex items-center justify-end gap-3">
                      <Link
                        href={`/dashboard/users/${u.id}`}
                        className="text-xs text-slate-500 hover:text-slate-800"
                      >
                        Details
                      </Link>
                      <button
                        onClick={() => setGrantUserId(u.id)}
                        className="text-xs text-teal-600 hover:text-teal-800 cursor-pointer"
                      >
                        Grant
                      </button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
            {sorted.length === 0 && (
              <tr>
                <td
                  colSpan={13}
                  className="px-4 py-10 text-center text-sm text-slate-400"
                >
                  No users match the current filters.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function Th({
  children,
  right,
  onClick,
}: {
  children: React.ReactNode;
  right?: boolean;
  onClick?: () => void;
}) {
  return (
    <th
      onClick={onClick}
      className={[
        "px-4 py-3 font-medium text-slate-600 select-none whitespace-nowrap",
        right ? "text-right" : "text-left",
        onClick ? "cursor-pointer hover:text-slate-900" : "",
      ].join(" ")}
    >
      {children}
    </th>
  );
}
