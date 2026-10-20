"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ProductIcon } from "@/components/product-icon";
import { apiRequest } from "@/lib/api";
import type { Dashboard, WorkspaceContext } from "@/types/api";

const money = new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 });

function DashboardSkeleton() {
  return <div className="product-page"><div className="skeleton heading-skeleton" /><div className="metric-grid">{[1, 2, 3, 4].map((item) => <div className="metric-card skeleton-card" key={item}><i className="skeleton" /><b className="skeleton" /><span className="skeleton" /></div>)}</div></div>;
}

export default function DashboardPage() {
  const router = useRouter();
  const [dashboard, setDashboard] = useState<Dashboard | null>(null);
  const [context, setContext] = useState<WorkspaceContext | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;
    Promise.all([apiRequest<Dashboard>("/dashboard"), apiRequest<WorkspaceContext>("/workspace/context")]).then(([result, contextResult]) => {
      if (!active) return;
      if (!result.ok) {
        if (result.error.code === "AUTHENTICATION_REQUIRED") router.replace("/login");
        else setError(result.error.message);
        return;
      }
      setDashboard(result.data);
      if (contextResult.ok) setContext(contextResult.data);
    });
    return () => { active = false; };
  }, [router]);

  if (!dashboard && !error) return <DashboardSkeleton />;
  if (error) return <main className="product-page"><div className="error-state"><span>!</span><h1>Dashboard unavailable</h1><p>{error}</p><button className="button button-primary" onClick={() => location.reload()}>Try again</button></div></main>;
  if (!dashboard) return null;

  const metrics = [
    ["Open receivables", dashboard.outstanding, `${dashboard.priorityInvoices.length} invoices in the collection queue`, "blue"],
    ["Needs attention", dashboard.overdueAmount, `${dashboard.overdueCount} overdue invoice${dashboard.overdueCount === 1 ? "" : "s"}`, "rose"],
    ["Due this week", dashboard.dueSoonAmount, "Plan the next seven days of follow-up", "amber"],
    ["Collected", dashboard.collectedAmount, `${dashboard.collectionRate}% collection rate`, "green"],
  ] as const;
  const openRisk = dashboard.outstanding ? Math.round((dashboard.overdueAmount / dashboard.outstanding) * 100) : 0;

  return <main className="product-page">
    <div className="page-heading dashboard-heading"><div><span className="page-eyebrow">{context?.sector.recordLabel || "Receivables"} command center</span><h1>A clear view of your cash.</h1><p>{dashboard.organization.name} has <strong>{dashboard.priorityInvoices.length} priority actions</strong> ready today. {context?.sector.description}</p></div><div className="heading-actions"><span className="live-context"><i /> {context?.sector.partyLabel || "Customer"} workflow live</span><Link className="button button-primary" href="/app/invoices">Create {context?.sector.recordLabel || "invoice"} <ProductIcon name="arrow" /></Link></div></div>

    <section className="metric-grid" aria-label="Key receivables metrics">
      {metrics.map(([label, value, detail, tone]) => <article className={`metric-card ${tone}`} key={label}><div><span>{label}</span><i><ProductIcon name={tone === "green" ? "check" : tone === "rose" ? "collections" : "arrow"} /></i></div><strong>{money.format(value)}</strong><p>{detail}</p></article>)}
    </section>

    <div className="dashboard-grid">
      <section className="panel collection-queue"><header><div><span className="section-kicker">Focus list</span><h2>Collection queue</h2><p>The balances most worth moving today.</p></div><Link href="/app/collections">Open queue <ProductIcon name="arrow" /></Link></header><div className="queue-table"><div className="table-head"><span>Priority</span><span>Customer & invoice</span><span>Recommended focus</span><span>Open balance</span></div>{dashboard.priorityInvoices.map((invoice, index) => <Link href={`/app/invoices/${invoice.id}`} className="table-row" key={invoice.id}><span className={`priority-number ${index < 2 ? "high" : "normal"}`}>{String(index + 1).padStart(2, "0")}</span><span><b>{invoice.customerName}</b><small>{invoice.invoiceNumber} · due {invoice.dueDate}</small></span><span><em className={`status ${invoice.status}`}>{invoice.status.replace(/_/g, " ")}</em><small>{invoice.daysOverdue > 0 ? `${invoice.daysOverdue} days overdue` : `Due in ${invoice.daysUntilDue} days`}</small></span><strong>{money.format(invoice.outstanding)}<ProductIcon name="arrow" /></strong></Link>)}</div></section>

      <section className="panel attention-card"><header><div><span className="section-kicker">Risk lens</span><h2>Open-balance health</h2></div><Link href="/app/reports" aria-label="Open reports"><ProductIcon name="arrow" /></Link></header><div className="risk-score"><div><strong>{openRisk}%</strong><span>of open receivables are overdue</span></div><i><b style={{ width: `${Math.max(openRisk, 3)}%` }} /></i></div><div className="aging-list">{[["Current", dashboard.aging.current, "current"], ["1–30 days", dashboard.aging.oneToThirty, "one"], ["31–60 days", dashboard.aging.thirtyOneToSixty, "two"], ["60+ days", dashboard.aging.overSixty, "three"]].map(([label, value, tone]) => <span key={label as string}><i className={tone as string} /><b>{label}</b><em>{money.format(value as number)}</em></span>)}</div></section>

      <section className="panel forecast-panel"><header><div><span className="section-kicker">Expected cash</span><h2>Forecast confidence</h2><p>Expected payment timing from current invoice activity.</p></div></header><div className="forecast-list">{dashboard.forecast.map((item) => <div key={item.label}><span><b>{item.label}</b><small>{item.confidence}% confidence</small></span><strong>{money.format(item.amount)}</strong><i><b style={{ width: `${item.confidence}%` }} /></i></div>)}</div></section>

      <section className="panel activity-panel"><header><div><span className="section-kicker">Latest activity</span><h2>What changed</h2></div></header><div className="activity-list">{dashboard.recentActivity.map((item, index) => <div key={`${item.title}-${index}`}><span>{item.kind === "payment" ? "₹" : item.kind === "promise" ? "✓" : "↗"}</span><p><b>{item.title}</b><small>{item.detail}</small></p><time>{item.at}</time></div>)}</div></section>
    </div>
  </main>;
}
