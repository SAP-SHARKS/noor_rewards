"use client";

import { useEffect, useState, useTransition } from "react";
import { useRouter, usePathname } from "next/navigation";
import Link from "next/link";
import { supabase, ADMIN_EMAILS } from "@/lib/supabase";
import { ConfigProvider } from "@/lib/config-context";
import type { User } from "@supabase/supabase-js";
import SabiqLogo from "@/components/SabiqLogo";
import { TONE_LIGHT, TONE_DARK, type Tone } from "@/lib/admin-tones";

// SVG icon paths (Heroicons outline style)
const ICONS: Record<string, string> = {
  overview:
    "M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-4 0a1 1 0 01-1-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 01-1 1",
  economy:
    "M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
  theme:
    "M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01",
  projects:
    "M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4",
  users:
    "M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z",
  features:
    "M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z",
  banners:
    "M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z",
  config:
    "M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z M15 12a3 3 0 11-6 0 3 3 0 016 0z",
  analytics:
    "M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z",
  categories:
    "M4 6h16M4 10h16M4 14h16M4 18h16",
  onboarding:
    "M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5z",
  donor_pool:
    "M2.25 18 9 11.25l4.306 4.307a11.95 11.95 0 015.814-5.519l2.74-1.22m0 0l-5.94-2.281m5.94 2.28l-2.28 5.941",
  orphans:
    "M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7zM21 9.75l-2.25 2.25M21 9.75l-2.25-2.25",
  azkar:
    "M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25",
  notifications:
    "M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0",
};

// Per-section color tint. Each nav item owns a tone so the active sidebar
// pill and the top-bar section chip stay visually linked. Page bodies can
// import TONE_LIGHT/TONE_DARK from "@/lib/admin-tones" to use the same
// palette ad-hoc (stat cards, pills, badges).
const NAV_ITEMS: { href: string; label: string; icon: string; tone: Tone }[] = [
  { href: "/dashboard",            label: "Overview",          icon: "overview",   tone: "teal" },
  { href: "/dashboard/economy",    label: "Economy",           icon: "economy",    tone: "amber" },
  { href: "/dashboard/donor-pool", label: "Donor Pool",        icon: "donor_pool", tone: "emerald" },
  { href: "/dashboard/theme",      label: "Theme & Colors",    icon: "theme",      tone: "violet" },
  { href: "/dashboard/projects",   label: "Projects",          icon: "projects",   tone: "sky" },
  { href: "/dashboard/orphans",    label: "Orphans",           icon: "orphans",    tone: "rose" },
  { href: "/dashboard/users",      label: "Users",             icon: "users",      tone: "indigo" },
  { href: "/dashboard/features",   label: "Feature Flags",     icon: "features",   tone: "fuchsia" },
  { href: "/dashboard/banners",    label: "Banners",           icon: "banners",    tone: "orange" },
  { href: "/dashboard/config",     label: "Raw Config",        icon: "config",     tone: "slate" },
  { href: "/dashboard/analytics",  label: "Analytics",         icon: "analytics",  tone: "cyan" },
  { href: "/dashboard/categories", label: "Azkar Categories",  icon: "categories", tone: "lime" },
  { href: "/dashboard/azkar",      label: "Azkar Library",     icon: "azkar",      tone: "emerald" },
  { href: "/dashboard/onboarding", label: "Onboarding Images", icon: "onboarding", tone: "pink" },
  { href: "/dashboard/notifications", label: "Push Notifications", icon: "notifications", tone: "rose" },
];

function NavIcon({ name, className }: { name: string; className?: string }) {
  const paths = ICONS[name];
  if (!paths) return null;
  return (
    <svg
      className={className ?? "w-5 h-5"}
      fill="none"
      stroke="currentColor"
      strokeWidth={1.5}
      viewBox="0 0 24 24"
    >
      {paths.split(" M").map((d, i) => (
        <path
          key={i}
          strokeLinecap="round"
          strokeLinejoin="round"
          d={i === 0 ? d : "M" + d}
        />
      ))}
    </svg>
  );
}

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [isPending, startTransition] = useTransition();
  const [clickedHref, setClickedHref] = useState("");
  const [dark, setDark] = useState(false);

  useEffect(() => {
    const saved = localStorage.getItem("noor-admin-dark");
    if (saved === "true") setDark(true);
  }, []);

  useEffect(() => {
    document.documentElement.classList.toggle("dark", dark);
    localStorage.setItem("noor-admin-dark", String(dark));
  }, [dark]);

  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      if (!data.user || !ADMIN_EMAILS.has(data.user.email ?? "")) {
        router.replace("/");
        return;
      }
      setUser(data.user);
      setLoading(false);
    });
  }, [router]);

  async function handleLogout() {
    await supabase.auth.signOut();
    router.replace("/");
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin w-8 h-8 border-4 border-teal-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  const currentItem = NAV_ITEMS.find((n) => n.href === pathname);
  const currentLabel = currentItem?.label ?? "Dashboard";
  const currentTone: Tone = currentItem?.tone ?? "teal";
  const currentToneStyle = dark ? TONE_DARK[currentTone] : TONE_LIGHT[currentTone];

  return (
    <div className={`min-h-screen flex ${dark ? "bg-slate-900" : "bg-slate-50"}`}>
      {/* Sidebar overlay for mobile */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black/40 z-30 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`fixed lg:sticky top-0 left-0 h-screen w-[240px] flex flex-col z-40 transition-transform lg:translate-x-0 ${
          sidebarOpen ? "translate-x-0" : "-translate-x-full"
        } ${
          dark
            ? "bg-slate-800 border-r border-slate-700"
            : "bg-white border-r border-slate-200"
        }`}
      >
        {/* Logo — soft gradient backdrop ties the brand into the colorful theme. */}
        <div
          className={`relative px-6 py-5 border-b overflow-hidden ${
            dark ? "border-slate-700" : "border-slate-100"
          }`}
        >
          <div
            className={`absolute inset-0 pointer-events-none ${
              dark
                ? "bg-gradient-to-r from-teal-500/10 via-emerald-500/5 to-transparent"
                : "bg-gradient-to-r from-teal-50 via-emerald-50/60 to-transparent"
            }`}
          />
          <div className="relative flex items-center gap-2.5">
            <div className="w-8 h-8 flex items-center justify-center filter drop-shadow-sm">
              <SabiqLogo size={32} />
            </div>
            <span
              className={`text-lg font-bold tracking-tight ${dark ? "text-white" : "text-slate-800"}`}
              style={{ fontFamily: "Outfit, sans-serif" }}
            >
              Sabiq Admin
            </span>
          </div>
        </div>

        {/* Nav */}
        <nav className="flex-1 overflow-y-auto py-3 px-3 space-y-0.5">
          {NAV_ITEMS.map((item) => {
            const active = pathname === item.href;
            const pending = isPending && clickedHref === item.href;
            const t = dark ? TONE_DARK[item.tone] : TONE_LIGHT[item.tone];
            const dotTone = TONE_LIGHT[item.tone].dot;
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={(e) => {
                  if (pathname === item.href) return;
                  e.preventDefault();
                  setSidebarOpen(false);
                  setClickedHref(item.href);
                  startTransition(() => {
                    router.push(item.href);
                  });
                }}
                className={`group relative flex items-center gap-3 pl-3 pr-3 py-2.5 rounded-lg text-sm transition ${
                  active || pending
                    ? `${t.bg} ${t.text} font-medium`
                    : dark
                      ? "text-slate-400 hover:bg-slate-700/60 hover:text-white"
                      : "text-slate-500 hover:bg-slate-50 hover:text-slate-800"
                }`}
              >
                {/* Always-visible colored dot to give each nav row a hint of its
                    section tone, even when inactive. Subtle but adds life. */}
                <span
                  className={`absolute left-0 top-1/2 -translate-y-1/2 w-1 rounded-r-full transition-all ${
                    active || pending ? `${dotTone} h-6 opacity-100` : `${dotTone} h-3 opacity-40 group-hover:opacity-70`
                  }`}
                />
                <NavIcon name={item.icon} className={`w-5 h-5 ${active || pending ? "" : "opacity-80"}`} />
                {item.label}
                {pending && (
                  <span className={`ml-auto w-3.5 h-3.5 border-2 border-t-transparent rounded-full animate-spin ${t.text}`} style={{ borderTopColor: "transparent" }} />
                )}
              </Link>
            );
          })}
        </nav>

        {/* Footer */}
        <div className={`px-4 py-4 border-t ${dark ? "border-slate-700" : "border-slate-100"}`}>
          <p className={`text-xs truncate mb-2 ${dark ? "text-slate-500" : "text-slate-400"}`}>
            {user?.email}
          </p>
          <button
            onClick={handleLogout}
            className="text-xs text-red-500 hover:text-red-400 cursor-pointer"
          >
            Sign out
          </button>
        </div>
      </aside>

      {/* Main content */}
      <div className="flex-1 min-w-0">
        {/* Top bar */}
        <header className={`sticky top-0 z-20 backdrop-blur border-b px-6 py-4 flex items-center gap-4 ${
          dark
            ? "bg-slate-900/80 border-slate-700"
            : "bg-white/80 border-slate-200"
        }`}>
          <button
            onClick={() => setSidebarOpen(true)}
            className={`lg:hidden cursor-pointer ${dark ? "text-slate-400" : "text-slate-600"}`}
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
          <div className="flex-1 flex items-center gap-2.5 min-w-0">
            {/* Colored section chip — mirrors the active nav row tone so users
                always know which area they're in. */}
            <span
              className={`hidden sm:inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ring-1 ${currentToneStyle.bg} ${currentToneStyle.text} ${currentToneStyle.ring}`}
            >
              <span className={`w-1.5 h-1.5 rounded-full ${TONE_LIGHT[currentTone].dot}`} />
              {currentLabel}
            </span>
            <h1 className={`text-lg font-semibold truncate ${dark ? "text-white" : "text-slate-800"}`}>
              {currentLabel}
            </h1>
          </div>
          {/* Dark mode toggle */}
          <button
            onClick={() => setDark(!dark)}
            className={`w-9 h-9 rounded-lg flex items-center justify-center cursor-pointer transition ${
              dark
                ? "bg-slate-700 text-yellow-400 hover:bg-slate-600"
                : "bg-slate-100 text-slate-500 hover:bg-slate-200"
            }`}
            title={dark ? "Switch to light mode" : "Switch to dark mode"}
          >
            {dark ? (
              <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 3v2.25m6.364.386l-1.591 1.591M21 12h-2.25m-.386 6.364l-1.591-1.591M12 18.75V21m-4.773-4.227l-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0z" />
              </svg>
            ) : (
              <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M21.752 15.002A9.718 9.718 0 0118 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 003 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 009.002-5.998z" />
              </svg>
            )}
          </button>
        </header>

        {/* Page content */}
        <main className="p-6">
          <ConfigProvider>{children}</ConfigProvider>
        </main>
      </div>
    </div>
  );
}
