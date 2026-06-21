"use client";

import { useEffect, useMemo, useState } from "react";
import { supabase } from "@/lib/supabase";
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

// ─── Types ──────────────────────────────────────────────────────────────────
type CountryStat = {
  country: string;
  active_users: number;
  total_coins: number;
};

type DeviceStat = {
  device_type: string;
  user_count: number;
};

type ProfileCountryRow = {
  id: string;
  country: string | null;
  noor_points: number | null;
};

type UserAnalyticsCountryRow = {
  user_id: string;
  country_code: string | null;
};

type FcmDeviceRow = {
  device_type: string | null;
};

type DailyStat = {
  user_id: string;
  stat_date: string;
  quran_time_sec: number | null;
  dhikr_time_sec: number | null;
  ayahs_read: number | null;
  dhikr_count: number | null;
};

type StreakProfile = {
  id: string;
  login_streak: number | null;
  dhikr_streak: number | null;
  quran_streak: number | null;
  noor_points: number | null;
  level: number | null;
  created_at: string;
};

type NotificationRow = {
  notification_type: string | null;
  sent_at: string | null;
  opened_at: string | null;
};

type PhraseRow = {
  phrase_id: string;
  count: number | null;
};

// ─── Constants ──────────────────────────────────────────────────────────────
const PALETTE = {
  teal: "#14b8a6",
  indigo: "#6366f1",
  amber: "#f59e0b",
  rose: "#f43f5e",
  violet: "#8b5cf6",
  slate: "#64748b",
};

const PIE_COLORS = [
  PALETTE.teal,
  PALETTE.indigo,
  PALETTE.amber,
  PALETTE.rose,
  PALETTE.violet,
  PALETTE.slate,
];

const MS_PER_DAY = 86_400_000;

// ─── Helpers ────────────────────────────────────────────────────────────────
function countryFlag(iso: string): string {
  if (!iso || iso.length !== 2) return "--";
  const codePoints = [...iso.toUpperCase()].map(
    (c) => 0x1f1e6 - 65 + c.charCodeAt(0),
  );
  return String.fromCodePoint(...codePoints);
}

function fmtDuration(sec: number): string {
  if (sec <= 0) return "0m";
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  if (h >= 100) return `${h.toLocaleString()}h`;
  if (h > 0) return `${h}h ${m}m`;
  return `${m}m`;
}

function shortDay(isoDay: string): string {
  // "2026-06-16" -> "06/16"
  const d = new Date(isoDay);
  if (isNaN(d.getTime())) return isoDay;
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${mm}/${dd}`;
}

// ─── Page ───────────────────────────────────────────────────────────────────
export default function AnalyticsPage() {
  const [countries, setCountries] = useState<CountryStat[]>([]);
  const [devices, setDevices] = useState<DeviceStat[]>([]);

  const [totalProfiles, setTotalProfiles] = useState(0);
  const [newSignupsToday, setNewSignupsToday] = useState(0);
  const [newSignups7d, setNewSignups7d] = useState(0);
  const [pushOptIn, setPushOptIn] = useState(0);

  const [daily, setDaily] = useState<DailyStat[]>([]);
  const [streakProfiles, setStreakProfiles] = useState<StreakProfile[]>([]);
  const [notifications, setNotifications] = useState<NotificationRow[]>([]);
  const [topPhrases, setTopPhrases] = useState<{ phrase_id: string; count: number }[]>([]);
  const [signupsByDay, setSignupsByDay] = useState<{ day: string; count: number }[]>([]);

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function load() {
      setLoading(true);
      setError(null);
      try {
        const now = new Date();
        const startOfToday = new Date(now);
        startOfToday.setUTCHours(0, 0, 0, 0);
        const sevenAgo = new Date(now.getTime() - 7 * MS_PER_DAY);
        const thirtyAgo = new Date(now.getTime() - 30 * MS_PER_DAY);
        const start30 = thirtyAgo.toISOString().slice(0, 10);

        const [
          profileCountryRes,
          analyticsCountryRes,
          fcmDeviceRes,
          totalRes,
          newTodayRes,
          new7dRes,
          fcmCountRes,
          dailyRes,
          streakRes,
          notifRes,
          phraseRes,
          signupListRes,
        ] = await Promise.all([
          supabase
            .from("profiles")
            .select("id, country, noor_points")
            .is("merged_into_id", null)
            .limit(50_000),

          supabase
            .from("user_analytics")
            .select("user_id, country_code")
            .not("country_code", "is", null)
            .limit(50_000),

          supabase
            .from("fcm_tokens")
            .select("device_type")
            .limit(50_000),

          supabase
            .from("profiles")
            .select("*", { count: "exact", head: true })
            .is("merged_into_id", null),
          supabase
            .from("profiles")
            .select("*", { count: "exact", head: true })
            .is("merged_into_id", null)
            .gte("created_at", startOfToday.toISOString()),
          supabase
            .from("profiles")
            .select("*", { count: "exact", head: true })
            .is("merged_into_id", null)
            .gte("created_at", sevenAgo.toISOString()),
          supabase
            .from("fcm_tokens")
            .select("*", { count: "exact", head: true }),

          supabase
            .from("user_daily_stats")
            .select(
              "user_id, stat_date, quran_time_sec, dhikr_time_sec, ayahs_read, dhikr_count",
            )
            .gte("stat_date", start30),

          supabase
            .from("profiles")
            .select(
              "id, login_streak, dhikr_streak, quran_streak, noor_points, level, created_at",
            )
            .is("merged_into_id", null),

          supabase
            .from("notification_log")
            .select("notification_type, sent_at, opened_at")
            .not("notification_id", "is", null)
            .gte("sent_at", thirtyAgo.toISOString())
            .limit(50_000),

          supabase
            .from("user_dhikr_phrase_counts")
            .select("phrase_id, count")
            .order("count", { ascending: false })
            .limit(10),

          supabase
            .from("profiles")
            .select("created_at")
            .is("merged_into_id", null)
            .gte(
              "created_at",
              new Date(now.getTime() - 30 * MS_PER_DAY).toISOString(),
            ),
        ]);

        // Country aggregation: prefer real IP-detected country code from
        // user_analytics; fall back to the profile-entered country for users
        // who haven't been geolocated yet. The Flutter tracking service
        // populates user_analytics.country_code on first session.
        const profileRows = (profileCountryRes.data ?? []) as ProfileCountryRow[];
        const fcmRows = (fcmDeviceRes.data ?? []) as FcmDeviceRow[];
        const ipCountryByUid = new Map<string, string>();
        for (const r of (analyticsCountryRes.data ??
          []) as UserAnalyticsCountryRow[]) {
          if (r.country_code) {
            ipCountryByUid.set(r.user_id, r.country_code.toUpperCase());
          }
        }

        const countryAgg = new Map<string, { active_users: number; total_coins: number }>();
        for (const p of profileRows) {
          // IP-detected wins; profile country is the fallback.
          const code =
            ipCountryByUid.get(p.id) ?? (p.country ?? "").trim();
          if (!code) continue;
          const key = code.length === 2 ? code.toUpperCase() : code;
          const cur = countryAgg.get(key) ?? { active_users: 0, total_coins: 0 };
          cur.active_users += 1;
          cur.total_coins += p.noor_points ?? 0;
          countryAgg.set(key, cur);
        }
        setCountries(
          Array.from(countryAgg.entries())
            .map(([country, v]) => ({
              country,
              active_users: v.active_users,
              total_coins: v.total_coins,
            }))
            .sort((a, b) => b.active_users - a.active_users)
            .slice(0, 10),
        );

        const deviceAgg = new Map<string, number>();
        for (const r of fcmRows) {
          const dev = (r.device_type ?? "").toLowerCase().trim();
          if (!dev) continue;
          deviceAgg.set(dev, (deviceAgg.get(dev) ?? 0) + 1);
        }
        setDevices(
          Array.from(deviceAgg.entries()).map(([device_type, user_count]) => ({
            device_type,
            user_count,
          })),
        );
        setTotalProfiles(totalRes.count ?? 0);
        setNewSignupsToday(newTodayRes.count ?? 0);
        setNewSignups7d(new7dRes.count ?? 0);
        setPushOptIn(fcmCountRes.count ?? 0);
        setDaily((dailyRes.data as DailyStat[]) ?? []);
        setStreakProfiles((streakRes.data as StreakProfile[]) ?? []);
        setNotifications((notifRes.data as NotificationRow[]) ?? []);
        setTopPhrases(
          ((phraseRes.data as PhraseRow[]) ?? []).map((p) => ({
            phrase_id: p.phrase_id,
            count: p.count ?? 0,
          })),
        );

        // Bucket signups by day for the 30-day trend chart
        const buckets = new Map<string, number>();
        for (let i = 29; i >= 0; i--) {
          const d = new Date(now.getTime() - i * MS_PER_DAY);
          buckets.set(d.toISOString().slice(0, 10), 0);
        }
        for (const r of (signupListRes.data ?? []) as { created_at: string }[]) {
          const day = r.created_at.slice(0, 10);
          if (buckets.has(day)) buckets.set(day, (buckets.get(day) ?? 0) + 1);
        }
        setSignupsByDay(
          Array.from(buckets.entries()).map(([day, count]) => ({ day, count })),
        );
      } catch (e) {
        setError(e instanceof Error ? e.message : String(e));
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  // ── Aggregates ──────────────────────────────────────────────────────────
  const totals30 = useMemo(() => {
    const dau = new Set<string>();
    let ayahs = 0;
    let dhikr = 0;
    let qSec = 0;
    let dSec = 0;
    const todayStr = new Date().toISOString().slice(0, 10);
    const dauToday = new Set<string>();
    for (const r of daily) {
      ayahs += r.ayahs_read ?? 0;
      dhikr += r.dhikr_count ?? 0;
      qSec += r.quran_time_sec ?? 0;
      dSec += r.dhikr_time_sec ?? 0;
      const isActive =
        (r.quran_time_sec ?? 0) > 0 ||
        (r.dhikr_time_sec ?? 0) > 0 ||
        (r.ayahs_read ?? 0) > 0 ||
        (r.dhikr_count ?? 0) > 0;
      if (isActive) {
        dau.add(r.user_id);
        if (r.stat_date === todayStr) dauToday.add(r.user_id);
      }
    }
    return { mau: dau.size, dauToday: dauToday.size, ayahs, dhikr, qSec, dSec };
  }, [daily]);

  // Daily aggregates across all users — used for time-series charts.
  const dailyAgg = useMemo(() => {
    const map = new Map<
      string,
      { ayahs: number; dhikr: number; qMin: number; dMin: number; activeUsers: Set<string> }
    >();
    for (const r of daily) {
      const cur = map.get(r.stat_date) ?? {
        ayahs: 0,
        dhikr: 0,
        qMin: 0,
        dMin: 0,
        activeUsers: new Set<string>(),
      };
      cur.ayahs += r.ayahs_read ?? 0;
      cur.dhikr += r.dhikr_count ?? 0;
      cur.qMin += Math.round((r.quran_time_sec ?? 0) / 60);
      cur.dMin += Math.round((r.dhikr_time_sec ?? 0) / 60);
      const isActive =
        (r.quran_time_sec ?? 0) > 0 ||
        (r.dhikr_time_sec ?? 0) > 0 ||
        (r.ayahs_read ?? 0) > 0 ||
        (r.dhikr_count ?? 0) > 0;
      if (isActive) cur.activeUsers.add(r.user_id);
      map.set(r.stat_date, cur);
    }
    // Pad missing days so the X-axis is continuous.
    const now = new Date();
    const out: {
      day: string;
      label: string;
      ayahs: number;
      dhikr: number;
      qMin: number;
      dMin: number;
      activeUsers: number;
    }[] = [];
    for (let i = 29; i >= 0; i--) {
      const d = new Date(now.getTime() - i * MS_PER_DAY);
      const key = d.toISOString().slice(0, 10);
      const v = map.get(key);
      out.push({
        day: key,
        label: shortDay(key),
        ayahs: v?.ayahs ?? 0,
        dhikr: v?.dhikr ?? 0,
        qMin: v?.qMin ?? 0,
        dMin: v?.dMin ?? 0,
        activeUsers: v?.activeUsers.size ?? 0,
      });
    }
    return out;
  }, [daily]);

  const streakBuckets = useMemo(() => {
    let active3 = 0;
    let active7 = 0;
    let active30 = 0;
    let bestEver = 0;
    for (const p of streakProfiles) {
      const best = Math.max(
        p.login_streak ?? 0,
        p.dhikr_streak ?? 0,
        p.quran_streak ?? 0,
      );
      if (best >= 3) active3++;
      if (best >= 7) active7++;
      if (best >= 30) active30++;
      if (best > bestEver) bestEver = best;
    }
    return { active3, active7, active30, bestEver };
  }, [streakProfiles]);

  const levelChartData = useMemo(() => {
    const buckets: Record<string, number> = {
      "L1-5": 0,
      "L6-10": 0,
      "L11-20": 0,
      "L21-35": 0,
      "L36+": 0,
    };
    for (const p of streakProfiles) {
      const lvl = p.level ?? 1;
      if (lvl <= 5) buckets["L1-5"]++;
      else if (lvl <= 10) buckets["L6-10"]++;
      else if (lvl <= 20) buckets["L11-20"]++;
      else if (lvl <= 35) buckets["L21-35"]++;
      else buckets["L36+"]++;
    }
    return Object.entries(buckets).map(([range, count]) => ({ range, count }));
  }, [streakProfiles]);

  const notifStats = useMemo(() => {
    const totalSent = notifications.length;
    const totalOpened = notifications.filter((n) => n.opened_at).length;
    const byType = new Map<string, { sent: number; opened: number }>();
    for (const n of notifications) {
      const key = n.notification_type ?? "(uncategorized)";
      const cur = byType.get(key) ?? { sent: 0, opened: 0 };
      cur.sent++;
      if (n.opened_at) cur.opened++;
      byType.set(key, cur);
    }
    const chartData = Array.from(byType.entries())
      .map(([type, v]) => ({
        type,
        sent: v.sent,
        opened: v.opened,
        rate: v.sent === 0 ? 0 : Math.round((v.opened / v.sent) * 1000) / 10,
      }))
      .sort((a, b) => b.sent - a.sent)
      .slice(0, 8);
    return {
      sent: totalSent,
      opened: totalOpened,
      rate: totalSent === 0 ? 0 : Math.round((totalOpened / totalSent) * 1000) / 10,
      chartData,
    };
  }, [notifications]);

  // ── Render ──────────────────────────────────────────────────────────────
  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-xl p-6 text-red-700">
        <p className="font-medium mb-2">Failed to load analytics</p>
        <pre className="text-xs whitespace-pre-wrap">{error}</pre>
      </div>
    );
  }

  const totalCoins = countries.reduce((s, c) => s + (c.total_coins ?? 0), 0);

  const countryChartData = countries.map((c) => ({
    country: c.country || "Unknown",
    label: `${countryFlag(c.country)} ${c.country || "Unknown"}`,
    users: c.active_users,
  }));

  const deviceChartData = devices.map((d) => ({
    name: d.device_type || "Unknown",
    value: d.user_count,
  }));

  const signupsChartData = signupsByDay.map((d) => ({
    label: shortDay(d.day),
    count: d.count,
  }));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <p className="text-sm text-slate-500">
          Aggregated analytics — no personal user data. 30-day rolling window.
        </p>
      </div>

      {/* ── Headline cards ───────────────────────────────────────────── */}
      <div className="grid grid-cols-2 lg:grid-cols-6 gap-3">
        <Stat label="Total users" value={totalProfiles.toLocaleString()} accent="slate" />
        <Stat label="Active (30d)" value={totals30.mau.toLocaleString()} accent="teal" />
        <Stat label="Active today" value={totals30.dauToday.toLocaleString()} accent="indigo" />
        <Stat label="New (24h)" value={newSignupsToday.toLocaleString()} accent="rose" />
        <Stat label="New (7d)" value={newSignups7d.toLocaleString()} accent="amber" />
        <Stat
          label="Push opt-in"
          value={`${pushOptIn.toLocaleString()}${
            totalProfiles > 0
              ? ` (${Math.round((pushOptIn / totalProfiles) * 100)}%)`
              : ""
          }`}
          accent="violet"
        />
      </div>

      {/* ── Worship activity (30-day area chart) ─────────────────────── */}
      <Card
        title="Worship time — last 30 days"
        subtitle="Minutes spent reading Quran and reciting dhikr, summed across all users."
      >
        <div className="h-72">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={dailyAgg} margin={{ top: 10, right: 12, left: -10, bottom: 0 }}>
              <defs>
                <linearGradient id="quranGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor={PALETTE.teal} stopOpacity={0.7} />
                  <stop offset="100%" stopColor={PALETTE.teal} stopOpacity={0.05} />
                </linearGradient>
                <linearGradient id="dhikrGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor={PALETTE.amber} stopOpacity={0.7} />
                  <stop offset="100%" stopColor={PALETTE.amber} stopOpacity={0.05} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" vertical={false} />
              <XAxis dataKey="label" stroke="#94a3b8" tick={{ fontSize: 11 }} interval={3} />
              <YAxis stroke="#94a3b8" tick={{ fontSize: 11 }} />
              <Tooltip
                contentStyle={{ background: "white", border: "1px solid #e2e8f0", borderRadius: 8, fontSize: 12 }}
                formatter={(value: number, name: string) => [`${value} min`, name]}
              />
              <Legend wrapperStyle={{ fontSize: 12 }} />
              <Area
                type="monotone"
                dataKey="qMin"
                name="Quran time"
                stroke={PALETTE.teal}
                strokeWidth={2}
                fill="url(#quranGrad)"
              />
              <Area
                type="monotone"
                dataKey="dMin"
                name="Dhikr time"
                stroke={PALETTE.amber}
                strokeWidth={2}
                fill="url(#dhikrGrad)"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3 mt-4">
          <MiniStat label="Ayahs read" value={totals30.ayahs.toLocaleString()} />
          <MiniStat label="Dhikr count" value={totals30.dhikr.toLocaleString()} />
          <MiniStat label="Quran time" value={fmtDuration(totals30.qSec)} />
          <MiniStat label="Dhikr time" value={fmtDuration(totals30.dSec)} />
          <MiniStat label="Coins gen." value={totalCoins.toLocaleString()} />
        </div>
      </Card>

      {/* ── Two-column row: Signups + DAU ────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card title="New signups — last 30 days">
          <div className="h-56">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={signupsChartData} margin={{ top: 10, right: 12, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" vertical={false} />
                <XAxis dataKey="label" stroke="#94a3b8" tick={{ fontSize: 11 }} interval={3} />
                <YAxis stroke="#94a3b8" tick={{ fontSize: 11 }} allowDecimals={false} />
                <Tooltip
                  contentStyle={{ background: "white", border: "1px solid #e2e8f0", borderRadius: 8, fontSize: 12 }}
                  formatter={(value: number) => [value, "Signups"]}
                />
                <Bar dataKey="count" fill={PALETTE.indigo} radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card title="Daily active users — last 30 days">
          <div className="h-56">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={dailyAgg} margin={{ top: 10, right: 12, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="dauGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor={PALETTE.violet} stopOpacity={0.6} />
                    <stop offset="100%" stopColor={PALETTE.violet} stopOpacity={0.05} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" vertical={false} />
                <XAxis dataKey="label" stroke="#94a3b8" tick={{ fontSize: 11 }} interval={3} />
                <YAxis stroke="#94a3b8" tick={{ fontSize: 11 }} allowDecimals={false} />
                <Tooltip
                  contentStyle={{ background: "white", border: "1px solid #e2e8f0", borderRadius: 8, fontSize: 12 }}
                  formatter={(value: number) => [value, "Active users"]}
                />
                <Area
                  type="monotone"
                  dataKey="activeUsers"
                  stroke={PALETTE.violet}
                  strokeWidth={2}
                  fill="url(#dauGrad)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>

      {/* ── Streaks + levels ──────────────────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card title="Active streaks (any type)">
          <div className="grid grid-cols-3 gap-3">
            <Stat label="3+ days" value={streakBuckets.active3.toLocaleString()} accent="teal" />
            <Stat label="7+ days" value={streakBuckets.active7.toLocaleString()} accent="amber" />
            <Stat label="30+ days" value={streakBuckets.active30.toLocaleString()} accent="rose" />
          </div>
          <p className="text-xs text-slate-500 mt-4">
            Longest current streak across all users:{" "}
            <span className="font-semibold text-slate-800">
              {streakBuckets.bestEver} day{streakBuckets.bestEver === 1 ? "" : "s"}
            </span>
          </p>
        </Card>

        <Card title="Users by level">
          <div className="h-56">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={levelChartData} margin={{ top: 10, right: 12, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" vertical={false} />
                <XAxis dataKey="range" stroke="#94a3b8" tick={{ fontSize: 11 }} />
                <YAxis stroke="#94a3b8" tick={{ fontSize: 11 }} allowDecimals={false} />
                <Tooltip
                  contentStyle={{ background: "white", border: "1px solid #e2e8f0", borderRadius: 8, fontSize: 12 }}
                  formatter={(value: number) => [value, "Users"]}
                />
                <Bar dataKey="count" fill={PALETTE.violet} radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>

      {/* ── Push notifications ────────────────────────────────────────── */}
      <Card
        title="Push notifications — last 30 days"
        subtitle="Only instrumented sends (post-instrumentation rows)."
      >
        {notifStats.sent === 0 ? (
          <p className="text-sm text-slate-400">
            No instrumented notifications sent yet.
          </p>
        ) : (
          <>
            <div className="grid grid-cols-3 gap-3 mb-5">
              <Stat label="Sent" value={notifStats.sent.toLocaleString()} accent="slate" />
              <Stat label="Opened" value={notifStats.opened.toLocaleString()} accent="teal" />
              <Stat label="Open rate" value={`${notifStats.rate}%`} accent="indigo" />
            </div>
            <div className="h-72">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  data={notifStats.chartData}
                  layout="vertical"
                  margin={{ top: 5, right: 24, left: 32, bottom: 5 }}
                >
                  <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" horizontal={false} />
                  <XAxis type="number" stroke="#94a3b8" tick={{ fontSize: 11 }} allowDecimals={false} />
                  <YAxis
                    type="category"
                    dataKey="type"
                    stroke="#94a3b8"
                    tick={{ fontSize: 11 }}
                    width={150}
                  />
                  <Tooltip
                    contentStyle={{ background: "white", border: "1px solid #e2e8f0", borderRadius: 8, fontSize: 12 }}
                  />
                  <Legend wrapperStyle={{ fontSize: 12 }} />
                  <Bar dataKey="sent" name="Sent" fill={PALETTE.slate} radius={[0, 4, 4, 0]} />
                  <Bar dataKey="opened" name="Opened" fill={PALETTE.teal} radius={[0, 4, 4, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </>
        )}
      </Card>

      {/* ── Country + Device ──────────────────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card title="Users by country (top 10)">
          {countryChartData.length === 0 ? (
            <p className="text-sm text-slate-400">No country data yet.</p>
          ) : (
            <div className="h-72">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  data={countryChartData}
                  layout="vertical"
                  margin={{ top: 5, right: 24, left: 12, bottom: 5 }}
                >
                  <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" horizontal={false} />
                  <XAxis type="number" stroke="#94a3b8" tick={{ fontSize: 11 }} allowDecimals={false} />
                  <YAxis
                    type="category"
                    dataKey="label"
                    stroke="#94a3b8"
                    tick={{ fontSize: 12 }}
                    width={110}
                  />
                  <Tooltip
                    contentStyle={{ background: "white", border: "1px solid #e2e8f0", borderRadius: 8, fontSize: 12 }}
                    formatter={(value: number) => [value, "Active users"]}
                  />
                  <Bar dataKey="users" fill={PALETTE.teal} radius={[0, 4, 4, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </Card>

        <Card title="Users by device">
          {deviceChartData.length === 0 ? (
            <p className="text-sm text-slate-400">
              No device data available yet.
            </p>
          ) : (
            <div className="h-72">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={deviceChartData}
                    dataKey="value"
                    nameKey="name"
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={100}
                    paddingAngle={2}
                    label={({ name, percent }) =>
                      `${name} ${((percent ?? 0) * 100).toFixed(0)}%`
                    }
                  >
                    {deviceChartData.map((_, i) => (
                      <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip
                    contentStyle={{ background: "white", border: "1px solid #e2e8f0", borderRadius: 8, fontSize: 12 }}
                    formatter={(value: number) => [value, "Users"]}
                  />
                  <Legend
                    wrapperStyle={{ fontSize: 12 }}
                    verticalAlign="bottom"
                    height={24}
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>
          )}
        </Card>
      </div>

      {/* ── Top dhikr phrases ─────────────────────────────────────────── */}
      <Card title="Most-recited dhikr phrases (all-time top 10)">
        {topPhrases.length === 0 ? (
          <p className="text-sm text-slate-400">
            No phrase-level counts recorded yet.
          </p>
        ) : (
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart
                data={topPhrases.map((p) => ({ phrase: p.phrase_id, count: p.count }))}
                layout="vertical"
                margin={{ top: 5, right: 24, left: 12, bottom: 5 }}
              >
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" horizontal={false} />
                <XAxis type="number" stroke="#94a3b8" tick={{ fontSize: 11 }} allowDecimals={false} />
                <YAxis
                  type="category"
                  dataKey="phrase"
                  stroke="#94a3b8"
                  tick={{ fontSize: 11 }}
                  width={200}
                />
                <Tooltip
                  contentStyle={{ background: "white", border: "1px solid #e2e8f0", borderRadius: 8, fontSize: 12 }}
                  formatter={(value: number) => [value.toLocaleString(), "Count"]}
                />
                <Bar dataKey="count" fill={PALETTE.rose} radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        )}
      </Card>
    </div>
  );
}

// ─── UI primitives ──────────────────────────────────────────────────────────
const DOT: Record<string, string> = {
  slate: "bg-slate-400",
  teal: "bg-teal-400",
  amber: "bg-amber-400",
  indigo: "bg-indigo-400",
  violet: "bg-violet-400",
  rose: "bg-rose-400",
};

function Stat({
  label,
  value,
  accent = "slate",
}: {
  label: string;
  value: string;
  accent?: keyof typeof DOT;
}) {
  return (
    <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
      <div className="flex items-center gap-2">
        <span className={`w-2 h-2 rounded-full ${DOT[accent]}`} />
        <p className="text-[11px] font-medium text-slate-500 uppercase tracking-wide">
          {label}
        </p>
      </div>
      <p className="text-2xl font-semibold text-slate-800 mt-2 tabular-nums">
        {value}
      </p>
    </div>
  );
}

function MiniStat({ label, value }: { label: string; value: string }) {
  return (
    <div className="bg-slate-50 rounded-lg p-3 text-center">
      <p className="text-xs text-slate-500 font-medium">{label}</p>
      <p className="text-lg font-semibold text-slate-800 mt-1 tabular-nums">
        {value}
      </p>
    </div>
  );
}

function Card({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
      <div className="mb-4">
        <h3 className="text-base font-semibold text-slate-800">{title}</h3>
        {subtitle && (
          <p className="text-xs text-slate-500 mt-0.5">{subtitle}</p>
        )}
      </div>
      {children}
    </div>
  );
}
