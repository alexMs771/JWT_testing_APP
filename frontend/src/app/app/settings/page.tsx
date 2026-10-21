"use client";

import { FormEvent, useEffect, useState } from "react";
import { ProductIcon } from "@/components/product-icon";
import { apiMutation, apiRequest } from "@/lib/api";
import type { AssistantStatus, WorkspaceSettings } from "@/types/api";

export default function SettingsPage() {
  const [workspace, setWorkspace] = useState<WorkspaceSettings | null>(null);
  const [assistant, setAssistant] = useState<AssistantStatus | null>(null);
  const [notice, setNotice] = useState("");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    let active = true;
    Promise.all([apiRequest<WorkspaceSettings>("/settings"), apiRequest<AssistantStatus>("/assistant/status")]).then(([workspaceResult, assistantResult]) => {
      if (!active) return;
      if (workspaceResult.ok) setWorkspace(workspaceResult.data); else setError(workspaceResult.error.message);
      if (assistantResult.ok) setAssistant(assistantResult.data);
    });
    return () => { active = false; };
  }, []);

  async function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSaving(true);
    setError("");
    setNotice("");
    const form = new FormData(event.currentTarget);
    const result = await apiMutation<WorkspaceSettings>("/settings", { name: form.get("name"), currency: form.get("currency"), financeEmail: form.get("financeEmail"), defaultTerms: Number(form.get("defaultTerms")) });
    if (result.ok) { setWorkspace(result.data); setNotice("Workspace settings saved."); } else setError(result.error.message);
    setSaving(false);
  }

  if (!workspace) return <main className="product-page"><div className="skeleton heading-skeleton" />{error && <div className="form-error" role="alert">{error}</div>}</main>;

  return <main className="product-page">
    <div className="page-heading"><div><span className="page-eyebrow">Workspace controls</span><h1>Set the rules once.</h1><p>Keep core billing defaults, security boundaries, and your AI connection understandable for every operator.</p></div></div>
    {error && <div className="form-error" role="alert">{error}</div>}{notice && <div className="form-notice" role="status"><ProductIcon name="check" />{notice}</div>}
    <div className="settings-grid"><form className="panel settings-form" onSubmit={save}><header><div><span className="section-kicker">Workspace profile</span><h2>Billing defaults</h2><p>These details determine the starting context for every new invoice.</p></div></header><div><label>Organization name<input name="name" minLength={2} maxLength={100} required defaultValue={workspace.name} /></label><label>Finance email<input name="financeEmail" type="email" maxLength={254} required defaultValue={workspace.financeEmail} /></label><div className="form-grid"><label>Base currency<select name="currency" defaultValue={workspace.currency}><option value="INR">INR — Indian Rupee</option><option value="USD">USD — US Dollar</option></select></label><label>Default payment terms<select name="defaultTerms" defaultValue={workspace.defaultTerms}><option value="15">Net 15</option><option value="30">Net 30</option><option value="45">Net 45</option></select></label></div></div><footer><span>Currency locks after the first invoice is created.</span><button disabled={saving} className="button button-primary">{saving ? "Saving…" : "Save changes"} {!saving && <ProductIcon name="arrow" />}</button></footer></form><aside className="settings-side"><section className="panel integration-card"><span className="section-kicker">AI assistant</span><h2>{assistant?.mode === "live" ? "Live intelligence is connected" : "Guided intelligence is ready"}</h2><p>{assistant?.mode === "live" ? `${assistant.keyCount} private provider credential slot${assistant.keyCount === 1 ? " is" : "s are"} available. No credential is sent to the browser.` : "Add a private provider key to your server environment to enable live answers. The guided assistant continues to use workspace context."}</p><div><i className={assistant?.enabled ? "online" : ""} /><span>{assistant?.enabled ? "Assistant enabled" : "Assistant unavailable"}</span><small>{assistant?.model}</small></div></section><section className="panel security-card"><span className="section-kicker">Trust controls</span><h2>Private by design</h2><ul><li>Secure refresh sessions</li><li>Short-lived bearer access tokens</li><li>Server-only provider credentials</li><li>Tenant-scoped workspace data</li></ul></section></aside></div>
  </main>;
}
