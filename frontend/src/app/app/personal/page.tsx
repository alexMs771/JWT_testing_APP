"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { ProductIcon } from "@/components/product-icon";
import { apiMutation, apiRequest } from "@/lib/api";
import type { PersonalObligation, PersonalProfile, PersonalSummary } from "@/types/api";

const money = new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 });
type Period = "all" | "past" | "current" | "next";

function dateValue(value: string) {
  return new Date(`${value}T00:00:00`);
}

function periodMatch(value: string, period: Period) {
  if (period === "all") return true;
  const date = dateValue(value);
  const now = new Date();
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  if (period === "past") return date < monthStart;
  if (period === "current") return date.getFullYear() === now.getFullYear() && date.getMonth() === now.getMonth();
  const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  return date.getFullYear() === nextMonth.getFullYear() && date.getMonth() === nextMonth.getMonth();
}

function statusText(obligation: PersonalObligation) {
  if (obligation.status === "paid") return "Paid";
  if (obligation.status === "overdue") return `${obligation.daysOverdue} day${obligation.daysOverdue === 1 ? "" : "s"} overdue`;
  if (obligation.daysUntilDue === 0) return "Due today";
  if (obligation.daysUntilDue > 0) return `Due in ${obligation.daysUntilDue} days`;
  return "Needs attention";
}

function Metric({ label, value, hint, tone }: { label: string; value: string; hint: string; tone: string }) {
  return <article className={`metric-card personal-metric ${tone}`}><span>{label}</span><strong>{value}</strong><p>{hint}</p></article>;
}

export default function PersonalDuesPage() {
  const router = useRouter();
  const [data, setData] = useState<PersonalSummary | null>(null);
  const [period, setPeriod] = useState<Period>("current");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [showAdd, setShowAdd] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    let active = true;
    apiRequest<PersonalSummary>("/personal/summary").then((result) => {
      if (!active) return;
      if (result.ok) setData(result.data);
      else if (result.error.code === "AUTHENTICATION_REQUIRED") router.replace("/login");
      else setError(result.error.message);
      setLoading(false);
    });
    return () => { active = false; };
  }, [router]);

  const visible = useMemo(() => data?.obligations.filter((item) => periodMatch(item.dueDate, period)) || [], [data, period]);

  async function saveProfile(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setNotice("");
    const form = new FormData(event.currentTarget);
    const displayName = String(form.get("displayName") || "").trim();
    const mobile = String(form.get("mobile") || "").trim();
    if (displayName.length < 2) { setError("Enter your name so personal activity has a clear owner."); return; }
    setSaving(true);
    const result = await apiMutation<PersonalProfile>("/personal/profile", { displayName, mobile });
    setSaving(false);
    if (!result.ok) { setError(result.error.message); return; }
    setData((current) => current ? { ...current, profile: result.data } : current);
    setNotice(result.data.mobileVerified ? "Personal profile updated." : "Personal profile saved. Mobile verification is required before live bill sync.");
  }

  async function addObligation(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setNotice("");
    setSaving(true);
    const form = new FormData(event.currentTarget);
    const result = await apiMutation<PersonalSummary>("/personal/obligations", {
      providerName: form.get("providerName"),
      category: form.get("category"),
      title: form.get("title"),
      externalReference: form.get("externalReference"),
      amount: Number(form.get("amount")),
      issueDate: form.get("issueDate"),
      dueDate: form.get("dueDate"),
      currency: form.get("currency"),
    });
    setSaving(false);
    if (!result.ok) { setError(result.error.message); return; }
    setData(result.data);
    setShowAdd(false);
    setNotice("Due added to your personal payment plan.");
    event.currentTarget.reset();
  }

  if (loading) return <main className="product-page"><div className="skeleton heading-skeleton" /><div className="metric-grid">{[1, 2, 3, 4].map((item) => <div className="metric-card skeleton-card" key={item}><i className="skeleton" /><b className="skeleton" /><span className="skeleton" /></div>)}</div></main>;
  if (!data) return <main className="product-page"><div className="error-state"><span>!</span><h1>Personal workspace unavailable</h1><p>{error || "We could not load your personal dues."}</p><button className="button button-primary" onClick={() => location.reload()}>Try again</button></div></main>;

  const open = data.obligations.filter((item) => item.balance > 0);
  const hasProfile = Boolean(data.profile.displayName && data.profile.mobileLast4);

  return <main className="product-page personal-page">
    <div className="page-heading dashboard-heading"><div><span className="page-eyebrow">Personal money view</span><h1>Your dues, one calm view.</h1><p>Track bills, EMIs, recharges, subscriptions, and government dues separately from your business workspace.</p></div><div className="heading-actions"><span className="live-context"><i /> Private to your account</span><button className="button button-primary" type="button" onClick={() => setShowAdd(true)}>Add a due <ProductIcon name="arrow" /></button></div></div>
    {error && <div className="form-error" role="alert">{error}</div>}
    {notice && <div className="form-notice" role="status"><ProductIcon name="check" />{notice}</div>}

    {!hasProfile && <section className="panel personal-onboarding"><div><span className="section-kicker">Finish your personal setup</span><h2>Tell DuePilot how to identify your personal account.</h2><p>Your workspace login remains email and password. Mobile verification will be required before any live biller or bank connection is enabled.</p></div><form onSubmit={saveProfile}><label>Name<input name="displayName" placeholder="Your name" defaultValue={data.profile.displayName} required minLength={2} maxLength={120} /></label><label>Mobile number<input name="mobile" inputMode="tel" placeholder="9876543210 or +919876543210" maxLength={16} required /></label><button className="button button-primary" disabled={saving}>{saving ? "Saving..." : "Save personal profile"}</button></form></section>}

    <section className="metric-grid" aria-label="Personal dues summary"><Metric label="Total to pay" value={money.format(data.summary.totalOpen)} hint={`${open.length} open obligation${open.length === 1 ? "" : "s"}`} tone="rose" /><Metric label="Past due" value={money.format(data.summary.overdueAmount)} hint={`${data.summary.overdueCount} need attention`} tone="amber" /><Metric label="Due soon" value={money.format(data.summary.dueSoonAmount)} hint="Next seven days" tone="blue" /><Metric label="Paid history" value={money.format(data.summary.paidAmount)} hint="Recorded personal payments" tone="green" /></section>

    <section className="panel personal-plan"><header><div><span className="section-kicker">Payment plan</span><h2>Plan around your real deadlines.</h2><p>These records are stored against your account, not the business workspace.</p></div><div className="filter-pills personal-periods">{(["all", "past", "current", "next"] as Period[]).map((item) => <button key={item} type="button" className={period === item ? "active" : ""} onClick={() => setPeriod(item)}>{item === "all" ? "All dues" : item === "past" ? "Past months" : item === "current" ? "This month" : "Next month"}</button>)}</div></header><div className="personal-due-list">{visible.map((item) => <article className={`personal-due-row ${item.status}`} key={item.id}><span className="personal-due-icon">{item.category.slice(0, 2).toUpperCase()}</span><div><b>{item.title}</b><small>{item.providerName} · {item.externalReference}</small></div><span><strong>{money.format(item.balance)}</strong><small>Due {item.dueDate}</small></span><em className={`status ${item.status}`}>{statusText(item)}</em>{item.balance > 0 ? <button className="button button-quiet" type="button" onClick={() => setNotice("Payment options will appear after a verified payment provider is connected. No payment credentials are collected here.")}>Payment options</button> : <span className="paid-label">Settled</span>}</article>)}{!visible.length && <div className="empty-list personal-empty"><span className="empty-art">+</span><b>No dues in this period</b><span>Add a bill manually or connect a verified provider when integrations are enabled.</span><button className="button button-primary" type="button" onClick={() => setShowAdd(true)}>Add your first due</button></div>}</div></section>

    <section className="personal-bottom-grid"><section className="panel personal-sources"><header><div><span className="section-kicker">Connected sources</span><h2>Consent before connection.</h2><p>DuePilot never asks for bank passwords, UPI PINs, card secrets, or OTPs.</p></div></header>{data.connections.length ? data.connections.map((connection) => <div className="personal-source" key={connection.id}><span>{connection.providerName.slice(0, 2).toUpperCase()}</span><div><b>{connection.providerName}</b><small>{connection.category} · {connection.status}</small></div><em>{connection.lastSyncedAt ? `Synced ${connection.lastSyncedAt}` : "Not synced yet"}</em></div>) : <div className="personal-source-empty"><b>No live sources connected.</b><span>Manual tracking is available now. Provider integrations require explicit consent and verification.</span></div>}</section><section className="panel personal-priority"><span className="section-kicker">Smart priority</span><h2>{data.summary.overdueCount ? "Resolve overdue balances first." : data.summary.dueSoonAmount ? "Prepare for the next seven days." : "You are caught up."}</h2><p>{data.summary.overdueCount ? `${data.summary.overdueCount} obligation${data.summary.overdueCount === 1 ? " is" : "s are"} past the due date. Review the oldest record before new renewals arrive.` : data.summary.dueSoonAmount ? "Review upcoming obligations and keep a payment method ready before their deadlines." : "Add your recurring bills here to make future deadlines visible."}</p><button className="button button-quiet" type="button" onClick={() => setNotice("DuePilot prioritizes by due date, balance, overdue days, and provider status.")}>How priority works</button></section></section>

    {showAdd && <div className="modal-backdrop" role="presentation" onMouseDown={() => setShowAdd(false)}><section className="modal personal-modal" role="dialog" aria-modal="true" aria-labelledby="add-personal-due" onMouseDown={(event) => event.stopPropagation()}><header><div><span className="section-kicker">Personal record</span><h2 id="add-personal-due">Add a due</h2><p>Track an obligation without connecting an external provider.</p></div><button className="icon-button" type="button" onClick={() => setShowAdd(false)} aria-label="Close"><ProductIcon name="close" /></button></header><form onSubmit={addObligation}><div className="form-grid"><label>Provider<input name="providerName" required minLength={2} maxLength={160} placeholder="TANGEDCO, HDFC Bank" /></label><label>Category<select name="category" defaultValue="utilities"><option value="utilities">Utilities</option><option value="vehicle">Vehicle</option><option value="government">Government</option><option value="recharge">Recharge</option><option value="subscriptions">Subscriptions</option><option value="housing">Housing</option><option value="education">Education</option><option value="healthcare">Healthcare</option><option value="other">Other</option></select></label></div><label>Due title<input name="title" required minLength={2} maxLength={180} placeholder="Electricity bill" /></label><div className="form-grid"><label>Reference<input name="externalReference" required minLength={2} maxLength={180} placeholder="Account or bill reference" /></label><label>Amount<input name="amount" type="number" min="0.01" max="999999999" step="0.01" required placeholder="2840" /></label><label>Issue date<input name="issueDate" type="date" /></label><label>Due date<input name="dueDate" type="date" required /></label></div><label>Currency<select name="currency" defaultValue="INR"><option value="INR">INR — Indian Rupee</option><option value="USD">USD — US Dollar</option></select></label><footer><button className="button button-quiet" type="button" onClick={() => setShowAdd(false)}>Cancel</button><button className="button button-primary" disabled={saving}>{saving ? "Saving..." : "Add due"} <ProductIcon name="arrow" /></button></footer></form></section></div>}
  </main>;
}
