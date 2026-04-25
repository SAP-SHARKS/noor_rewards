"use client";

import { useEffect, useState, useRef } from "react";
import { supabase } from "@/lib/supabase";

// ── Types ────────────────────────────────────────────────────────────────────

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
  current_points?: number;
};

type MediaItem = {
  id: string;
  project_id: string;
  media_type: "image" | "video";
  url: string;
  caption: string | null;
  sort_order: number;
};

const EMPTY: Omit<Project, "id"> = {
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

const BUCKET = "project-media";

// ── Helpers ──────────────────────────────────────────────────────────────────

function daysLeft(endDate: string): number {
  if (!endDate) return -1;
  const diff = new Date(endDate).getTime() - Date.now();
  return Math.max(0, Math.ceil(diff / 86400000));
}

function pct(current: number, target: number): number {
  if (target <= 0) return 0;
  return Math.min(100, Math.round((current / target) * 100));
}

function mimeFor(ext: string, type: "image" | "video"): string {
  if (type === "video") {
    if (ext === "mov") return "video/quicktime";
    if (ext === "webm") return "video/webm";
    return "video/mp4";
  }
  if (ext === "png") return "image/png";
  if (ext === "webp") return "image/webp";
  if (ext === "gif") return "image/gif";
  return "image/jpeg";
}

// ── Component ────────────────────────────────────────────────────────────────

export default function ProjectsPage() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [donations, setDonations] = useState<Record<string, number>>({});
  const [loading, setLoading] = useState(true);
  const [view, setView] = useState<"list" | "form" | "media">("list");
  const [editing, setEditing] = useState<Project | null>(null);
  const [form, setForm] = useState<Omit<Project, "id">>(EMPTY);
  const [saving, setSaving] = useState(false);

  // Media state
  const [media, setMedia] = useState<MediaItem[]>([]);
  const [mediaProject, setMediaProject] = useState<Project | null>(null);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState("");
  const [dragging, setDragging] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);
  const coverRef = useRef<HTMLInputElement>(null);

  // ── Data loading ─────────────────────────────────────────────────────────

  async function loadProjects() {
    const [{ data: proj }, { data: donData }] = await Promise.all([
      supabase.from("community_projects").select("*").order("sort_order"),
      supabase.from("user_donations").select("project_id, points_donated"),
    ]);

    const totals: Record<string, number> = {};
    for (const d of donData ?? []) {
      totals[d.project_id] = (totals[d.project_id] ?? 0) + (d.points_donated ?? 0);
    }
    setDonations(totals);
    setProjects(proj ?? []);
    setLoading(false);
  }

  async function loadMedia(projectId: string) {
    const { data } = await supabase
      .from("community_project_media")
      .select("*")
      .eq("project_id", projectId)
      .order("sort_order");
    setMedia(data ?? []);
  }

  useEffect(() => {
    loadProjects();
  }, []);

  // ── Project CRUD ─────────────────────────────────────────────────────────

  function openCreate() {
    setEditing(null);
    setForm({ ...EMPTY, sort_order: projects.length });
    setView("form");
  }

  function openEdit(p: Project) {
    setEditing(p);
    setForm(p);
    setView("form");
  }

  function openMedia(p: Project) {
    setMediaProject(p);
    loadMedia(p.id);
    setView("media");
  }

  async function handleSave() {
    setSaving(true);
    if (editing) {
      await supabase.from("community_projects").update(form).eq("id", editing.id);
    } else {
      await supabase.from("community_projects").insert([form]);
    }
    await loadProjects();
    setSaving(false);
    setView("list");
  }

  async function handleDelete(id: string) {
    if (!confirm("Delete this project and all its media?")) return;
    await supabase.from("community_projects").delete().eq("id", id);
    await loadProjects();
  }

  async function toggleField(p: Project, field: "is_active" | "is_completed") {
    await supabase
      .from("community_projects")
      .update({ [field]: !p[field] })
      .eq("id", p.id);
    await loadProjects();
  }

  // ── Cover image upload ───────────────────────────────────────────────────

  async function handleCoverUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file || !editing) return;
    setUploading(true);
    const ext = file.name.split(".").pop()?.toLowerCase() ?? "jpg";
    const path = `${editing.id}/dp_${crypto.randomUUID()}.${ext}`;
    await supabase.storage.from(BUCKET).upload(path, file, {
      contentType: mimeFor(ext, "image"),
      upsert: true,
    });
    const { data } = supabase.storage.from(BUCKET).getPublicUrl(path);
    const url = data.publicUrl;
    await supabase.from("community_projects").update({ dp_url: url }).eq("id", editing.id);
    setForm((f) => ({ ...f, dp_url: url }));
    setEditing((prev) => prev ? { ...prev, dp_url: url } : prev);
    setUploading(false);
  }

  // ── Media carousel management ────────────────────────────────────────────

  async function uploadFiles(files: File[]) {
    if (!files.length || !mediaProject) return;
    setUploading(true);
    let nextOrder = media.length;
    const total = files.length;

    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      setUploadProgress(`Uploading ${i + 1} of ${total} — ${file.name}`);
      const ext = file.name.split(".").pop()?.toLowerCase() ?? "jpg";
      const isVideo = file.type.startsWith("video/") || ["mp4", "mov", "webm"].includes(ext);
      const mediaType = isVideo ? "video" : "image";
      const path = `${mediaProject.id}/${crypto.randomUUID()}.${ext}`;

      await supabase.storage.from(BUCKET).upload(path, file, {
        contentType: mimeFor(ext, mediaType),
      });

      const { data } = supabase.storage.from(BUCKET).getPublicUrl(path);

      await supabase.from("community_project_media").insert({
        project_id: mediaProject.id,
        media_type: mediaType,
        url: data.publicUrl,
        sort_order: nextOrder++,
      });
    }

    await loadMedia(mediaProject.id);
    setUploading(false);
    setUploadProgress("");
    if (fileRef.current) fileRef.current.value = "";
  }

  async function handleMediaUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const files = e.target.files;
    if (!files?.length) return;
    await uploadFiles(Array.from(files));
  }

  function handleDrop(e: React.DragEvent) {
    e.preventDefault();
    setDragging(false);
    const files = Array.from(e.dataTransfer.files).filter(
      (f) => f.type.startsWith("image/") || f.type.startsWith("video/")
    );
    if (files.length) uploadFiles(files);
  }

  async function deleteMedia(item: MediaItem) {
    if (!confirm("Delete this media?")) return;
    // Delete from storage
    const marker = `/${BUCKET}/`;
    const idx = item.url.indexOf(marker);
    if (idx !== -1) {
      const storagePath = item.url.substring(idx + marker.length);
      await supabase.storage.from(BUCKET).remove([storagePath]);
    }
    await supabase.from("community_project_media").delete().eq("id", item.id);
    setMedia((prev) => prev.filter((m) => m.id !== item.id));
  }

  async function moveMedia(index: number, direction: -1 | 1) {
    const target = index + direction;
    if (target < 0 || target >= media.length) return;
    const items = [...media];
    [items[index], items[target]] = [items[target], items[index]];
    items.forEach((m, i) => (m.sort_order = i));
    setMedia(items);
    await Promise.all(
      items.map((m, i) =>
        supabase.from("community_project_media").update({ sort_order: i }).eq("id", m.id)
      )
    );
  }

  // ── Loading ──────────────────────────────────────────────────────────────

  if (loading)
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );

  // ═══════════════════════════════════════════════════════════════════════════
  // MEDIA MANAGER VIEW
  // ═══════════════════════════════════════════════════════════════════════════

  if (view === "media" && mediaProject) {
    return (
      <div className="max-w-4xl">
        <div className="flex items-center justify-between mb-6">
          <div>
            <button
              onClick={() => setView("list")}
              className="text-sm text-teal-600 hover:text-teal-800 cursor-pointer mb-1"
            >
              ← Back to Projects
            </button>
            <h2 className="text-lg font-semibold text-slate-800">
              Media — {mediaProject.title}
            </h2>
            <p className="text-xs text-slate-400">{media.length} item{media.length !== 1 ? "s" : ""} in carousel</p>
          </div>
          <div>
            <input
              ref={fileRef}
              type="file"
              accept="image/*,video/mp4,video/quicktime,video/webm"
              multiple
              onChange={handleMediaUpload}
              className="hidden"
            />
            <button
              onClick={() => fileRef.current?.click()}
              disabled={uploading}
              className="px-4 py-2 bg-slate-800 text-white text-sm rounded-lg hover:bg-slate-900 disabled:opacity-50 cursor-pointer"
            >
              {uploading ? uploadProgress : "+ Upload Images / Videos"}
            </button>
          </div>
        </div>

        {/* Drag & Drop Zone */}
        <div
          onDragOver={(e) => { e.preventDefault(); setDragging(true); }}
          onDragLeave={() => setDragging(false)}
          onDrop={handleDrop}
          className={`rounded-xl border-2 border-dashed p-6 mb-6 text-center transition cursor-pointer ${
            dragging
              ? "border-blue-400 bg-blue-50"
              : "border-slate-200 bg-white hover:border-slate-300"
          }`}
          onClick={() => !uploading && fileRef.current?.click()}
        >
          {uploading ? (
            <div className="flex items-center justify-center gap-3">
              <div className="animate-spin w-5 h-5 border-2 border-slate-800 border-t-transparent rounded-full" />
              <p className="text-sm text-slate-600">{uploadProgress}</p>
            </div>
          ) : (
            <>
              <svg className="w-8 h-8 text-slate-300 mx-auto mb-2" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5m-13.5-9L12 3m0 0l4.5 4.5M12 3v13.5" /></svg>
              <p className="text-sm text-slate-500">
                {dragging ? "Drop files here" : "Drag and drop images or videos here, or click to browse"}
              </p>
              <p className="text-xs text-slate-400 mt-1">
                JPG, PNG, WebP, GIF, MP4, MOV, WebM — multiple files supported
              </p>
            </>
          )}
        </div>

        {media.length === 0 && !uploading ? (
          <div className="text-center py-8">
            <p className="text-sm text-slate-400">
              No media uploaded yet. Use the area above to add images and videos.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            {media.map((item, i) => (
              <div
                key={item.id}
                className="bg-white rounded-xl border border-slate-200 overflow-hidden group"
              >
                {item.media_type === "image" ? (
                  <img
                    src={item.url}
                    alt=""
                    className="w-full h-40 object-cover"
                  />
                ) : (
                  <div className="w-full h-40 bg-slate-900 flex items-center justify-center relative">
                    <video src={item.url} className="w-full h-full object-cover" />
                    <div className="absolute inset-0 flex items-center justify-center">
                      <span className="w-12 h-12 rounded-full bg-white/80 flex items-center justify-center text-xl">
                        ▶
                      </span>
                    </div>
                  </div>
                )}
                <div className="p-3 flex items-center justify-between">
                  <div className="flex items-center gap-1">
                    <span className="text-xs text-slate-400 uppercase font-medium">
                      {item.media_type}
                    </span>
                    <span className="text-xs text-slate-300">
                      #{item.sort_order + 1}
                    </span>
                  </div>
                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => moveMedia(i, -1)}
                      disabled={i === 0}
                      className="w-7 h-7 flex items-center justify-center rounded text-xs text-slate-400 hover:bg-slate-100 disabled:opacity-20 cursor-pointer"
                    >
                      ←
                    </button>
                    <button
                      onClick={() => moveMedia(i, 1)}
                      disabled={i >= media.length - 1}
                      className="w-7 h-7 flex items-center justify-center rounded text-xs text-slate-400 hover:bg-slate-100 disabled:opacity-20 cursor-pointer"
                    >
                      →
                    </button>
                    <button
                      onClick={() => deleteMedia(item)}
                      className="w-7 h-7 flex items-center justify-center rounded text-xs text-red-400 hover:bg-red-50 cursor-pointer"
                    >
                      ✕
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATE / EDIT FORM
  // ═══════════════════════════════════════════════════════════════════════════

  if (view === "form") {
    return (
      <div className="max-w-3xl">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-semibold">
            {editing ? "Edit Project" : "New Project"}
          </h2>
          <button
            onClick={() => setView("list")}
            className="text-sm text-slate-500 hover:text-slate-700 cursor-pointer"
          >
            Cancel
          </button>
        </div>

        <div className="space-y-6">
          {/* Cover Image */}
          <div className="bg-white rounded-xl border border-slate-200 p-6">
            <h3 className="text-sm font-semibold text-slate-800 mb-3">
              Cover Image
            </h3>
            {form.dp_url ? (
              <div className="relative rounded-lg overflow-hidden mb-3">
                <img
                  src={form.dp_url}
                  alt=""
                  className="w-full h-48 object-cover"
                />
                <button
                  onClick={() => setForm((f) => ({ ...f, dp_url: "" }))}
                  className="absolute top-2 right-2 w-8 h-8 rounded-full bg-black/50 text-white flex items-center justify-center text-sm hover:bg-black/70 cursor-pointer"
                >
                  ✕
                </button>
              </div>
            ) : (
              <div className="border-2 border-dashed border-slate-200 rounded-lg p-8 text-center mb-3">
                <svg className="w-8 h-8 text-slate-300 mb-2 mx-auto" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909M3.75 21h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v13.5A1.5 1.5 0 003.75 21z" /></svg>
                <p className="text-sm text-slate-400">No cover image set</p>
              </div>
            )}
            {editing && (
              <>
                <input
                  ref={coverRef}
                  type="file"
                  accept="image/*"
                  onChange={handleCoverUpload}
                  className="hidden"
                />
                <button
                  onClick={() => coverRef.current?.click()}
                  disabled={uploading}
                  className="px-4 py-2 bg-slate-100 text-slate-700 text-sm rounded-lg hover:bg-slate-200 disabled:opacity-50 cursor-pointer"
                >
                  {uploading ? "Uploading..." : "Upload Cover Image"}
                </button>
              </>
            )}
            {!editing && (
              <p className="text-xs text-slate-400">
                Save the project first, then you can upload a cover image.
              </p>
            )}
          </div>

          {/* Details */}
          <div className="bg-white rounded-xl border border-slate-200 p-6 space-y-4">
            <h3 className="text-sm font-semibold text-slate-800 mb-1">
              Project Details
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {(
                [
                  ["title", "Title"],
                  ["sponsor", "Sponsor / Organization"],
                  ["category", "Category"],
                  ["location", "Location"],
                ] as const
              ).map(([key, label]) => (
                <div key={key}>
                  <label className="block text-xs font-medium text-slate-500 mb-1">
                    {label}
                  </label>
                  <input
                    type="text"
                    value={(form as Record<string, unknown>)[key]?.toString() ?? ""}
                    onChange={(e) => setForm((f) => ({ ...f, [key]: e.target.value }))}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
                  />
                </div>
              ))}
            </div>

            <div>
              <label className="block text-xs font-medium text-slate-500 mb-1">
                Short Description
              </label>
              <textarea
                value={form.short_description}
                onChange={(e) =>
                  setForm((f) => ({ ...f, short_description: e.target.value }))
                }
                rows={2}
                className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
              />
            </div>

            <div>
              <label className="block text-xs font-medium text-slate-500 mb-1">
                Full Campaign Story
              </label>
              <textarea
                value={form.story}
                onChange={(e) => setForm((f) => ({ ...f, story: e.target.value }))}
                rows={5}
                className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
              />
            </div>

            <div>
              <label className="block text-xs font-medium text-slate-500 mb-1">
                Impact Quote
              </label>
              <textarea
                value={form.impact_quote}
                onChange={(e) =>
                  setForm((f) => ({ ...f, impact_quote: e.target.value }))
                }
                rows={2}
                className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
              />
            </div>
          </div>

          {/* Funding */}
          <div className="bg-white rounded-xl border border-slate-200 p-6 space-y-4">
            <h3 className="text-sm font-semibold text-slate-800 mb-1">
              Funding Goal
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div>
                <label className="block text-xs font-medium text-slate-500 mb-1">
                  Target Points
                </label>
                <input
                  type="number"
                  value={form.target_points}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, target_points: Number(e.target.value) }))
                  }
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-slate-500 mb-1">
                  Estimated USD
                </label>
                <input
                  type="number"
                  value={form.estimated_usd}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, estimated_usd: Number(e.target.value) }))
                  }
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-slate-500 mb-1">
                  End Date
                </label>
                <input
                  type="date"
                  value={form.end_date}
                  onChange={(e) => setForm((f) => ({ ...f, end_date: e.target.value }))}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
                />
              </div>
            </div>
          </div>

          {/* Status + Save */}
          <div className="bg-white rounded-xl border border-slate-200 p-6 flex items-center justify-between">
            <div className="flex gap-6">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={form.is_active}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, is_active: e.target.checked }))
                  }
                  className="w-4 h-4 accent-teal-600"
                />
                <span className="text-sm text-slate-700">Active</span>
              </label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={form.is_completed}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, is_completed: e.target.checked }))
                  }
                  className="w-4 h-4 accent-teal-600"
                />
                <span className="text-sm text-slate-700">Completed</span>
              </label>
            </div>
            <button
              onClick={handleSave}
              disabled={saving || !form.title.trim()}
              className="px-6 py-2.5 bg-slate-800 text-white rounded-lg hover:bg-slate-900 disabled:opacity-50 transition cursor-pointer font-medium"
            >
              {saving ? "Saving..." : "Save Project"}
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROJECT LIST — LaunchGood-style cards
  // ═══════════════════════════════════════════════════════════════════════════

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <p className="text-sm text-slate-500">
          {projects.length} project{projects.length !== 1 ? "s" : ""}
        </p>
        <button
          onClick={openCreate}
          className="px-4 py-2.5 bg-slate-800 text-white text-sm rounded-lg hover:bg-slate-900 transition cursor-pointer font-medium"
        >
          + New Project
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
        {projects.map((p) => {
          const current = donations[p.id] ?? 0;
          const progress = pct(current, p.target_points);
          const days = daysLeft(p.end_date);

          return (
            <div
              key={p.id}
              className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-sm hover:shadow-md transition-shadow"
            >
              {/* Cover */}
              <div className="relative h-44 bg-gradient-to-br from-teal-100 to-emerald-50">
                {p.dp_url ? (
                  <img
                    src={p.dp_url}
                    alt=""
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <svg className="w-12 h-12 text-slate-300" fill="none" stroke="currentColor" strokeWidth={1} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909M3.75 21h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v13.5A1.5 1.5 0 003.75 21z" /></svg>
                  </div>
                )}
                {/* Category badge */}
                {p.category && (
                  <span className="absolute top-3 left-3 px-2.5 py-1 bg-white/90 backdrop-blur text-xs font-semibold text-teal-700 rounded-full shadow-sm">
                    {p.category}
                  </span>
                )}
                {/* Status */}
                <div className="absolute top-3 right-3 flex gap-1.5">
                  {!p.is_active && (
                    <span className="px-2 py-1 bg-red-500/90 text-white text-xs rounded-full font-medium">
                      Inactive
                    </span>
                  )}
                  {p.is_completed && (
                    <span className="px-2 py-1 bg-blue-500/90 text-white text-xs rounded-full font-medium">
                      Completed
                    </span>
                  )}
                </div>
              </div>

              {/* Content */}
              <div className="p-4">
                <h3 className="text-base font-bold text-slate-800 leading-tight mb-1 line-clamp-2">
                  {p.title || "Untitled Project"}
                </h3>
                <p className="text-xs text-slate-400 mb-3">
                  by {p.sponsor || "—"} &middot; {p.location || "—"}
                </p>

                {/* Progress bar */}
                <div className="mb-2">
                  <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-teal-500 rounded-full transition-all"
                      style={{ width: `${progress}%` }}
                    />
                  </div>
                </div>

                {/* Stats row */}
                <div className="flex items-center justify-between text-xs mb-4">
                  <div>
                    <span className="font-bold text-slate-800">
                      {current.toLocaleString()}
                    </span>
                    <span className="text-slate-400">
                      {" "}/ {p.target_points.toLocaleString()} pts
                    </span>
                  </div>
                  <span className="font-bold text-teal-600">{progress}%</span>
                </div>

                {/* Meta */}
                <div className="flex items-center gap-3 text-xs text-slate-400 mb-4">
                  {p.estimated_usd > 0 && (
                    <span>~${p.estimated_usd.toLocaleString()}</span>
                  )}
                  {days >= 0 && (
                    <span>
                      {days === 0
                        ? "Ends today"
                        : `${days} day${days !== 1 ? "s" : ""} left`}
                    </span>
                  )}
                </div>

                {/* Actions */}
                <div className="flex items-center gap-2 pt-3 border-t border-slate-100">
                  <button
                    onClick={() => openEdit(p)}
                    className="flex-1 py-2 text-xs font-medium text-teal-700 bg-teal-50 rounded-lg hover:bg-teal-100 cursor-pointer text-center"
                  >
                    Edit
                  </button>
                  <button
                    onClick={() => openMedia(p)}
                    className="flex-1 py-2 text-xs font-medium text-indigo-700 bg-indigo-50 rounded-lg hover:bg-indigo-100 cursor-pointer text-center"
                  >
                    Media
                  </button>
                  <button
                    onClick={() => toggleField(p, "is_active")}
                    className="flex-1 py-2 text-xs font-medium text-slate-600 bg-slate-50 rounded-lg hover:bg-slate-100 cursor-pointer text-center"
                  >
                    {p.is_active ? "Deactivate" : "Activate"}
                  </button>
                  <button
                    onClick={() => handleDelete(p.id)}
                    className="py-2 px-3 text-xs text-red-500 bg-red-50 rounded-lg hover:bg-red-100 cursor-pointer"
                  >
                    ✕
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {projects.length === 0 && (
        <div className="bg-white rounded-2xl border-2 border-dashed border-slate-200 p-16 text-center">
          <svg className="w-10 h-10 text-slate-300 mb-3 mx-auto" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" /></svg>
          <p className="text-slate-500 mb-4">No projects yet</p>
          <button
            onClick={openCreate}
            className="px-4 py-2 bg-slate-800 text-white text-sm rounded-lg hover:bg-slate-900 cursor-pointer"
          >
            Create Your First Project
          </button>
        </div>
      )}
    </div>
  );
}
