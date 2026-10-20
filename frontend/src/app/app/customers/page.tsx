"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import { ProductIcon } from "@/components/product-icon";
import { apiMutation, apiRequest } from "@/lib/api";
import type { Customer } from "@/types/api";

const money = new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 });

export default function CustomersPage() {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [query, setQuery] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [saving, setSaving] = useState(false);
  const [notice, setNotice] = useState("");

  useEffect(() => {
    let active = true;
    apiRequest<Customer[]>("/customers").then((result) => {
      if (!active) return;
      if (result.ok) setCustomers(result.data);
      else setError(result.error.message);
      setLoading(false);
    });
    return () => { active = false; };
  }, []);

  const visible = useMemo(() => customers.filter((customer) => `${customer.name} ${customer.contact} ${customer.email}`.toLowerCase().includes(query.toLowerCase())), [customers, query]);
  const totalOpen = customers.reduce((sum, customer) => sum + customer.outstanding, 0);

  async function createCustomer(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(""); setNotice(""); setSaving(true);
    const form = new FormData(event.currentTarget);
    const result = await apiMutation<Customer>("/customers", { name: form.get("name"), contactName: form.get("contactName"), email: form.get("email"), phone: form.get("phone"), externalReference: form.get("externalReference") });
    setSaving(false);
    if (!result.ok) { setError(result.error.message); return; }
    setCustomers((current) => [result.data, ...current]);
    setNotice(`${result.data.name} was added to this workspace.`);
    setShowCreate(false);
    event.currentTarget.reset();
  }

  return <main className="product-page">
    <div className="page-heading"><div><span className="page-eyebrow">Customer health</span><h1>Know every account.</h1><p>See the people behind each balance, their payment behaviour, and where a relationship needs attention.</p></div><div className="heading-actions"><div className="heading-stat"><small>Open across accounts</small><strong>{money.format(totalOpen)}</strong></div><button className="button button-primary" type="button" onClick={() => setShowCreate(true)}>Add account <ProductIcon name="arrow" /></button></div></div>
    {error && <div className="form-error" role="alert">{error}</div>}
    {notice && <div className="form-notice" role="status"><ProductIcon name="check" />{notice}</div>}
    <section className="panel customer-workspace"><div className="list-toolbar"><label><ProductIcon name="search" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search customer, contact, or email" /></label><span className="result-count">{visible.length} account{visible.length === 1 ? "" : "s"}</span></div>{loading ? <div className="list-loading">Loading customer records…</div> : <div className="customer-grid">{visible.map((customer) => <article key={customer.id}><header><span className="customer-avatar">{customer.initials}</span><div><h2>{customer.name}</h2><p>{customer.contact}</p><a href={`mailto:${customer.email}`}>{customer.email}</a></div><em className={`health ${customer.health}`}>{customer.health.replace(/_/g, " ")}</em></header><div className="customer-stats"><span><small>Open balance</small><b>{money.format(customer.outstanding)}</b></span><span><small>Overdue</small><b>{money.format(customer.overdue)}</b></span><span><small>Invoices</small><b>{customer.invoiceCount}</b></span></div></article>)}{!visible.length && <div className="empty-list"><span className="empty-art">◉</span><b>No customer records match</b><span>Check the search term and try again.</span></div>}</div>}</section>
    {showCreate && <div className="modal-backdrop" role="presentation" onMouseDown={() => setShowCreate(false)}><section className="modal compact" role="dialog" aria-modal="true" aria-labelledby="new-account-title" onMouseDown={(event) => event.stopPropagation()}><header><div><span className="section-kicker">Workspace record</span><h2 id="new-account-title">Add an account</h2><p>Create the person or organization you bill in this workspace.</p></div><button type="button" className="icon-button" onClick={() => setShowCreate(false)} aria-label="Close"><ProductIcon name="close" /></button></header><form onSubmit={createCustomer}><label>Account name<input name="name" required minLength={2} maxLength={160} placeholder="e.g. Nova Labs" /></label><div className="form-grid"><label>Contact name<input name="contactName" maxLength={120} placeholder="Optional" /></label><label>Phone<input name="phone" maxLength={40} placeholder="Optional" /></label></div><label>Email<input name="email" type="email" maxLength={254} placeholder="billing@example.com" /></label><label>External reference<input name="externalReference" maxLength={120} placeholder="CRM or ERP ID (optional)" /></label><footer><button type="button" className="button button-quiet" onClick={() => setShowCreate(false)}>Cancel</button><button className="button button-primary" disabled={saving}>{saving ? "Creating..." : "Create account"} <ProductIcon name="arrow" /></button></footer></form></section></div>}
  </main>;
}
