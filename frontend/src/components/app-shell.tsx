"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { AiAssistant } from "@/components/ai-assistant";
import { ProductIcon } from "@/components/product-icon";
import { ThemeToggle } from "@/components/theme-toggle";
import { apiMutation, apiRequest } from "@/lib/api";
import type { Session } from "@/types/api";

const navigation = [
  ["/app/dashboard", "Dashboard", "dashboard"],
  ["/app/invoices", "Invoices", "invoices"],
  ["/app/customers", "Customers", "customers"],
  ["/app/collections", "Collections", "collections"],
  ["/app/reports", "Reports", "reports"],
  ["/app/profile", "Profile", "settings"],
] as const;

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [assistantOpen, setAssistantOpen] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [session, setSession] = useState<Session | null>(null);
  const [authLoading, setAuthLoading] = useState(true);
  const [refreshingSession, setRefreshingSession] = useState(false);
  const [sessionMessage, setSessionMessage] = useState("");

  useEffect(() => {
    const savedTheme = localStorage.getItem("duepilot-theme") === "dark" ? "dark" : "light";
    document.documentElement.dataset.theme = savedTheme;

    let active = true;
    apiRequest<Session>("/auth/me").then((result) => {
      if (!active) return;
      if (result.ok) {
        if (result.data.user.isPlatformAdmin) router.replace("/admin");
        else setSession(result.data);
      }
      else router.replace("/login");
      setAuthLoading(false);
    });

    return () => { active = false; };
  }, [router]);

  async function logout() {
    await apiMutation<{ signedOut: boolean }>("/auth/logout", {});
    router.replace("/login");
    router.refresh();
  }

  async function refreshSession() {
    setRefreshingSession(true);
    setSessionMessage("");
    const result = await apiRequest<{ refreshed: boolean; accessIn: number; refreshIn: number }>("/auth/refresh", { method: "POST" });
    if (result.ok) {
      setSessionMessage("Session refreshed");
    } else if (result.error.code === "AUTHENTICATION_REQUIRED") {
      router.replace("/login");
    } else {
      setSessionMessage(result.error.message);
    }
    setRefreshingSession(false);
  }

  const isActive = (href: string) => pathname === href || (href !== "/app/dashboard" && pathname.startsWith(`${href}/`));

  if (authLoading) {
    return <div className="app-loading"><div><span className="loading-mark">DP</span><strong>Preparing your workspace</strong><small>Confirming your secure session…</small></div></div>;
  }

  if (!session) return null;

  return <div className="app-shell">
    {sidebarOpen && <button className="sidebar-scrim" aria-label="Close navigation" onClick={() => setSidebarOpen(false)} />}
    <aside className={`app-sidebar ${sidebarOpen ? "open" : ""}`}>
      <Link href="/app/dashboard" className="sidebar-logo" aria-label="DuePilot dashboard">
        <Image src="/duepilot-logo.svg" alt="DuePilot" width={116} height={83} priority />
      </Link>
      <div className="workspace-card"><span>{session.workspace.initials}</span><div><strong>{session.workspace.name}</strong><small>{session.workspace.plan} workspace</small></div><i aria-hidden="true">⌄</i></div>
      <nav aria-label="Workspace navigation">
        <small>OPERATIONS</small>
        {navigation.slice(0, 4).map(([href, label, icon]) => <Link key={href} href={href} onClick={() => setSidebarOpen(false)} className={isActive(href) ? "active" : ""}><ProductIcon name={icon} /><span>{label}</span></Link>)}
        <small>INTELLIGENCE</small>
        {navigation.slice(4).map(([href, label, icon]) => <Link key={href} href={href} onClick={() => setSidebarOpen(false)} className={isActive(href) ? "active" : ""}><ProductIcon name={icon} /><span>{label}</span></Link>)}
        <Link href="/app/settings" onClick={() => setSidebarOpen(false)} className={isActive("/app/settings") ? "active" : ""}><ProductIcon name="settings" /><span>Settings</span></Link>
      </nav>
      <Link href="/" className="sidebar-public-link"><span aria-hidden="true">←</span> Back to public site</Link>
      <div className="sidebar-user"><span>{session.user.initials}</span><div><strong>{session.user.name}</strong><small>{session.user.role}</small></div><button onClick={logout} aria-label="Sign out of DuePilot">Sign out</button></div>
    </aside>
    <section className="app-main">
      <header className="app-topbar">
        <button className="mobile-menu" aria-label="Open navigation" aria-expanded={sidebarOpen} onClick={() => setSidebarOpen(true)}><ProductIcon name="menu" /> Menu</button>
        <label className="global-search"><ProductIcon name="search" /><input aria-label="Search workspace" placeholder="Search invoices, customers…" onKeyDown={(event) => { if (event.key === "Enter") { const value = event.currentTarget.value.trim(); router.push(value ? `/app/invoices?search=${encodeURIComponent(value)}` : "/app/invoices"); } }} /><kbd>⌘ K</kbd></label>
        <div className="topbar-actions"><span className="sync-state"><i /> <span>Session protected</span></span><button className="session-refresh" onClick={refreshSession} disabled={refreshingSession} title="Refresh the secure session"><span aria-hidden="true">↻</span><span>{refreshingSession ? "Refreshing" : "Refresh session"}</span></button>{sessionMessage && <span className="session-message" role="status">{sessionMessage}</span>}<ThemeToggle /><button className="ai-button" onClick={() => setAssistantOpen(true)}><ProductIcon name="sparkle" /> Ask DuePilot</button></div>
      </header>
      {children}
    </section>
    <AiAssistant open={assistantOpen} onClose={() => setAssistantOpen(false)} />
  </div>;
}
