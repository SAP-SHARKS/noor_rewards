"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";

type Profile = {
  id: string;
  display_name: string;
  noor_points: number;
  level: number;
  day_streak: number;
  country: string;
  created_at: string;
};

export default function UsersPage() {
  const [users, setUsers] = useState<Profile[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [grantUserId, setGrantUserId] = useState<string | null>(null);
  const [grantAmount, setGrantAmount] = useState("");
  const [granting, setGranting] = useState(false);

  useEffect(() => {
    supabase
      .from("profiles")
      .select("*")
      .order("noor_points", { ascending: false })
      .limit(100)
      .then(({ data }) => {
        setUsers(data ?? []);
        setLoading(false);
      });
  }, []);

  async function handleGrant(userId: string) {
    const amount = parseInt(grantAmount);
    if (!amount || amount <= 0) return;
    setGranting(true);
    await supabase.rpc("grant_points", {
      p_user_id: userId,
      p_amount: amount,
    });
    // Refresh
    const { data } = await supabase
      .from("profiles")
      .select("*")
      .order("noor_points", { ascending: false })
      .limit(100);
    setUsers(data ?? []);
    setGrantUserId(null);
    setGrantAmount("");
    setGranting(false);
  }

  const filtered = search
    ? users.filter((u) =>
        u.display_name?.toLowerCase().includes(search.toLowerCase())
      )
    : users;

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
          placeholder="Search by name..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="flex-1 max-w-sm px-4 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
        />
        <p className="text-sm text-slate-500">
          Top {users.length} users by Points
        </p>
      </div>

      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200">
              <th className="text-left px-4 py-3 font-medium text-slate-600">
                #
              </th>
              <th className="text-left px-4 py-3 font-medium text-slate-600">
                Name
              </th>
              <th className="text-right px-4 py-3 font-medium text-slate-600">
                Level
              </th>
              <th className="text-right px-4 py-3 font-medium text-slate-600">
                Points
              </th>
              <th className="text-right px-4 py-3 font-medium text-slate-600">
                Streak
              </th>
              <th className="text-right px-4 py-3 font-medium text-slate-600">
                Actions
              </th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((u, i) => (
              <tr key={u.id} className="border-b border-slate-100 last:border-0">
                <td className="px-4 py-3 text-slate-400">{i + 1}</td>
                <td className="px-4 py-3">
                  <p className="font-medium text-slate-800">
                    {u.display_name || "Anonymous"}
                  </p>
                  <p className="text-xs text-slate-400">
                    {u.country || "—"} &middot; Joined{" "}
                    {new Date(u.created_at).toLocaleDateString()}
                  </p>
                </td>
                <td className="px-4 py-3 text-right text-slate-600">
                  {u.level}
                </td>
                <td className="px-4 py-3 text-right font-semibold text-slate-800">
                  {u.noor_points?.toLocaleString()}
                </td>
                <td className="px-4 py-3 text-right text-slate-600">
                  {u.day_streak}d
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
                    <button
                      onClick={() => setGrantUserId(u.id)}
                      className="text-xs text-teal-600 hover:text-teal-800 cursor-pointer"
                    >
                      Grant Points
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
