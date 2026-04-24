"use client";

import { useEffect, useState, useRef } from "react";
import {
  supabase,
  fetchAllConfig,
  updateConfigKey,
  type AppConfigRow,
} from "@/lib/supabase";

export default function RawConfigPage() {
  const [rows, setRows] = useState<AppConfigRow[]>([]);
  const [editing, setEditing] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const emailRef = useRef("");

  useEffect(() => {
    Promise.all([fetchAllConfig(), supabase.auth.getUser()]).then(
      ([configData, { data }]) => {
        setRows(configData);
        const map: Record<string, string> = {};
        for (const r of configData) map[r.key] = r.value;
        setEditing(map);
        emailRef.current = data.user?.email ?? "admin";
        setLoading(false);
      }
    );
  }, []);

  async function handleSave(key: string) {
    setSaving(key);
    await updateConfigKey(key, editing[key], emailRef.current);
    setRows((prev) =>
      prev.map((r) =>
        r.key === key
          ? {
              ...r,
              value: editing[key],
              updated_at: new Date().toISOString(),
              updated_by: emailRef.current,
            }
          : r
      )
    );
    setSaving(null);
  }

  const filtered = search
    ? rows.filter(
        (r) =>
          r.key.toLowerCase().includes(search.toLowerCase()) ||
          r.description?.toLowerCase().includes(search.toLowerCase())
      )
    : rows;

  // Group by prefix
  const groups: Record<string, AppConfigRow[]> = {};
  for (const row of filtered) {
    const prefix = row.key.split("_")[0] || "other";
    if (!groups[prefix]) groups[prefix] = [];
    groups[prefix].push(row);
  }

  if (loading)
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );

  return (
    <div>
      <div className="flex items-center gap-4 mb-6">
        <input
          type="text"
          placeholder="Search config keys..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="flex-1 max-w-sm px-4 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
        />
        <p className="text-sm text-slate-500">{rows.length} keys</p>
      </div>

      <div className="space-y-6">
        {Object.entries(groups).map(([group, items]) => (
          <div key={group}>
            <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2 px-1">
              {group}
            </h3>
            <div className="space-y-2">
              {items.map((row) => {
                const changed = editing[row.key] !== row.value;
                return (
                  <div
                    key={row.key}
                    className="bg-white rounded-xl border border-slate-200 p-4"
                  >
                    <div className="flex flex-col sm:flex-row sm:items-center gap-3">
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-mono font-semibold text-slate-800">
                          {row.key}
                        </p>
                        {row.description && (
                          <p className="text-xs text-slate-400">
                            {row.description}
                          </p>
                        )}
                        {row.updated_at && (
                          <p className="text-xs text-slate-300 mt-0.5">
                            Updated{" "}
                            {new Date(row.updated_at).toLocaleString()} by{" "}
                            {row.updated_by || "—"}
                          </p>
                        )}
                      </div>
                      <div className="flex items-center gap-2">
                        <input
                          type="text"
                          value={editing[row.key] ?? ""}
                          onChange={(e) =>
                            setEditing((prev) => ({
                              ...prev,
                              [row.key]: e.target.value,
                            }))
                          }
                          className="w-48 px-3 py-2 border border-slate-200 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-teal-500"
                        />
                        <button
                          onClick={() => handleSave(row.key)}
                          disabled={!changed || saving === row.key}
                          className="px-4 py-2 bg-slate-800 text-white text-sm rounded-lg hover:bg-slate-900 disabled:opacity-30 transition cursor-pointer"
                        >
                          {saving === row.key ? "..." : "Save"}
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
