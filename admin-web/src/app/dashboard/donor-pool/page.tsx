"use client";

// Donor Pool simulator — interactive economy planner.
//
// Lets the admin tune the four numbers that drive the monthly Seeds→USD
// distribution and see the resulting per-Seed value + per-user impact
// update live. Includes a growth-scenarios table so the admin can plan
// what sponsor commitment is needed at each user-count milestone.
//
// All four tunable values persist to the shared `app_config` table:
//   donor_pool_usd_monthly
//   min_seed_value_usd
//   max_seed_value_usd
//   max_donatable_seeds_per_month
//
// The "active users" / "avg Seeds per user" inputs are simulation-only
// (local React state, never saved) — they're what-if assumptions, not
// platform settings.

import { useEffect, useState } from "react";
import { useConfig } from "@/lib/config-context";

// ── Saved settings (persist to app_config) ──────────────────────────────────
type SavableKey =
  | "donor_pool_usd_monthly"
  | "min_seed_value_usd"
  | "max_seed_value_usd"
  | "max_donatable_seeds_per_month";

const SAVABLE: Record<
  SavableKey,
  { label: string; desc: string; placeholder: string; suffix?: string }
> = {
  donor_pool_usd_monthly: {
    label: "Monthly donor pool",
    desc: "Total $ sponsors commit each month. Gets distributed to charity projects proportional to the Seeds users send their way.",
    placeholder: "300",
    suffix: "USD",
  },
  min_seed_value_usd: {
    label: "Floor (min per-Seed value)",
    desc: "If raw pool/Seeds falls below this, this floor is used and the platform tops up the gap from reserve.",
    placeholder: "0.0005",
    suffix: "USD",
  },
  max_seed_value_usd: {
    label: "Ceiling (max per-Seed value)",
    desc: "If raw pool/Seeds exceeds this, this ceiling is used and the excess rolls into a reserve fund for future months.",
    placeholder: "0.005",
    suffix: "USD",
  },
  max_donatable_seeds_per_month: {
    label: "Max donatable Seeds / user / month",
    desc: "Seeds above this cap still count for level/badges/leaderboard but do not tap the donor pool. Keeps power-users from dominating.",
    placeholder: "5000",
    suffix: "Seeds",
  },
};

// ── Growth scenarios (read-only stage table) ────────────────────────────────
const SCENARIOS: { stage: string; users: number }[] = [
  { stage: "Beta", users: 100 },
  { stage: "Early", users: 1_000 },
  { stage: "Growth", users: 10_000 },
  { stage: "Scale", users: 50_000 },
  { stage: "Mature", users: 200_000 },
];

// ── Helpers ─────────────────────────────────────────────────────────────────
const fmtNum = (n: number) =>
  Number.isFinite(n) ? n.toLocaleString(undefined, { maximumFractionDigits: 0 }) : "—";

const fmtUSD = (n: number, digits = 2) =>
  Number.isFinite(n)
    ? `$${n.toLocaleString(undefined, {
        minimumFractionDigits: digits,
        maximumFractionDigits: digits,
      })}`
    : "—";

const fmtUSDPrecise = (n: number) => {
  if (!Number.isFinite(n)) return "—";
  if (n >= 1) return fmtUSD(n);
  if (n >= 0.01) return `$${n.toFixed(4)}`;
  if (n >= 0.0001) return `$${n.toFixed(6)}`;
  return `$${n.toFixed(8)}`;
};

type ComputeResult = {
  effectiveSeedsPerUser: number;
  totalSeeds: number;
  rawSeedValue: number;
  clampedSeedValue: number;
  avgUserImpact: number;
  poolDistributed: number;
  surplus: number; // positive = pool not fully used (rolls to reserve); negative = shortfall
  clampedByFloor: boolean;
  clampedByCeiling: boolean;
};

function compute(
  pool: number,
  minVal: number,
  maxVal: number,
  cap: number,
  activeUsers: number,
  avgSeeds: number
): ComputeResult {
  const effective = Math.min(avgSeeds, cap > 0 ? cap : Number.POSITIVE_INFINITY);
  const total = activeUsers * effective;
  const raw = total > 0 ? pool / total : 0;
  const clamped =
    raw < minVal
      ? minVal
      : maxVal > 0 && raw > maxVal
        ? maxVal
        : raw;
  return {
    effectiveSeedsPerUser: effective,
    totalSeeds: total,
    rawSeedValue: raw,
    clampedSeedValue: clamped,
    avgUserImpact: effective * clamped,
    poolDistributed: total * clamped,
    surplus: pool - total * clamped,
    clampedByFloor: raw > 0 && raw < minVal,
    clampedByCeiling: maxVal > 0 && raw > maxVal,
  };
}

export default function DonorPoolPage() {
  const { config, loading, saveBatch } = useConfig();

  const [draft, setDraft] = useState<Record<SavableKey, string>>({
    donor_pool_usd_monthly: "",
    min_seed_value_usd: "",
    max_seed_value_usd: "",
    max_donatable_seeds_per_month: "",
  });
  const [sim, setSim] = useState({ activeUsers: "1000", avgSeeds: "3000" });
  const [saving, setSaving] = useState(false);
  const [initialized, setInitialized] = useState(false);

  // Seed `draft` from saved config the first time it loads, falling back to
  // the placeholder default when a key has never been set.
  useEffect(() => {
    if (initialized || loading) return;
    const next: Record<SavableKey, string> = {
      donor_pool_usd_monthly:
        config.donor_pool_usd_monthly ?? SAVABLE.donor_pool_usd_monthly.placeholder,
      min_seed_value_usd:
        config.min_seed_value_usd ?? SAVABLE.min_seed_value_usd.placeholder,
      max_seed_value_usd:
        config.max_seed_value_usd ?? SAVABLE.max_seed_value_usd.placeholder,
      max_donatable_seeds_per_month:
        config.max_donatable_seeds_per_month ??
        SAVABLE.max_donatable_seeds_per_month.placeholder,
    };
    setDraft(next);
    setInitialized(true);
  }, [config, loading, initialized]);

  if (loading || !initialized) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  // ── Numeric reads (every render — cheap) ─────────────────────────────────
  const pool = Number(draft.donor_pool_usd_monthly) || 0;
  const minVal = Number(draft.min_seed_value_usd) || 0;
  const maxVal = Number(draft.max_seed_value_usd) || 0;
  const cap = Number(draft.max_donatable_seeds_per_month) || 0;
  const simUsers = Number(sim.activeUsers) || 0;
  const simSeeds = Number(sim.avgSeeds) || 0;

  const live = compute(pool, minVal, maxVal, cap, simUsers, simSeeds);

  // Has anything been changed vs. the saved config?
  const hasChanges = (Object.keys(SAVABLE) as SavableKey[]).some(
    (k) => draft[k] !== (config[k] ?? "")
  );

  async function handleSave() {
    setSaving(true);
    try {
      await saveBatch(draft);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="max-w-5xl space-y-6 pb-24">
      <p className="text-sm text-slate-500">
        Plan the Sabiq Seed economy. Tune the four settings under{" "}
        <span className="font-medium text-slate-700">Donor pool settings</span>{" "}
        and the simulator + scenarios table below show what each combination
        looks like at different user-count milestones. <strong>Save</strong>{" "}
        commits the settings to the database; the simulator inputs (active
        users / avg Seeds) are local "what-if" knobs and aren&apos;t saved.
      </p>

      {/* ── Donor pool settings (savable) ─────────────────────────────── */}
      <section className="bg-white rounded-xl border border-slate-200 p-5">
        <h2 className="text-base font-semibold text-slate-800 mb-1">
          Donor pool settings
        </h2>
        <p className="text-xs text-slate-400 mb-4">
          These four values persist to <code>app_config</code> and drive the
          monthly settlement.
        </p>
        <div className="space-y-3">
          {(Object.keys(SAVABLE) as SavableKey[]).map((k) => {
            const meta = SAVABLE[k];
            const changed = draft[k] !== (config[k] ?? "");
            return (
              <div
                key={k}
                className="flex flex-col sm:flex-row sm:items-center gap-3"
              >
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-semibold text-slate-800">
                      {meta.label}
                    </p>
                    {changed && (
                      <span className="text-[10px] font-bold uppercase tracking-wider text-amber-700 bg-amber-100 rounded px-1.5 py-0.5">
                        unsaved
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-slate-400 mt-0.5">{meta.desc}</p>
                </div>
                <div className="flex items-center gap-2">
                  <input
                    type="number"
                    step="any"
                    value={draft[k] ?? ""}
                    onChange={(e) =>
                      setDraft((prev) => ({ ...prev, [k]: e.target.value }))
                    }
                    className="w-32 px-3 py-2 border border-slate-200 rounded-lg text-sm text-right font-mono focus:outline-none focus:ring-2 focus:ring-teal-500"
                  />
                  {meta.suffix && (
                    <span className="text-xs text-slate-400 w-12">
                      {meta.suffix}
                    </span>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* ── Live simulator ─────────────────────────────────────────────── */}
      <section className="bg-white rounded-xl border border-slate-200 p-5">
        <h2 className="text-base font-semibold text-slate-800 mb-1">
          Live simulator
        </h2>
        <p className="text-xs text-slate-400 mb-4">
          Adjust the assumptions; the stats below recompute instantly using
          your draft settings above.
        </p>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-5">
          <SimInput
            label="Active users this month"
            value={sim.activeUsers}
            onChange={(v) => setSim((p) => ({ ...p, activeUsers: v }))}
          />
          <SimInput
            label="Avg donatable Seeds / user / month"
            value={sim.avgSeeds}
            onChange={(v) => setSim((p) => ({ ...p, avgSeeds: v }))}
          />
        </div>

        <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
          <Stat
            label="Total Seeds donated"
            value={fmtNum(live.totalSeeds)}
            hint={
              live.effectiveSeedsPerUser < simSeeds
                ? `Capped at ${fmtNum(cap)}/user`
                : undefined
            }
          />
          <Stat
            label="Per-Seed value (effective)"
            value={fmtUSDPrecise(live.clampedSeedValue)}
            highlight
          />
          <Stat
            label="Avg user impact"
            value={fmtUSD(live.avgUserImpact)}
            highlight
          />
          <Stat
            label="Per-Seed value (raw)"
            value={fmtUSDPrecise(live.rawSeedValue)}
            hint={
              live.clampedByFloor
                ? "Below floor"
                : live.clampedByCeiling
                  ? "Above ceiling"
                  : "Within band"
            }
          />
          <Stat
            label="Pool distributed"
            value={fmtUSD(live.poolDistributed)}
          />
          <Stat
            label={live.surplus >= 0 ? "Surplus → reserve" : "Shortfall (top-up)"}
            value={fmtUSD(Math.abs(live.surplus))}
            tone={live.surplus >= 0 ? "good" : "warn"}
          />
        </div>

        {(live.clampedByFloor || live.clampedByCeiling) && (
          <p className="text-xs mt-4 px-3 py-2 rounded-lg bg-amber-50 border border-amber-200 text-amber-800">
            ⚠ Raw value{" "}
            {live.clampedByFloor
              ? "is below the floor — the platform tops up the difference from reserve."
              : "exceeds the ceiling — excess pool rolls into the reserve fund."}{" "}
            Adjust the pool size or the floor/ceiling to land inside the band.
          </p>
        )}
      </section>

      {/* ── Growth scenarios ───────────────────────────────────────────── */}
      <section className="bg-white rounded-xl border border-slate-200 p-5">
        <h2 className="text-base font-semibold text-slate-800 mb-1">
          Growth scenarios
        </h2>
        <p className="text-xs text-slate-400 mb-4">
          Each row uses your current draft settings with the same{" "}
          <span className="font-mono">avg Seeds/user</span> as the simulator,
          just different user counts. Use it to plan how much sponsor money
          you&apos;ll need at each stage.
        </p>
        <div className="overflow-x-auto -mx-2">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-[10px] uppercase text-slate-400 tracking-wider border-b border-slate-100">
                <th className="text-left font-semibold py-2 px-2">Stage</th>
                <th className="text-right font-semibold py-2 px-2">Active users</th>
                <th className="text-right font-semibold py-2 px-2">Total Seeds</th>
                <th className="text-right font-semibold py-2 px-2">1 Seed ≈</th>
                <th className="text-right font-semibold py-2 px-2">Avg user funds</th>
                <th className="text-right font-semibold py-2 px-2">Surplus / Shortfall</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {SCENARIOS.map((s) => {
                const r = compute(pool, minVal, maxVal, cap, s.users, simSeeds);
                return (
                  <tr key={s.stage}>
                    <td className="py-2.5 px-2 font-medium text-slate-700">
                      {s.stage}
                    </td>
                    <td className="text-right text-slate-600 font-mono">
                      {fmtNum(s.users)}
                    </td>
                    <td className="text-right text-slate-600 font-mono">
                      {fmtNum(r.totalSeeds)}
                    </td>
                    <td className="text-right text-slate-800 font-mono">
                      {fmtUSDPrecise(r.clampedSeedValue)}
                    </td>
                    <td className="text-right text-slate-800 font-mono">
                      {fmtUSD(r.avgUserImpact)}
                    </td>
                    <td
                      className={`text-right font-mono ${
                        r.surplus >= 0 ? "text-emerald-700" : "text-rose-700"
                      }`}
                    >
                      {r.surplus >= 0 ? "+" : "−"}
                      {fmtUSD(Math.abs(r.surplus))}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </section>

      {/* ── Save bar (sticky) ──────────────────────────────────────────── */}
      <div className="fixed bottom-0 left-0 right-0 lg:left-[240px] bg-white/90 backdrop-blur border-t border-slate-200 px-6 py-3 flex items-center gap-3 z-10">
        <p className="text-xs text-slate-500 flex-1">
          {hasChanges ? (
            <span className="text-amber-700 font-medium">
              You have unsaved changes
            </span>
          ) : (
            <span>All settings saved.</span>
          )}
        </p>
        <button
          onClick={handleSave}
          disabled={!hasChanges || saving}
          className="px-4 py-2 bg-teal-600 text-white text-sm font-semibold rounded-lg hover:bg-teal-700 disabled:opacity-40 transition cursor-pointer"
        >
          {saving ? "Saving…" : "Save settings"}
        </button>
      </div>
    </div>
  );
}

// ── Small presentational components ─────────────────────────────────────────
function SimInput({
  label,
  value,
  onChange,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
}) {
  return (
    <div>
      <label className="block text-xs font-medium text-slate-600 mb-1">
        {label}
      </label>
      <input
        type="number"
        min="0"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-teal-500"
      />
    </div>
  );
}

function Stat({
  label,
  value,
  hint,
  highlight = false,
  tone,
}: {
  label: string;
  value: string;
  hint?: string;
  highlight?: boolean;
  tone?: "good" | "warn";
}) {
  const base = "p-3 rounded-lg border";
  const palette = highlight
    ? "bg-teal-50 border-teal-100"
    : tone === "good"
      ? "bg-emerald-50 border-emerald-100"
      : tone === "warn"
        ? "bg-rose-50 border-rose-100"
        : "bg-slate-50 border-slate-100";
  const valueColor = highlight
    ? "text-teal-700"
    : tone === "good"
      ? "text-emerald-700"
      : tone === "warn"
        ? "text-rose-700"
        : "text-slate-800";
  return (
    <div className={`${base} ${palette}`}>
      <p className="text-[11px] text-slate-500 uppercase tracking-wider">
        {label}
      </p>
      <p className={`text-lg font-bold mt-1 font-mono ${valueColor}`}>{value}</p>
      {hint && <p className="text-[10px] text-slate-400 mt-0.5">{hint}</p>}
    </div>
  );
}
