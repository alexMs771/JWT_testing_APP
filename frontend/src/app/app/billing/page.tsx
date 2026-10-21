"use client";

import { FormEvent, useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { apiMutation, apiRequest } from "@/lib/api";
import { notifyToast } from "@/lib/toast";
import { ProductIcon } from "@/components/product-icon";
import type { PlanAccess, PlanDefinition, Session, WorkspaceNode, WorkspaceUnit } from "@/types/api";

type BillingResponse = { current: PlanAccess; plans: PlanDefinition[] };
type WorkspaceResponse = { items: WorkspaceNode[]; access: PlanAccess };
type UnitResponse = { items: WorkspaceUnit[]; access: PlanAccess };

type JsonRecord = Record<string, unknown>;

function valueOf(record: JsonRecord, ...keys: string[]) {
  for (const key of keys) {
    if (record[key] !== undefined && record[key] !== null) return record[key];
  }
  return undefined;
}

function numberOf(record: JsonRecord, ...keys: string[]) {
  const value = valueOf(record, ...keys);
  return typeof value === "number" ? value : Number(value ?? 0);
}

function textOf(record: JsonRecord, ...keys: string[]) {
  const value = valueOf(record, ...keys);
  return value === undefined ? "" : String(value);
}

function normalizeBillingResponse(raw: BillingResponse): BillingResponse {
  const source = raw as unknown as JsonRecord;
  const rawCurrent = (valueOf(source, "current") || {}) as JsonRecord;
  const rawUsage = (valueOf(rawCurrent, "usage") || {}) as JsonRecord;
  const rawLimits = (valueOf(rawCurrent, "limits") || {}) as JsonRecord;
  const rawWorkspace = (valueOf(rawCurrent, "workspace") || {}) as JsonRecord;
  const rawPlans = Array.isArray(valueOf(source, "plans")) ? valueOf(source, "plans") as JsonRecord[] : [];

  return {
    current: {
      plan: textOf(rawCurrent, "plan") || "free",
      subscriptionStatus: textOf(rawCurrent, "subscriptionStatus", "subscriptionstatus") || "active",
      subscriptionId: textOf(rawCurrent, "subscriptionId", "subscriptionid"),
      startsAt: textOf(rawCurrent, "startsAt", "startsat"),
      expiresAt: textOf(rawCurrent, "expiresAt", "expiresat"),
      isPaid: Boolean(valueOf(rawCurrent, "isPaid", "ispaid")),
      demoMode: Boolean(valueOf(rawCurrent, "demoMode", "demomode")),
      features: Array.isArray(valueOf(rawCurrent, "features")) ? valueOf(rawCurrent, "features") as string[] : [],
      limits: {
        aiRequestsPerMonth: numberOf(rawLimits, "aiRequestsPerMonth", "airequestspermonth"),
        childWorkspaces: numberOf(rawLimits, "childWorkspaces", "childworkspaces"),
      },
      usage: {
        aiRequestsThisMonth: numberOf(rawUsage, "aiRequestsThisMonth", "airequeststhismonth"),
        aiRequestsRemaining: numberOf(rawUsage, "aiRequestsRemaining", "airequestsremaining"),
      },
      workspace: {
        childCount: numberOf(rawWorkspace, "childCount", "childcount"),
        canCreateChild: Boolean(valueOf(rawWorkspace, "canCreateChild", "cancreatechild")),
      },
    },
    plans: rawPlans.map((rawPlan) => ({
      key: textOf(rawPlan, "key"),
      name: textOf(rawPlan, "name"),
      annualValidity: textOf(rawPlan, "annualValidity", "annualvalidity"),
      aiRequestsPerMonth: numberOf(rawPlan, "aiRequestsPerMonth", "airequestspermonth"),
      childWorkspaces: numberOf(rawPlan, "childWorkspaces", "childworkspaces"),
      description: textOf(rawPlan, "description"),
    })),
  };
}

const planTitles: Record<string, string> = {
  free: "Start focused",
  plus: "Scale the team",
  pro: "Run the operation",
};

const planFeatures: Record<string, string[]> = {
  free: ["One secure workspace", "CSV invoice imports", "Core receivables reports"],
  plus: ["Guided AI for collections", "Two nested workspaces", "Sector units for departments and classes"],
  pro: ["Unlimited AI assistance", "Nineteen nested workspaces", "Advanced reports and audit exports"],
};

export default function BillingPage() {
  const [data, setData] = useState<BillingResponse | null>(null);
  const [workspaces, setWorkspaces] = useState<WorkspaceNode[]>([]);
  const [units, setUnits] = useState<WorkspaceUnit[]>([]);
  const [error, setError] = useState("");
  const [structureError, setStructureError] = useState("");
  const [notice, setNotice] = useState("");
  const [busy, setBusy] = useState("");
  const [structureBusy, setStructureBusy] = useState("");

  const load = useCallback(async () => {
    setError("");
    const result = await apiRequest<BillingResponse>("/subscription", { method: "GET" });
    if (result.ok) {
      setData(normalizeBillingResponse(result.data));
      setError("");
    } else setError(result.error.message);
  }, []);

  const loadStructure = useCallback(async () => {
    const [workspaceResult, unitResult] = await Promise.all([
      apiRequest<WorkspaceResponse>("/workspaces", { method: "GET" }),
      apiRequest<UnitResponse>("/workspace/units", { method: "GET" }),
    ]);
    if (workspaceResult.ok) setWorkspaces(workspaceResult.data.items || []);
    if (unitResult.ok) setUnits(unitResult.data.items || []);
    if (!workspaceResult.ok && !unitResult.ok) setStructureError(workspaceResult.error.message);
  }, []);

  useEffect(() => {
    const initialLoad = window.setTimeout(() => {
      void load();
      void loadStructure();
    }, 0);
    const interval = window.setInterval(() => { void load(); void loadStructure(); }, 10000);
    return () => {
      window.clearTimeout(initialLoad);
      window.clearInterval(interval);
    };
  }, [load, loadStructure]);

  async function choosePlan(plan: string) {
    setBusy(plan); setError(""); setNotice("");
    const result = await apiMutation<{ subscription: PlanAccess; session: Session }>("/subscription/subscribe", { plan });
    if (result.ok) {
      const label = plan === "pro" ? "Pro" : "Plus";
      const expires = result.data.subscription.expiresAt ? new Date(result.data.subscription.expiresAt).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }) : "soon";
      setNotice(`${label} is active until ${expires}.`);
      notifyToast({ tone: "success", title: `${label} plan activated`, message: result.data.subscription.demoMode ? `Your test entitlement is active until ${expires}. Signed claims were refreshed.` : "Your workspace entitlements and signed claims were refreshed.", session: result.data.session });
      await Promise.all([load(), loadStructure()]);
    }
    else setError(result.error.message);
    setBusy("");
  }

  async function createChildWorkspace(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const values = new FormData(event.currentTarget);
    const name = String(values.get("workspaceName") || "").trim();
    const organizationType = String(values.get("organizationType") || "business");
    if (!name) return;
    setStructureBusy("workspace"); setStructureError("");
    const result = await apiMutation<WorkspaceNode>("/workspaces", { name, organizationType });
    if (result.ok) {
      event.currentTarget.reset();
      notifyToast({ tone: "success", title: "Nested workspace created", message: `${result.data.name} is ready for a separate team or department.` });
      await Promise.all([load(), loadStructure()]);
    } else setStructureError(result.error.message);
    setStructureBusy("");
  }

  async function createUnit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const values = new FormData(event.currentTarget);
    const name = String(values.get("unitName") || "").trim();
    const unitType = String(values.get("unitType") || "department");
    const code = String(values.get("unitCode") || "").trim();
    const parentUnitId = String(values.get("parentUnitId") || "");
    if (!name) return;
    setStructureBusy("unit"); setStructureError("");
    const result = await apiMutation<WorkspaceUnit>("/workspace/units", { name, unitType, code, parentUnitId });
    if (result.ok) {
      event.currentTarget.reset();
      notifyToast({ tone: "success", title: "Workspace unit added", message: `${result.data.name} is now part of your sector structure.` });
      await Promise.all([load(), loadStructure()]);
    } else setStructureError(result.error.message);
    setStructureBusy("");
  }

  if (!data && !error) return <main className="product-page"><div className="skeleton heading-skeleton" /></main>;
  if (error && !data) return <main className="product-page"><div className="form-error" role="alert">{error}</div></main>;
  if (!data) return null;

  const current = data.current;
  return <main className="product-page billing-page">
    <div className="billing-breadcrumb"><Link href="/app/dashboard">← Workspace overview</Link><span>Plans &amp; usage</span></div>
    <section className="billing-hero">
      <div className="billing-hero-copy"><span className="page-eyebrow">Workspace entitlements</span><h1>Give your team room to move.</h1><p>Choose the right balance of AI guidance and workspace capacity. Your identity role never changes when the workspace plan changes.</p><div className="billing-proof-row"><span><i />Secure by workspace</span><span><i />No payment collected in this test flow</span></div></div>
      <div className="billing-current-card"><span className="billing-card-label">Current plan</span><div className="billing-current-title"><strong>{current.plan.toUpperCase()}</strong><span className="billing-active-pill"><i /> Active</span></div><p>{current.isPaid ? "Annual access is active for this workspace." : "Core receivables workflow is available."}</p><Link href="/app/dashboard">View workspace <b>→</b></Link></div>
    </section>
    {error && <div className="form-error billing-error" role="alert"><span>{error}</span><button type="button" onClick={() => void load()}>Retry</button></div>}
    {notice && <div className="form-notice billing-notice" role="status">{notice}</div>}
    <section className="billing-usage-panel"><div className="billing-section-heading"><div><span className="section-kicker">Usage guardrails</span><h2>Know what you can use before you automate.</h2></div><span>Live workspace limits</span></div><div className="billing-usage"><span><b>{current.usage.aiRequestsRemaining < 0 ? "∞" : current.usage.aiRequestsRemaining}</b><small>AI requests remaining</small></span><span><b>{current.workspace.childCount} / {current.limits.childWorkspaces || "—"}</b><small>Nested workspaces</small></span><span><b>{current.expiresAt ? current.expiresAt.slice(0, 10) : "—"}</b><small>Entitlement end</small></span></div></section>
    <section className="structure-panel"><header><div><span className="section-kicker">Sector structure</span><h2>Organize the operation around real teams.</h2><p>Use nested workspaces for departments and sector units for classes, branches, batches, or divisions.</p></div><span className="structure-count"><b>{workspaces.filter((item) => item.parentWorkspaceId).length}</b> nested <b>{units.length}</b> units</span></header><div className="structure-grid"><div className="structure-tree"><div className="structure-root"><span className="structure-node-icon"><ProductIcon name="dashboard" /></span><div><strong>{workspaces.find((item) => !item.parentWorkspaceId)?.name || "Main workspace"}</strong><small>Main tenant · current plan</small></div></div>{workspaces.filter((item) => item.parentWorkspaceId).map((item) => <div className="structure-child" key={item.id}><span className="structure-branch" /><span className="structure-node-icon"><ProductIcon name="dashboard" /></span><div><strong>{item.name}</strong><small>{item.organizationType || "business"} · {item.plan} plan</small></div></div>)}{units.map((unit) => <div className="structure-unit" key={unit.id}><span className="structure-node-icon"><ProductIcon name="invoices" /></span><div><strong>{unit.name}</strong><small>{unit.unitType}{unit.code ? ` · ${unit.code}` : ""}</small></div></div>)}{!workspaces.some((item) => item.parentWorkspaceId) && !units.length && <div className="structure-empty">No nested structure yet. Upgrade to Plus to model your first department.</div>}</div><div className="structure-forms"><form onSubmit={createChildWorkspace}><div className="structure-form-heading"><strong>New nested workspace</strong><small>Plus: 2 · Pro: 19</small></div><label>Workspace name<input name="workspaceName" minLength={2} maxLength={120} placeholder="e.g. Computer Science" required disabled={!data.current.workspace.canCreateChild || Boolean(structureBusy)} /></label><label>Sector<select name="organizationType" defaultValue="business" disabled={!data.current.workspace.canCreateChild || Boolean(structureBusy)}><option value="business">Business / division</option><option value="school">School</option><option value="college">College department</option><option value="coaching">Coaching / batch</option><option value="healthcare">Healthcare unit</option><option value="other">Other</option></select></label><button className="button button-primary" disabled={!data.current.workspace.canCreateChild || Boolean(structureBusy)}>{structureBusy === "workspace" ? "Creating..." : data.current.workspace.canCreateChild ? "Create nested workspace" : "Upgrade to unlock"}</button></form><form onSubmit={createUnit}><div className="structure-form-heading"><strong>New sector unit</strong><small>Plus: 20 · Pro: 200</small></div><label>Unit name<input name="unitName" minLength={2} maxLength={120} placeholder="e.g. Class 12-A" required disabled={!data.current.isPaid || Boolean(structureBusy)} /></label><div className="structure-form-row"><label>Type<select name="unitType" defaultValue="department" disabled={!data.current.isPaid || Boolean(structureBusy)}><option value="department">Department</option><option value="division">Division</option><option value="branch">Branch</option><option value="grade">Grade</option><option value="class">Class</option><option value="batch">Batch</option><option value="team">Team</option></select></label><label>Code<input name="unitCode" maxLength={40} placeholder="Optional" disabled={!data.current.isPaid || Boolean(structureBusy)} /></label></div><button className="button button-secondary" disabled={!data.current.isPaid || Boolean(structureBusy)}>{structureBusy === "unit" ? "Adding..." : data.current.isPaid ? "Add sector unit" : "Upgrade to unlock"}</button></form></div></div>{structureError && <div className="form-error structure-error" role="alert">{structureError}</div>}</section>
    <div className="billing-plans-heading"><div><span className="section-kicker">Plans for your operation</span><h2>Start small. Scale with clarity.</h2></div><p>Every plan keeps your data, roles, and workspace context intact.</p></div>
    <div className="plan-grid">{data.plans.map((plan) => <article className={`plan-card plan-${plan.key} ${plan.key === current.plan ? "current" : ""}`} key={plan.key}><div className="plan-card-top"><span className="section-kicker">{plan.name}</span>{plan.key === "plus" && <span className="plan-badge">Most popular</span>}</div><h2>{planTitles[plan.key] || plan.name}</h2><p>{plan.description}</p><div className="plan-facts"><span><b>{plan.aiRequestsPerMonth < 0 ? "Unlimited" : plan.aiRequestsPerMonth}</b><small>AI requests / month</small></span><span><b>{plan.childWorkspaces || "—"}</b><small>Nested workspaces</small></span><span><b>{plan.annualValidity}</b><small>Validity</small></span></div><ul className="plan-features">{(planFeatures[plan.key] || []).map((feature) => <li key={feature}><i>✓</i>{feature}</li>)}</ul><button className={`button ${plan.key === current.plan ? "button-quiet" : "button-primary"}`} disabled={plan.key === "free" || plan.key === current.plan || Boolean(busy)} onClick={() => void choosePlan(plan.key)}>{busy === plan.key ? "Activating..." : plan.key === current.plan ? "Current plan" : `Choose ${plan.name}`}</button></article>)}</div>
    <section className="billing-note"><div className="billing-note-icon">i</div><div><b>How plan changes work</b><span>{current.demoMode ? "This test flow activates a server-side entitlement for a short TTL, reissues signed access claims, and returns to Free automatically when it expires." : "In production, a verified payment webhook would activate the same entitlement service; the user role and authorization model remain separate."}</span></div></section>
  </main>;
}
