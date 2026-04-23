"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";

type Project = {
  id: string;
  title: string;
  sponsor: string;
  category: string;
  location: string;
  short_description: string;
  story: string;
  impact_quote: string;
  target_points: number;
  estimated_usd: number;
  dp_url: string;
  is_active: boolean;
  is_completed: boolean;
  sort_order: number;
  end_date: string;
};

const EMPTY_PROJECT: Omit<Project, "id"> = {
  title: "",
  sponsor: "",
  category: "",
  location: "",
  short_description: "",
  story: "",
  impact_quote: "",
  target_points: 0,
  estimated_usd: 0,
  dp_url: "",
  is_active: true,
  is_completed: false,
  sort_order: 0,
  end_date: "",
};

export default function ProjectsPage() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Project | null>(null);
  const [creating, setCreating] = useState(false);
  const [form, setForm] = useState<Omit<Project, "id">>(EMPTY_PROJECT);
  const [saving, setSaving] = useState(false);

  async function loadProjects() {
    const { data } = await supabase
      .from("community_projects")
      .select("*")
      .order("sort_order");
    setProjects(data ?? []);
    setLoading(false);
  }

  useEffect(() => {
    loadProjects();
  }, []);

  function startEdit(p: Project) {
    setEditing(p);
    setCreating(false);
    setForm(p);
  }

  function startCreate() {
    setEditing(null);
    setCreating(true);
    setForm({ ...EMPTY_PROJECT, sort_order: projects.length });
  }

  async function handleSave() {
    setSaving(true);
    if (creating) {
      await supabase.from("community_projects").insert([form]);
    } else if (editing) {
      await supabase
        .from("community_projects")
        .update(form)
        .eq("id", editing.id);
    }
    setEditing(null);
    setCreating(false);
    await loadProjects();
    setSaving(false);
  }

  async function handleDelete(id: string) {
    if (!confirm("Delete this project?")) return;
    await supabase.from("community_projects").delete().eq("id", id);
    await loadProjects();
  }

  async function toggleActive(p: Project) {
    await supabase
      .from("community_projects")
      .update({ is_active: !p.is_active })
      .eq("id", p.id);
    await loadProjects();
  }

  async function toggleCompleted(p: Project) {
    await supabase
      .from("community_projects")
      .update({ is_completed: !p.is_completed })
      .eq("id", p.id);
    await loadProjects();
  }

  if (loading)
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );

  // Show form
  if (creating || editing) {
    return (
      <div className="max-w-3xl">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-semibold">
            {creating ? "New Project" : "Edit Project"}
          </h2>
          <button
            onClick={() => {
              setEditing(null);
              setCreating(false);
            }}
            className="text-sm text-slate-500 hover:text-slate-700 cursor-pointer"
          >
            Cancel
          </button>
        </div>

        <div className="space-y-4 bg-white rounded-xl border border-slate-200 p-6">
          {(
            [
              ["title", "Title", "text"],
              ["sponsor", "Sponsor", "text"],
              ["category", "Category", "text"],
              ["location", "Location", "text"],
              ["end_date", "End Date", "date"],
              ["target_points", "Target Points", "number"],
              ["estimated_usd", "Estimated USD", "number"],
              ["dp_url", "Display Picture URL", "text"],
              ["short_description", "Short Description", "textarea"],
              ["story", "Full Story", "textarea"],
              ["impact_quote", "Impact Quote", "textarea"],
            ] as const
          ).map(([key, label, type]) => (
            <div key={key}>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                {label}
              </label>
              {type === "textarea" ? (
                <textarea
                  value={(form as Record<string, unknown>)[key]?.toString() ?? ""}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, [key]: e.target.value }))
                  }
                  rows={3}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
                />
              ) : (
                <input
                  type={type}
                  value={(form as Record<string, unknown>)[key]?.toString() ?? ""}
                  onChange={(e) =>
                    setForm((f) => ({
                      ...f,
                      [key]:
                        type === "number"
                          ? Number(e.target.value)
                          : e.target.value,
                    }))
                  }
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
                />
              )}
            </div>
          ))}

          <div className="flex gap-4">
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={form.is_active}
                onChange={(e) =>
                  setForm((f) => ({ ...f, is_active: e.target.checked }))
                }
              />
              <span className="text-sm">Active</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={form.is_completed}
                onChange={(e) =>
                  setForm((f) => ({ ...f, is_completed: e.target.checked }))
                }
              />
              <span className="text-sm">Completed</span>
            </label>
          </div>

          <button
            onClick={handleSave}
            disabled={saving}
            className="px-6 py-2.5 bg-teal-600 text-white rounded-lg hover:bg-teal-700 disabled:opacity-50 transition cursor-pointer"
          >
            {saving ? "Saving..." : "Save Project"}
          </button>
        </div>
      </div>
    );
  }

  // List view
  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <p className="text-sm text-slate-500">
          {projects.length} project{projects.length !== 1 ? "s" : ""}
        </p>
        <button
          onClick={startCreate}
          className="px-4 py-2 bg-teal-600 text-white text-sm rounded-lg hover:bg-teal-700 transition cursor-pointer"
        >
          + New Project
        </button>
      </div>

      <div className="space-y-3">
        {projects.map((p) => (
          <div
            key={p.id}
            className="bg-white rounded-xl border border-slate-200 p-4 flex flex-col sm:flex-row sm:items-center gap-3"
          >
            {p.dp_url && (
              <img
                src={p.dp_url}
                alt=""
                className="w-16 h-16 rounded-lg object-cover"
              />
            )}
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-slate-800">{p.title}</p>
              <p className="text-xs text-slate-500">
                {p.sponsor} &middot; {p.category} &middot; {p.location}
              </p>
              <div className="flex gap-2 mt-1">
                {p.is_active && (
                  <span className="text-xs bg-green-50 text-green-700 px-2 py-0.5 rounded-full">
                    Active
                  </span>
                )}
                {p.is_completed && (
                  <span className="text-xs bg-blue-50 text-blue-700 px-2 py-0.5 rounded-full">
                    Completed
                  </span>
                )}
              </div>
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={() => toggleActive(p)}
                className="text-xs px-3 py-1.5 rounded-lg border border-slate-200 hover:bg-slate-50 cursor-pointer"
              >
                {p.is_active ? "Deactivate" : "Activate"}
              </button>
              <button
                onClick={() => toggleCompleted(p)}
                className="text-xs px-3 py-1.5 rounded-lg border border-slate-200 hover:bg-slate-50 cursor-pointer"
              >
                {p.is_completed ? "Uncomplete" : "Complete"}
              </button>
              <button
                onClick={() => startEdit(p)}
                className="text-xs px-3 py-1.5 rounded-lg bg-teal-50 text-teal-700 hover:bg-teal-100 cursor-pointer"
              >
                Edit
              </button>
              <button
                onClick={() => handleDelete(p.id)}
                className="text-xs px-3 py-1.5 rounded-lg bg-red-50 text-red-600 hover:bg-red-100 cursor-pointer"
              >
                Delete
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
