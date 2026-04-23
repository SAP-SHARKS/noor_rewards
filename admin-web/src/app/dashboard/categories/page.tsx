"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";

type Category = {
  id: string;
  label: string;
  icon: string;
  is_visible: boolean;
  sort_order: number;
};

export default function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [toggling, setToggling] = useState<string | null>(null);

  async function loadCategories() {
    const { data } = await supabase
      .from("azkar_categories")
      .select("*")
      .order("sort_order");
    setCategories(data ?? []);
    setLoading(false);
  }

  useEffect(() => {
    loadCategories();
  }, []);

  async function toggleVisibility(cat: Category) {
    setToggling(cat.id);
    // Optimistic update
    setCategories((prev) =>
      prev.map((c) =>
        c.id === cat.id ? { ...c, is_visible: !c.is_visible } : c
      )
    );
    await supabase
      .from("azkar_categories")
      .update({ is_visible: !cat.is_visible })
      .eq("id", cat.id);
    setToggling(null);
  }

  async function moveUp(index: number) {
    if (index === 0) return;
    const items = [...categories];
    const prev = items[index - 1];
    const curr = items[index];
    // Optimistic swap
    [items[index - 1], items[index]] = [
      { ...curr, sort_order: prev.sort_order },
      { ...prev, sort_order: curr.sort_order },
    ];
    setCategories(items);
    await Promise.all([
      supabase
        .from("azkar_categories")
        .update({ sort_order: prev.sort_order })
        .eq("id", curr.id),
      supabase
        .from("azkar_categories")
        .update({ sort_order: curr.sort_order })
        .eq("id", prev.id),
    ]);
  }

  async function moveDown(index: number) {
    if (index >= categories.length - 1) return;
    const items = [...categories];
    const next = items[index + 1];
    const curr = items[index];
    // Optimistic swap
    [items[index], items[index + 1]] = [
      { ...next, sort_order: curr.sort_order },
      { ...curr, sort_order: next.sort_order },
    ];
    setCategories(items);
    await Promise.all([
      supabase
        .from("azkar_categories")
        .update({ sort_order: next.sort_order })
        .eq("id", curr.id),
      supabase
        .from("azkar_categories")
        .update({ sort_order: curr.sort_order })
        .eq("id", next.id),
    ]);
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
        Control which azkar categories are visible in the app and their display
        order.
      </p>

      <div className="space-y-2">
        {categories.map((cat, i) => (
          <div
            key={cat.id}
            className={`bg-white rounded-xl border px-5 py-4 flex items-center gap-4 min-h-[72px] transition ${
              cat.is_visible
                ? "border-slate-200"
                : "border-slate-100 opacity-50"
            }`}
          >
            <span className="text-xl shrink-0">{cat.icon || "📿"}</span>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-slate-800">
                {cat.label}
              </p>
              <p className="text-xs text-slate-400">
                Order: {cat.sort_order}
              </p>
            </div>

            {/* Reorder */}
            <div className="shrink-0 flex flex-col gap-1">
              <button
                onClick={() => moveUp(i)}
                disabled={i === 0}
                className="w-7 h-7 flex items-center justify-center rounded-md text-xs text-slate-400 hover:bg-slate-100 hover:text-slate-700 disabled:opacity-20 cursor-pointer"
              >
                ▲
              </button>
              <button
                onClick={() => moveDown(i)}
                disabled={i >= categories.length - 1}
                className="w-7 h-7 flex items-center justify-center rounded-md text-xs text-slate-400 hover:bg-slate-100 hover:text-slate-700 disabled:opacity-20 cursor-pointer"
              >
                ▼
              </button>
            </div>

            {/* Visibility toggle */}
            <div className="shrink-0 pl-3">
              <button
                onClick={() => toggleVisibility(cat)}
                disabled={toggling === cat.id}
                className={`relative w-[52px] h-[28px] rounded-full transition-colors cursor-pointer ${
                  cat.is_visible ? "bg-teal-500" : "bg-slate-200"
                }`}
              >
                <span
                  className={`absolute top-[2px] left-[2px] w-6 h-6 bg-white rounded-full shadow transition-transform ${
                    cat.is_visible ? "translate-x-6" : "translate-x-0"
                  }`}
                />
              </button>
            </div>
          </div>
        ))}

        {categories.length === 0 && (
          <p className="text-sm text-slate-400 text-center py-8">
            No azkar categories found.
          </p>
        )}
      </div>
    </div>
  );
}
