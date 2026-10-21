"use client";

import Image from "next/image";
import Link from "next/link";
import { useCallback, useEffect, useRef, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { AiAssistant } from "@/components/ai-assistant";
import { ProductIcon } from "@/components/product-icon";
import { ThemeToggle } from "@/components/theme-toggle";
import { apiMutation, apiRequest } from "@/lib/api";
import type { Session } from "@/types/api";
import type { ToastPayload } from "@/lib/toast";

const navigation = [
  ["/app/dashboard", "Dashboard", "dashboard"],
  ["/app/invoices", "Invoices", "invoices"],
  ["/app/customers", "Customers", "customers"],
  ["/app/collections", "Collections", "collections"],
  ["/app/reports", "Reports", "reports"],
  ["/app/billing", "Plans & usage", "sparkle"],
  ["/app/personal", "Personal dues", "invoices"],
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
  const [accountOpen, setAccountOpen] = useState(false);
  const [toast, setToast] = useState<(ToastPayload & { id: number }) | null>(null);
  const accountMenuRef = useRef<HTMLDivElement>(null);
  const lastPlanRef = useRef("");
  const toastTimerRef = useRef<number | null>(null);

  const announce = useCallback((payload: ToastPayload) => {
    if (toastTimerRef.current) window.clearTimeout(toastTimerRef.current);
    setToast({ ...payload, id: Date.now() });
    toastTimerRef.current = window.setTimeout(() => setToast(null), payload.duration ?? 5600);
  }, []);

  const applySession = useCallback((next: Session, announceTransition = true) => {
    const nextPlan = next.access?.plan || next.user.plan || "free";
    const previousPlan = lastPlanRef.current;
    if (announceTransition && previousPlan && previousPlan !== nextPlan && previousPlan !== "free" && nextPlan === "free") {
      announce({ tone: "warning", title: "Test entitlement expired", message: "Your access returned to Free and a fresh token claim was issued." });
    }
    lastPlanRef.current = nextPlan;
    setSession(next);
  }, [announce]);

  useEffect(() => {
    const savedTheme = localStorage.getItem("duepilot-theme") === "dark" ? "dark" : "light";
    document.documentElement.dataset.theme = savedTheme;

    let active = true;
    apiRequest<Session>("/auth/me").then((result) => {
      if (!active) return;
      if (result.ok) {
        if (result.data.user.isPlatformAdmin) router.replace("/admin");
        else applySession(result.data, false);
      }
      else router.replace("/login");
      setAuthLoading(false);
    });

    return () => { active = false; };
  }, [applySession, router]);

  useEffect(() => {
    function onToast(event: Event) {
      const payload = (event as CustomEvent<ToastPayload>).detail;
      if (!payload) return;
      if (payload.session) applySession(payload.session, false);
      announce(payload);
    }
    window.addEventListener("duepilot:toast", onToast);
    return () => window.removeEventListener("duepilot:toast", onToast);
  }, [announce, applySession]);

  useEffect(() => {
    if (!session) return;
    const timer = window.setInterval(async () => {
      const result = await apiRequest<Session>("/auth/me");
      if (result.ok) applySession(result.data);
      else if (result.error.code === "AUTHENTICATION_REQUIRED") router.replace("/login");
    }, 10000);
    return () => window.clearInterval(timer);
  }, [applySession, router, session]);

  useEffect(() => () => {
    if (toastTimerRef.current) window.clearTimeout(toastTimerRef.current);
  }, []);

  useEffect(() => {
    if (!accountOpen) return;
    function closeAccountMenu(event: PointerEvent) {
      if (!accountMenuRef.current?.contains(event.target as Node)) setAccountOpen(false);
    }
    document.addEventListener("pointerdown", closeAccountMenu);
    return () => document.removeEventListener("pointerdown", closeAccountMenu);
  }, [accountOpen]);

  async function logout() {
    setAccountOpen(false);
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
      const current = await apiRequest<Session>("/auth/me");
      if (current.ok) applySession(current.data);
    } else if (result.error.code === "AUTHENTICATION_REQUIRED") {
      router.replace("/login");
    } else {
      setSessionMessage(result.error.message);
    }
    setRefreshingSession(false);
  }

  const isActive = (href: string) => pathname === href || (href !== "/app/dashboard" && pathname.startsWith(`${href}/`));

  if (authLoading) {
    return <div className="app-loading"><div><span className="loading-mark" aria-hidden="true"><Image src="/duepilot-reference.png" alt="" width={789} height={768} priority /></span><strong>Preparing your workspace</strong><small>Confirming your secure session…</small></div></div>;
  }

  if (!session) return null;

  return <div className="app-shell">
    {sidebarOpen && <button className="sidebar-scrim" aria-label="Close navigation" onClick={() => setSidebarOpen(false)} />}
    <aside className={`app-sidebar ${sidebarOpen ? "open" : ""}`}>
      <Link href="/app/dashboard" className="workspace-brand-lockup" aria-label="DuePilot dashboard">
        <span className="workspace-brand-mark" aria-hidden="true">
          <Image className="workspace-brand-image" src="/duepilot-reference.png" alt="" width={789} height={768} priority />
        </span>
        <span className="workspace-brand-copy"><strong>DuePilot</strong><small>Receivables workspace</small></span>
      </Link>
      <div className="workspace-card"><span>{session.workspace.initials}</span><div><strong>{session.workspace.name}</strong><small>{session.access?.plan || session.workspace.plan} workspace</small></div><i aria-hidden="true">⌄</i></div>
      <nav aria-label="Workspace navigation">
        <small>OPERATIONS</small>
        {navigation.slice(0, 4).map(([href, label, icon]) => <Link key={href} href={href} onClick={() => setSidebarOpen(false)} className={isActive(href) ? "active" : ""}><ProductIcon name={icon} /><span>{label}</span></Link>)}
        <small>INTELLIGENCE</small>
        {navigation.slice(4, 6).map(([href, label, icon]) => <Link key={href} href={href} onClick={() => setSidebarOpen(false)} className={isActive(href) ? "active" : ""}><ProductIcon name={icon} /><span>{label}</span></Link>)}
        <small>ACCOUNT</small>
        {navigation.slice(6).map(([href, label, icon]) => <Link key={href} href={href} onClick={() => setSidebarOpen(false)} className={isActive(href) ? "active" : ""}><ProductIcon name={icon} /><span>{label}</span></Link>)}
        <Link href="/app/settings" onClick={() => setSidebarOpen(false)} className={isActive("/app/settings") ? "active" : ""}><ProductIcon name="settings" /><span>Settings</span></Link>
      </nav>
      <Link href="/" className="sidebar-public-link"><span aria-hidden="true">←</span> Back to public site</Link>
      <Link href="/app/profile" className="sidebar-user" onClick={() => setSidebarOpen(false)}><span>{session.user.initials}</span><div><strong>{session.user.name}</strong><small>{session.user.role} · View profile</small></div><b aria-hidden="true">↗</b></Link>
    </aside>
    <section className="app-main">
      <header className="app-topbar">
        <button className="mobile-menu" aria-label="Open navigation" aria-expanded={sidebarOpen} onClick={() => setSidebarOpen(true)}><ProductIcon name="menu" /> Menu</button>
        <Link href="/app/dashboard" className="mobile-brand" aria-label="DuePilot dashboard"><span className="workspace-brand-mark" aria-hidden="true"><Image className="workspace-brand-image" src="/duepilot-reference.png" alt="" width={789} height={768} priority /></span><strong>DuePilot</strong></Link>
        <label className="global-search"><ProductIcon name="search" /><input aria-label="Search workspace" placeholder="Search invoices, customers…" onKeyDown={(event) => { if (event.key === "Enter") { const value = event.currentTarget.value.trim(); router.push(value ? `/app/invoices?search=${encodeURIComponent(value)}` : "/app/invoices"); } }} /><kbd>⌘ K</kbd></label>
        <div className="topbar-actions"><ThemeToggle /><button className="ai-button" onClick={() => setAssistantOpen(true)}><ProductIcon name="sparkle" /> Ask DuePilot</button><div className="account-menu" ref={accountMenuRef}><button className="topbar-account" type="button" aria-expanded={accountOpen} aria-haspopup="menu" onClick={() => setAccountOpen((open) => !open)}><span className="topbar-account-avatar">{session.user.initials}</span><span className="topbar-account-copy"><strong>{session.user.name}</strong><small>{session.access?.plan || session.workspace.plan} plan</small></span><span className="topbar-account-chevron" aria-hidden="true">⌄</span></button>{accountOpen && <div className="account-popover" role="menu"><div className="account-popover-heading"><span className="topbar-account-avatar">{session.user.initials}</span><div><strong>{session.user.name}</strong><small>{session.user.email}</small></div></div><div className="account-popover-divider" />{sessionMessage && <div className="account-feedback" role="status">{sessionMessage}</div>}<Link href="/app/profile" role="menuitem" onClick={() => setAccountOpen(false)}>Profile</Link><Link href="/app/settings" role="menuitem" onClick={() => setAccountOpen(false)}>Workspace settings</Link><button type="button" role="menuitem" onClick={refreshSession} disabled={refreshingSession}><span>{refreshingSession ? "Refreshing session…" : "Refresh session"}</span><small>Keep your secure access active</small></button><div className="account-popover-divider" /><button className="account-signout" type="button" role="menuitem" onClick={() => void logout()}>Sign out</button></div>}</div></div>
      </header>
      {children}
    </section>
    <AiAssistant open={assistantOpen} onClose={() => setAssistantOpen(false)} />
    {toast && <div className={`duepilot-toast duepilot-toast-${toast.tone}`} role="status" aria-live="polite"><span className="duepilot-toast-icon" aria-hidden="true">{toast.tone === "success" ? "✓" : toast.tone === "warning" ? "!" : toast.tone === "error" ? "×" : "i"}</span><span><strong>{toast.title}</strong><small>{toast.message}</small></span><button type="button" onClick={() => setToast(null)} aria-label="Dismiss notification">×</button></div>}
  </div>;
}
