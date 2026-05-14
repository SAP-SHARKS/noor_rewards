"use client";

import { useEffect, useMemo, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

// ─── Types ───────────────────────────────────────────────────────────────────
type Profile = {
  id: string;
  display_name: string | null;
  email?: string | null;
  level: number;
  total_xp: number;
  noor_points: number;
  login_streak: number | null;
  dhikr_streak: number | null;
  quran_streak: number | null;
  best_login_streak: number | null;
  best_dhikr_streak: number | null;
  best_quran_streak: number | null;
  country: string | null;
  created_at: string;
};

type Analytics = {
  user_id: string;
  country_code: string | null;
  device_model: string | null;
  device_type: string | null;
  session_duration_sec: number | null;
  quran_time_sec: number | null;
  dhikr_time_sec: number | null;
  noor_coins_earned: number | null;
  last_active_at: string | null;
};

type MonthlyStat = {
  month: string;
  ayahs_read: number;
  quran_sessions: number;
  quran_time_sec: number;
  dhikr_sets: number;
  dhikr_count: number;
  dhikr_time_sec: number;
  total_points: number;
  active_days: number;
  login_days: number;
};

type DailyStat = {
  stat_date: string;
  quran_time_sec: number;
  dhikr_time_sec: number;
  ayahs_read: number;
  dhikr_count: number;
};

type PhraseCount = { phrase_id: string; count: number };

type FcmToken = {
  user_id: string;
  token: string | null;
  timezone: string | null;
  latitude: number | null;
  longitude: number | null;
  device_type: string | null;
  last_seen: string | null;
};

type Bookmark = { surah: number | null; ayah: number | null; label?: string | null };
type Progress = { last_surah: number | null; last_ayah: number | null; updated_at?: string };
type Activity = {
  id?: string;
  activity_type?: string | null;
  metadata?: Record<string, unknown> | null;
  created_at?: string | null;
};
type Badge = { badge_id?: string; awarded_at?: string };

// ─── Helpers ─────────────────────────────────────────────────────────────────
function fmtNum(n: number | null | undefined) {
  if (n == null) return "—";
  return n.toLocaleString();
}
function fmtDuration(sec: number | null | undefined) {
  if (!sec || sec <= 0) return "0m";
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  const s = sec % 60;
  if (h > 0) return `${h}h ${m}m`;
  if (m > 0) return `${m}m ${s}s`;
  return `${s}s`;
}
function fmtDate(s: string | null | undefined) {
  if (!s) return "—";
  try {
    return new Date(s).toLocaleString();
  } catch {
    return s;
  }
}
function countryFlag(iso: string | null | undefined) {
  if (!iso || iso.length !== 2) return "";
  const codePoints = [...iso.toUpperCase()].map(
    (c) => 0x1f1e6 - 65 + c.charCodeAt(0),
  );
  return String.fromCodePoint(...codePoints);
}

// ─── Page ────────────────────────────────────────────────────────────────────
export default function UserDetailPage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const uid = params.id;

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [analytics, setAnalytics] = useState<Analytics | null>(null);
  const [monthly, setMonthly] = useState<MonthlyStat[]>([]);
  const [daily, setDaily] = useState<DailyStat[]>([]);
  const [phrases, setPhrases] = useState<PhraseCount[]>([]);
  const [fcm, setFcm] = useState<FcmToken | null>(null);
  const [progress, setProgress] = useState<Progress | null>(null);
  const [bookmarks, setBookmarks] = useState<Bookmark[]>([]);
  const [activities, setActivities] = useState<Activity[]>([]);
  const [badges, setBadges] = useState<Badge[]>([]);

  async function loadAll() {
    setLoading(true);
    setError(null);
    try {
      const today = new Date();
      const thirtyAgo = new Date(today);
      thirtyAgo.setDate(thirtyAgo.getDate() - 29);
      const startDate = thirtyAgo.toISOString().slice(0, 10);

      const [
        profileRes,
        analyticsRes,
        monthlyRes,
        dailyRes,
        phrasesRes,
        fcmRes,
        progressRes,
        bookmarksRes,
        activitiesRes,
        badgesRes,
      ] = await Promise.all([
        supabase.from("profiles").select("*").eq("id", uid).maybeSingle(),
        supabase
          .from("user_analytics")
          .select("*")
          .eq("user_id", uid)
          .maybeSingle(),
        supabase
          .from("user_monthly_stats")
          .select("*")
          .eq("user_id", uid)
          .order("month", { ascending: false })
          .limit(6),
        supabase
          .from("user_daily_stats")
          .select("*")
          .eq("user_id", uid)
          .gte("stat_date", startDate)
          .order("stat_date", { ascending: true }),
        supabase
          .from("user_dhikr_phrase_counts")
          .select("*")
          .eq("user_id", uid)
          .order("count", { ascending: false }),
        supabase
          .from("fcm_tokens")
          .select("*")
          .eq("user_id", uid)
          .maybeSingle(),
        supabase
          .from("user_progress")
          .select("*")
          .eq("user_id", uid)
          .maybeSingle(),
        supabase
          .from("quran_bookmarks")
          .select("*")
          .eq("user_id", uid)
          .limit(50),
        supabase
          .from("user_activities")
          .select("*")
          .eq("user_id", uid)
          .order("created_at", { ascending: false })
          .limit(25),
        supabase.from("badges").select("*").eq("user_id", uid),
      ]);

      setProfile((profileRes.data as Profile) ?? null);
      setAnalytics((analyticsRes.data as Analytics) ?? null);
      setMonthly((monthlyRes.data as MonthlyStat[]) ?? []);
      setDaily((dailyRes.data as DailyStat[]) ?? []);
      setPhrases((phrasesRes.data as PhraseCount[]) ?? []);
      setFcm((fcmRes.data as FcmToken) ?? null);
      setProgress((progressRes.data as Progress) ?? null);
      setBookmarks((bookmarksRes.data as Bookmark[]) ?? []);
      setActivities((activitiesRes.data as Activity[]) ?? []);
      setBadges((badgesRes.data as Badge[]) ?? []);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (uid) loadAll();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [uid]);

  // Aggregate the last 30 days for headline cards.
  const totals = useMemo(() => {
    let qSec = 0;
    let dSec = 0;
    let ayahs = 0;
    let dhikr = 0;
    let activeDays = 0;
    for (const d of daily) {
      qSec += d.quran_time_sec ?? 0;
      dSec += d.dhikr_time_sec ?? 0;
      ayahs += d.ayahs_read ?? 0;
      dhikr += d.dhikr_count ?? 0;
      if (
        (d.quran_time_sec ?? 0) > 0 ||
        (d.dhikr_time_sec ?? 0) > 0 ||
        (d.ayahs_read ?? 0) > 0 ||
        (d.dhikr_count ?? 0) > 0
      ) {
        activeDays += 1;
      }
    }
    return { qSec, dSec, ayahs, dhikr, activeDays };
  }, [daily]);

  // Bar-chart-style daily times (last 14 days for visibility).
  const last14 = useMemo(() => daily.slice(-14), [daily]);
  const maxSec = useMemo(
    () =>
      last14.reduce(
        (m, d) => Math.max(m, (d.quran_time_sec ?? 0) + (d.dhikr_time_sec ?? 0)),
        0,
      ),
    [last14],
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-xl p-6 text-red-700 dark:text-red-300">
        <p className="font-medium mb-2">Failed to load user data</p>
        <pre className="text-xs whitespace-pre-wrap">{error}</pre>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-6">
        <p className="text-slate-600 dark:text-slate-300 mb-4">
          No profile found for user{" "}
          <code className="bg-slate-100 dark:bg-slate-700 px-1 rounded">
            {uid}
          </code>
          .
        </p>
        <Link
          href="/dashboard/users"
          className="text-teal-600 hover:text-teal-800 text-sm"
        >
          ← Back to users
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start gap-4">
        <button
          onClick={() => router.back()}
          className="text-slate-400 hover:text-slate-700 dark:hover:text-white mt-1 cursor-pointer"
          title="Back"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M15 19l-7-7 7-7"
            />
          </svg>
        </button>
        <div className="flex-1 min-w-0">
          <h2 className="text-3xl font-bold text-slate-800 dark:text-slate-100 tracking-tight">
            {profile.display_name || "Anonymous"}{" "}
            <span className="ml-1">
              {countryFlag(analytics?.country_code ?? profile.country)}
            </span>
          </h2>
          <p className="text-xs text-slate-500 dark:text-slate-400 font-mono mt-1 break-all">
            {profile.id}
          </p>
          <p className="text-sm text-slate-600 dark:text-slate-300 mt-1.5">
            Joined {fmtDate(profile.created_at)}
            {analytics?.last_active_at && (
              <>
                {" "}
                · last active {fmtDate(analytics.last_active_at)}
              </>
            )}
          </p>
        </div>
        <button
          onClick={loadAll}
          className="px-4 py-2 text-sm font-medium rounded-lg bg-teal-600 hover:bg-teal-700 text-white shadow-sm cursor-pointer flex items-center gap-2 transition"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
            />
          </svg>
          Refresh
        </button>
      </div>

      {/* Top stats — at-a-glance */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Stat label="Sabiq Seeds" value={fmtNum(profile.noor_points)} accent="amber" />
        <Stat label="Level" value={profile.level.toString()} accent="violet" />
        <Stat label="Total XP" value={fmtNum(profile.total_xp)} accent="indigo" />
        <Stat
          label="Best Streak"
          value={`${Math.max(
            profile.best_login_streak ?? 0,
            profile.best_dhikr_streak ?? 0,
            profile.best_quran_streak ?? 0,
          )}d`}
          accent="rose"
        />
      </div>

      {/* Streaks */}
      <Card title="Streaks">
        <div className="grid grid-cols-3 gap-4">
          <StreakBlock
            label="Login"
            current={profile.login_streak ?? 0}
            best={profile.best_login_streak ?? 0}
          />
          <StreakBlock
            label="Dhikr"
            current={profile.dhikr_streak ?? 0}
            best={profile.best_dhikr_streak ?? 0}
          />
          <StreakBlock
            label="Quran"
            current={profile.quran_streak ?? 0}
            best={profile.best_quran_streak ?? 0}
          />
        </div>
      </Card>

      {/* Last 30 days summary */}
      <Card title="Last 30 days">
        <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
          <MiniStat label="Active days" value={`${totals.activeDays} / 30`} />
          <MiniStat label="Quran time" value={fmtDuration(totals.qSec)} />
          <MiniStat label="Dhikr time" value={fmtDuration(totals.dSec)} />
          <MiniStat label="Ayahs read" value={fmtNum(totals.ayahs)} />
          <MiniStat label="Dhikr count" value={fmtNum(totals.dhikr)} />
        </div>
      </Card>

      {/* Daily activity bar chart (last 14 days) */}
      <Card title="Worship activity — last 14 days">
        {last14.length === 0 ? (
          <p className="text-sm text-slate-500 dark:text-slate-400">
            No daily activity recorded yet.
          </p>
        ) : (
          <div className="flex items-end justify-between gap-1 h-32">
            {last14.map((d) => {
              const total =
                (d.quran_time_sec ?? 0) + (d.dhikr_time_sec ?? 0);
              const ratio = maxSec === 0 ? 0 : total / maxSec;
              const h = total === 0 ? 4 : Math.max(12, ratio * 116);
              const day = new Date(d.stat_date);
              return (
                <div
                  key={d.stat_date}
                  className="flex-1 flex flex-col items-center justify-end gap-1"
                  title={`${d.stat_date}: ${fmtDuration(total)} (Quran ${fmtDuration(
                    d.quran_time_sec ?? 0,
                  )}, Dhikr ${fmtDuration(d.dhikr_time_sec ?? 0)})`}
                >
                  <div className="w-full flex flex-col rounded-md overflow-hidden">
                    <div
                      style={{
                        height:
                          total === 0
                            ? 0
                            : ((d.quran_time_sec ?? 0) / total) * h,
                      }}
                      className="bg-teal-500"
                    />
                    <div
                      style={{
                        height:
                          total === 0
                            ? h
                            : ((d.dhikr_time_sec ?? 0) / total) * h,
                      }}
                      className={total === 0 ? "bg-slate-200 dark:bg-slate-700" : "bg-amber-500"}
                    />
                  </div>
                  <span className="text-[11px] text-slate-500 dark:text-slate-400">
                    {day.toLocaleDateString(undefined, { day: "numeric" })}
                  </span>
                </div>
              );
            })}
          </div>
        )}
        <div className="flex items-center gap-4 mt-3 text-xs text-slate-500 dark:text-slate-400">
          <Legend color="bg-teal-500" label="Quran time" />
          <Legend color="bg-amber-500" label="Dhikr time" />
        </div>
      </Card>

      {/* Daily table */}
      <Card title="Daily breakdown (last 30 days)">
        {daily.length === 0 ? (
          <p className="text-sm text-slate-500 dark:text-slate-400">
            No daily rows yet.
          </p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-xs">
              <thead>
                <tr className="bg-slate-50 dark:bg-slate-900/40 text-slate-600 dark:text-slate-300 text-left text-xs font-semibold border-b border-slate-200 dark:border-slate-700">
                  <th className="px-3 py-2 font-semibold uppercase tracking-wider">Date</th>
                  <th className="px-3 py-2 font-semibold uppercase tracking-wider text-right">Quran time</th>
                  <th className="px-3 py-2 font-semibold uppercase tracking-wider text-right">Dhikr time</th>
                  <th className="px-3 py-2 font-semibold uppercase tracking-wider text-right">Ayahs</th>
                  <th className="px-3 py-2 font-semibold uppercase tracking-wider text-right">Dhikr count</th>
                </tr>
              </thead>
              <tbody>
                {[...daily].reverse().map((d) => (
                  <tr
                    key={d.stat_date}
                    className="border-t border-slate-100 dark:border-slate-700"
                  >
                    <td className="px-3 py-2 text-slate-600 dark:text-slate-300">
                      {d.stat_date}
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums text-slate-800 dark:text-white font-medium">
                      {fmtDuration(d.quran_time_sec)}
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums text-slate-800 dark:text-white font-medium">
                      {fmtDuration(d.dhikr_time_sec)}
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums text-slate-800 dark:text-white font-medium">
                      {fmtNum(d.ayahs_read)}
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums text-slate-800 dark:text-white font-medium">
                      {fmtNum(d.dhikr_count)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Monthly stats */}
      <Card title="Monthly rollups (latest 6)">
        {monthly.length === 0 ? (
          <p className="text-sm text-slate-500 dark:text-slate-400">
            No monthly rollups yet.
          </p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-xs">
              <thead>
                <tr className="bg-slate-50 dark:bg-slate-900/40 text-slate-600 dark:text-slate-300 text-left text-xs font-semibold border-b border-slate-200 dark:border-slate-700">
                  <th className="px-3 py-2 font-semibold uppercase tracking-wider">Month</th>
                  <th className="px-3 py-2 font-semibold uppercase tracking-wider text-right">Points</th>
                  <th className="px-3 py-2 font-semibold uppercase tracking-wider text-right">Active days</th>
                  <th className="px-3 py-2 font-semibold uppercase tracking-wider text-right">Login days</th>
                  <th className="px-3 py-2 font-semibold uppercase tracking-wider text-right">Ayahs</th>
                  <th className="px-3 py-2 font-semibold uppercase tracking-wider text-right">Quran time</th>
                  <th className="px-3 py-2 font-semibold uppercase tracking-wider text-right">Dhikr count</th>
                  <th className="px-3 py-2 font-semibold uppercase tracking-wider text-right">Dhikr time</th>
                </tr>
              </thead>
              <tbody>
                {monthly.map((m) => (
                  <tr
                    key={m.month}
                    className="border-t border-slate-100 dark:border-slate-700"
                  >
                    <td className="px-3 py-2 text-slate-600 dark:text-slate-300">
                      {m.month}
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums text-slate-800 dark:text-white font-medium">
                      {fmtNum(m.total_points)}
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums text-slate-800 dark:text-white font-medium">
                      {fmtNum(m.active_days)}
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums text-slate-800 dark:text-white font-medium">
                      {fmtNum(m.login_days)}
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums text-slate-800 dark:text-white font-medium">
                      {fmtNum(m.ayahs_read)}
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums text-slate-800 dark:text-white font-medium">
                      {fmtDuration(m.quran_time_sec)}
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums text-slate-800 dark:text-white font-medium">
                      {fmtNum(m.dhikr_count)}
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums text-slate-800 dark:text-white font-medium">
                      {fmtDuration(m.dhikr_time_sec)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Dhikr phrase counts */}
      <Card title={`Dhikr phrases (${phrases.length})`}>
        {phrases.length === 0 ? (
          <p className="text-sm text-slate-500 dark:text-slate-400">
            No phrase-level counts recorded.
          </p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-1">
            {phrases.map((p) => (
              <div
                key={p.phrase_id}
                className="flex justify-between text-sm py-1.5 border-b border-slate-100 dark:border-slate-700 last:border-0"
              >
                <span className="text-slate-700 dark:text-slate-200 font-mono text-xs truncate mr-2">
                  {p.phrase_id}
                </span>
                <span className="text-slate-800 dark:text-white font-semibold tabular-nums">
                  {fmtNum(p.count)}
                </span>
              </div>
            ))}
          </div>
        )}
      </Card>

      {/* Device / notifications / privacy-relevant info */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card title="Account & device">
          <KV label="Email" value={profile.email || "—"} />
          <KV label="Country" value={analytics?.country_code ?? profile.country ?? "—"} />
          <KV label="Device" value={analytics?.device_model ?? "—"} />
          <KV label="Platform" value={analytics?.device_type ?? "—"} />
          <KV
            label="Lifetime session"
            value={fmtDuration(analytics?.session_duration_sec)}
          />
          <KV
            label="All-time Quran time"
            value={fmtDuration(analytics?.quran_time_sec)}
          />
          <KV
            label="All-time Dhikr time"
            value={fmtDuration(analytics?.dhikr_time_sec)}
          />
          <KV label="Coins earned" value={fmtNum(analytics?.noor_coins_earned)} />
        </Card>
        <Card title="Push notifications (FCM)">
          {!fcm ? (
            <p className="text-sm text-slate-500 dark:text-slate-400">
              No FCM token registered.
            </p>
          ) : (
            <>
              <KV label="Timezone" value={fcm.timezone || "—"} />
              <KV label="Device type" value={fcm.device_type || "—"} />
              <KV label="Last seen" value={fmtDate(fcm.last_seen)} />
              <KV
                label="Location"
                value={
                  fcm.latitude != null && fcm.longitude != null
                    ? `${fcm.latitude.toFixed(3)}, ${fcm.longitude.toFixed(3)}`
                    : "Not granted"
                }
              />
              <KV
                label="Token"
                value={
                  <code className="text-[10px] font-mono break-all text-slate-500 dark:text-slate-400">
                    {fcm.token
                      ? `${fcm.token.substring(0, 18)}…${fcm.token.substring(
                          fcm.token.length - 10,
                        )}`
                      : "—"}
                  </code>
                }
              />
            </>
          )}
        </Card>
      </div>

      {/* Quran progress + bookmarks */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card title="Quran reading position">
          {!progress ? (
            <p className="text-sm text-slate-500 dark:text-slate-400">
              No reading position saved yet.
            </p>
          ) : (
            <>
              <KV label="Last surah" value={fmtNum(progress.last_surah)} />
              <KV label="Last ayah" value={fmtNum(progress.last_ayah)} />
              <KV label="Updated" value={fmtDate(progress.updated_at)} />
            </>
          )}
        </Card>
        <Card title={`Bookmarks (${bookmarks.length})`}>
          {bookmarks.length === 0 ? (
            <p className="text-sm text-slate-500 dark:text-slate-400">
              No bookmarks yet.
            </p>
          ) : (
            <ul className="text-sm text-slate-700 dark:text-slate-200 space-y-1">
              {bookmarks.slice(0, 10).map((b, i) => (
                <li
                  key={i}
                  className="border-b border-slate-100 dark:border-slate-700 last:border-0 pb-1.5 text-slate-800 dark:text-white font-medium"
                >
                  Surah {b.surah ?? "—"}:{b.ayah ?? "—"}{" "}
                  {b.label && (
                    <span className="text-xs text-slate-500 dark:text-slate-400 ml-1 font-normal">
                      ({b.label})
                    </span>
                  )}
                </li>
              ))}
              {bookmarks.length > 10 && (
                <li className="text-xs text-slate-500 dark:text-slate-400 pt-1">
                  …and {bookmarks.length - 10} more
                </li>
              )}
            </ul>
          )}
        </Card>
      </div>

      {/* Activities + badges */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card title={`Recent activity (${activities.length})`}>
          {activities.length === 0 ? (
            <p className="text-sm text-slate-500 dark:text-slate-400">
              No activity logged.
            </p>
          ) : (
            <ul className="text-sm space-y-1.5 max-h-72 overflow-y-auto">
              {activities.map((a, i) => (
                <li
                  key={a.id ?? i}
                  className="border-b border-slate-100 dark:border-slate-700 last:border-0 pb-1.5"
                >
                  <div className="flex justify-between gap-2">
                    <span className="text-slate-800 dark:text-white font-medium">
                      {a.activity_type ?? "activity"}
                    </span>
                    <span className="text-xs text-slate-500 dark:text-slate-400">
                      {fmtDate(a.created_at)}
                    </span>
                  </div>
                  {a.metadata && Object.keys(a.metadata).length > 0 && (
                    <pre className="text-[10px] text-slate-500 dark:text-slate-400 mt-0.5 truncate font-mono">
                      {JSON.stringify(a.metadata)}
                    </pre>
                  )}
                </li>
              ))}
            </ul>
          )}
        </Card>
        <Card title={`Badges (${badges.length})`}>
          {badges.length === 0 ? (
            <p className="text-sm text-slate-500 dark:text-slate-400">
              No badges earned yet.
            </p>
          ) : (
            <div className="flex flex-wrap gap-1.5">
              {badges.map((b, i) => (
                <span
                  key={b.badge_id ?? i}
                  className="px-2 py-1 text-xs rounded-md bg-amber-50 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300 border border-amber-200 dark:border-amber-800"
                  title={b.awarded_at}
                >
                  {b.badge_id}
                </span>
              ))}
            </div>
          )}
        </Card>
      </div>
    </div>
  );
}

// ─── Components ──────────────────────────────────────────────────────────────
// Color principle: pure white card surfaces (matches the rest of the admin),
// slate-800 for primary text/numbers (the proven readable weight used on the
// /dashboard/users list page), slate-500/600 for labels, plus a small colored
// dot per stat card so each metric is recognizable at a glance.
function Card({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-5">
      <h3 className="text-sm font-semibold text-slate-700 dark:text-slate-200 mb-4">
        {title}
      </h3>
      {children}
    </div>
  );
}

const STAT_DOT: Record<string, string> = {
  amber: "bg-amber-400",
  violet: "bg-violet-400",
  indigo: "bg-indigo-400",
  rose: "bg-rose-400",
};

function Stat({
  label,
  value,
  accent = "amber",
}: {
  label: string;
  value: string;
  accent?: "amber" | "violet" | "indigo" | "rose";
}) {
  return (
    <div className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-4">
      <div className="flex items-center gap-2">
        <span className={`w-2 h-2 rounded-full ${STAT_DOT[accent]}`} />
        <p className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wide">
          {label}
        </p>
      </div>
      <p className="text-2xl font-semibold text-slate-800 dark:text-white mt-2 tabular-nums">
        {value}
      </p>
    </div>
  );
}

function MiniStat({ label, value }: { label: string; value: string }) {
  return (
    <div className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg p-3.5">
      <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">
        {label}
      </p>
      <p className="text-lg font-semibold text-slate-800 dark:text-white mt-1 tabular-nums">
        {value}
      </p>
    </div>
  );
}

function StreakBlock({
  label,
  current,
  best,
}: {
  label: string;
  current: number;
  best: number;
}) {
  return (
    <div className="text-center bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg p-4">
      <p className="text-xs text-slate-500 dark:text-slate-400 font-medium mb-1">
        {label}
      </p>
      <p className="text-2xl font-semibold text-slate-800 dark:text-white tabular-nums">
        {current}
        <span className="text-sm font-normal text-slate-500 dark:text-slate-400">
          {" "}days
        </span>
      </p>
      <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
        best <span className="text-slate-700 dark:text-slate-200 font-medium">{best}d</span>
      </p>
    </div>
  );
}

function KV({
  label,
  value,
}: {
  label: string;
  value: React.ReactNode;
}) {
  return (
    <div className="flex justify-between items-center text-sm py-1.5 border-b border-slate-100 dark:border-slate-700 last:border-0">
      <span className="text-slate-500 dark:text-slate-400">{label}</span>
      <span className="text-slate-800 dark:text-white font-medium text-right truncate ml-3 max-w-[60%]">
        {value}
      </span>
    </div>
  );
}

function Legend({ color, label }: { color: string; label: string }) {
  return (
    <div className="flex items-center gap-1.5">
      <span className={`w-3 h-3 rounded-sm ${color}`} />
      <span className="text-slate-600 dark:text-slate-300">{label}</span>
    </div>
  );
}
