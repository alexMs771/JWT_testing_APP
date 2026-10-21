"use client";

import Image from "next/image";
import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { ThemeToggle } from "@/components/theme-toggle";
import { apiMutation, apiRequest } from "@/lib/api";
import type { AdminOverview, Session } from "@/types/api";

function initials(value: string) {
  return value
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0])
    .join("")
    .toUpperCase() || "DP";
}

function titleCase(value: string) {
  return value ? value.charAt(0).toUpperCase() + value.slice(1) : "Business";
}

export default function AdminPage() {
  const router = useRouter();
  const [overview, setOverview] = useState<AdminOverview | null>(null);
  const [error, setError] = useState("");
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [busyId, setBusyId] = useState("");

  const load = useCallback(async () => {
    setRefreshing(true);
    setError("");
    const session = await apiRequest<Session>("/auth/me");
    if (!session.ok || !session.data.user.isPlatformAdmin) {
      router.replace("/login");
      return;
    }
    const result = await apiRequest<AdminOverview>("/admin/overview");
    if (result.ok) setOverview(result.data);
    else setError(result.error.message);
    setLoading(false);
    setRefreshing(false);
  }, [router]);

  useEffect(() => {
    const timer = window.setTimeout(() => { void load(); }, 0);
    return () => window.clearTimeout(timer);
  }, [load]);

  const visibleWorkspaces = useMemo(() => {
    if (!overview) return [];
    const term = query.trim().toLowerCase();
    if (!term) return overview.workspaces;
    return overview.workspaces.filter((workspace) => [
      workspace.name,
      workspace.slug,
      workspace.email,
      workspace.organizationType || "",
      workspace.plan || "",
    ].some((value) => value.toLowerCase().includes(term)));
  }, [overview, query]);

  async function deleteWorkspace(id: string, name: string) {
    if (!window.confirm(`Permanently delete ${name}? This removes all of its data.`)) return;
    setBusyId(id);
    setError("");
    const result = await apiMutation<{ deleted: boolean }>(`/admin/workspaces/${id}/delete`, {});
    setBusyId("");
    if (result.ok) void load();
    else setError(result.error.message);
  }

  async function signOut() {
    await apiMutation<{ signedOut: boolean }>("/auth/logout", {});
    router.replace("/login");
  }

  if (loading) {
    return <main className="admin-page"><div className="admin-loading"><span className="admin-loading-mark">D</span><strong>Preparing the admin console</strong><small>Checking your protected platform session…</small></div></main>;
  }

  if (!overview) {
    return <main className="admin-page"><div className="admin-error-state"><span className="admin-alert-mark">!</span><span className="page-eyebrow">Platform console</span><h1>We couldn’t load your overview.</h1><p>{error || "The platform service did not return a usable response."}</p><div><button className="button button-primary" onClick={() => { setLoading(true); void load(); }}>Try again</button><Link className="button button-secondary" href="/">Back to public site</Link></div></div></main>;
  }

  const metrics = [
    { label: "Workspaces", value: overview.metrics.workspaceCount, detail: "Total tenant records", tone: "blue" },
    { label: "Active users", value: overview.metrics.userCount, detail: "Accounts with access", tone: "teal" },
    { label: "Successful logins", value: overview.metrics.loginsToday, detail: "Last 24 hours", tone: "violet" },
    { label: "Invoices stored", value: overview.metrics.invoiceCount, detail: "Across all workspaces", tone: "amber" },
  ];

  return <main className="admin-page">
    <header className="admin-header">
      <Link href="/admin" className="admin-brand" aria-label="DuePilot admin home"><Image src="/duepilot-logo.svg" alt="DuePilot" width={136} height={96} priority /><span>Platform control</span></Link>
      <div className="admin-header-actions"><span className="admin-secure-chip"><i /> Protected console</span><ThemeToggle /><button className="admin-signout" onClick={signOut}>Sign out</button></div>
    </header>

    <section className="admin-content">
      <div className="admin-hero">
        <div><span className="page-eyebrow">Platform overview</span><h1>Operate DuePilot with confidence.</h1><p>See tenant health, usage, and sign-in activity from one protected control plane.</p></div>
        <div className="admin-hero-actions"><span className="admin-live-state"><i /> Live data</span><button className="button button-secondary" onClick={() => void load()} disabled={refreshing}>{refreshing ? "Refreshing…" : "Refresh overview"}</button></div>
      </div>

      {error && <div className="admin-inline-error" role="alert"><strong>Couldn’t refresh the overview.</strong><span>{error}</span><button onClick={() => setError("")} aria-label="Dismiss error">×</button></div>}

      <div className="admin-metrics">{metrics.map((metric) => <article className={`admin-metric-card ${metric.tone}`} key={metric.label}><span className="admin-metric-icon" aria-hidden="true" /><span className="admin-metric-label">{metric.label}</span><strong>{metric.value.toLocaleString("en-IN")}</strong><small>{metric.detail}</small></article>)}</div>

      <section className="admin-panel admin-workspaces-panel"><header><div><span className="section-kicker">Tenant operations</span><h2>Workspace directory</h2><p>Review every organization, plan, and recent activity.</p></div><span className="admin-result-count">{visibleWorkspaces.length} of {overview.workspaces.length}</span></header><div className="admin-toolbar"><label className="admin-search"><span aria-hidden="true">⌕</span><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search workspace, email, plan…" aria-label="Search workspaces" />{query && <button onClick={() => setQuery("")} aria-label="Clear search">×</button>}</label><span className="admin-toolbar-note">Updates on refresh</span></div><div className="admin-table">{visibleWorkspaces.length > 0 ? <><div className="admin-table-head"><span>Workspace</span><span>Owner / plan</span><span>Created</span><span>Members</span><span>Invoices</span><span>Last active</span><span /></div>{visibleWorkspaces.map((workspace) => <div className="admin-table-row" key={workspace.id}><span className="admin-workspace-name"><i>{initials(workspace.name)}</i><span><b>{workspace.name}</b><small>{titleCase(workspace.organizationType || "business")} · {workspace.slug}</small></span></span><span className="admin-owner"><b>{workspace.email || "Not set"}</b><small className={`admin-plan ${workspace.plan || "free"}`}>{titleCase(workspace.plan || "free")} plan</small></span><span>{workspace.createdAt}</span><span>{workspace.memberCount}</span><span>{workspace.invoiceCount}</span><span>{workspace.lastLogin}<small>{workspace.usage30d} actions / 30d</small></span><button className="text-danger" disabled={busyId === workspace.id} onClick={() => deleteWorkspace(workspace.id, workspace.name)}>{busyId === workspace.id ? "Deleting…" : "Delete"}</button></div>)}</> : <div className="admin-empty"><span>⌕</span><strong>No workspaces match “{query}”.</strong><small>Try a different workspace, email, sector, or plan.</small></div>}</div></section>

      <section className="admin-panel"><header><div><span className="section-kicker">Authentication audit</span><h2>Recent access events</h2><p>The latest platform sign-ins and sign-outs.</p></div><span className="admin-result-count">{overview.loginEvents.length} events</span></header><div className="admin-events">{overview.loginEvents.length > 0 ? overview.loginEvents.map((event, index) => <div key={`${event.email}-${event.at}-${index}`}><span className={event.outcome}>{event.outcome}</span><span className="admin-event-person"><b>{event.name}</b><small>{event.email}</small></span><time>{event.at}</time></div>) : <div className="admin-empty"><span>✓</span><strong>No access events yet.</strong><small>Authentication activity will appear here.</small></div>}</div></section>
    </section>
  </main>;
}
