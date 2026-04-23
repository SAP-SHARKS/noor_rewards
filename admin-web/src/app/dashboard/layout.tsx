"use client";

import { useEffect, useState, useTransition } from "react";
import { useRouter, usePathname } from "next/navigation";
import Link from "next/link";
import { supabase, ADMIN_EMAILS } from "@/lib/supabase";
import { ConfigProvider } from "@/lib/config-context";
import type { User } from "@supabase/supabase-js";

const NAV_ITEMS = [
  { href: "/dashboard", label: "Overview", icon: "📊" },
  { href: "/dashboard/economy", label: "Economy", icon: "💰" },
  { href: "/dashboard/theme", label: "Theme & Colors", icon: "🎨" },
  { href: "/dashboard/projects", label: "Projects", icon: "🏗️" },
  { href: "/dashboard/users", label: "Users", icon: "👥" },
  { href: "/dashboard/features", label: "Feature Flags", icon: "🚀" },
  { href: "/dashboard/banners", label: "Banners", icon: "📢" },
  { href: "/dashboard/config", label: "Raw Config", icon: "⚙️" },
  { href: "/dashboard/analytics", label: "Analytics", icon: "📈" },
  { href: "/dashboard/categories", label: "Azkar Categories", icon: "📿" },
];

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

  const currentLabel =
    NAV_ITEMS.find((n) => n.href === pathname)?.label ?? "Dashboard";

  return (
    <div className="min-h-screen flex bg-slate-50">
      {/* Sidebar overlay for mobile */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black/40 z-30 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`fixed lg:sticky top-0 left-0 h-screen w-[240px] bg-[#0F172A] text-white flex flex-col z-40 transition-transform lg:translate-x-0 ${
          sidebarOpen ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        {/* Logo */}
        <div className="px-6 py-5 border-b border-white/10">
          <div className="flex items-center gap-2">
            <span className="text-2xl">🌙</span>
            <span className="text-lg font-bold tracking-tight">NoorAdmin</span>
          </div>
        </div>

        {/* Nav */}
        <nav className="flex-1 overflow-y-auto py-3 px-3 space-y-0.5">
          {NAV_ITEMS.map((item) => {
            const active = pathname === item.href;
            const pending = isPending && clickedHref === item.href;
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
                className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition ${
                  active || pending
                    ? "bg-teal-600/20 text-teal-400 font-medium"
                    : "text-slate-400 hover:bg-white/5 hover:text-white"
                }`}
              >
                <span className="text-base">{item.icon}</span>
                {item.label}
                {pending && (
                  <span className="ml-auto w-3.5 h-3.5 border-2 border-teal-400 border-t-transparent rounded-full animate-spin" />
                )}
              </Link>
            );
          })}
        </nav>

        {/* Footer */}
        <div className="px-4 py-4 border-t border-white/10">
          <p className="text-xs text-slate-500 truncate mb-2">
            {user?.email}
          </p>
          <button
            onClick={handleLogout}
            className="text-xs text-red-400 hover:text-red-300 cursor-pointer"
          >
            Sign out
          </button>
        </div>
      </aside>

      {/* Main content */}
      <div className="flex-1 min-w-0">
        {/* Top bar */}
        <header className="sticky top-0 z-20 bg-white/80 backdrop-blur border-b border-slate-200 px-6 py-4 flex items-center gap-4">
          <button
            onClick={() => setSidebarOpen(true)}
            className="lg:hidden text-slate-600 cursor-pointer"
          >
            <svg
              className="w-6 h-6"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M4 6h16M4 12h16M4 18h16"
              />
            </svg>
          </button>
          <h1 className="text-lg font-semibold text-slate-800">
            {currentLabel}
          </h1>
        </header>

        {/* Page content */}
        <main className="p-6">
            <ConfigProvider>{children}</ConfigProvider>
          </main>
      </div>
    </div>
  );
}
