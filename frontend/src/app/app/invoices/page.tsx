"use client";

import Link from "next/link";
import { FormEvent, useCallback, useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import { ProductIcon } from "@/components/product-icon";
import { apiMutation, apiRequest } from "@/lib/api";
import type { Customer, Invoice } from "@/types/api";

const money = new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 });
const today = new Date().toISOString().slice(0, 10);
const defaultDue = new Date(Date.now() + 30 * 86400000).toISOString().slice(0, 10);
const filters = ["all", "overdue", "due_soon", "partial", "disputed", "paid"];

export default function InvoicesPage() {
  const searchParams = useSearchParams();
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [status, setStatus] = useState("all");
  const [query, setQuery] = useState(() => searchParams.get("search") || "");
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    const [invoiceResult, customerResult] = await Promise.all([apiRequest<Invoice[]>("/invoices"), apiRequest<Customer[]>("/customers")]);
    if (invoiceResult.ok) setInvoices(invoiceResult.data); else setError(invoiceResult.error.message);
    if (customerResult.ok) setCustomers(customerResult.data); else setError(customerResult.error.message);
    setLoading(false);
  }, []);

  useEffect(() => {
    let active = true;
    Promise.all([apiRequest<Invoice[]>("/invoices"), apiRequest<Customer[]>("/customers")]).then(([invoiceResult, customerResult]) => {
      if (!active) return;
      if (invoiceResult.ok) setInvoices(invoiceResult.data); else setError(invoiceResult.error.message);
      if (customerResult.ok) setCustomers(customerResult.data); else setError(customerResult.error.message);
      setLoading(false);
    });
    return () => { active = false; };
  }, []);

  const visibleInvoices = useMemo(() => invoices.filter((invoice) => {
    const matchesStatus = status === "all" || invoice.status === status;
    const needle = query.trim().toLowerCase();
    return matchesStatus && (!needle || `${invoice.invoiceNumber} ${invoice.customerName}`.toLowerCase().includes(needle));
  }), [invoices, query, status]);

  async function createInvoice(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const formElement = event.currentTarget;
    setError("");
    setNotice("");
    const form = new FormData(formElement);
    const result = await apiMutation<Invoice>("/invoices", { customerId: form.get("customerId"), amount: Number(form.get("amount")), issueDate: form.get("issueDate"), dueDate: form.get("dueDate"), purchaseOrder: form.get("purchaseOrder"), description: form.get("description") });
    if (!result.ok) { setError(result.error.message); return; }
    setNotice(`${result.data.invoiceNumber} was created and added to your collection workflow.`);
    setShowCreate(false);
    formElement.reset();
    await load();
  }

  return <main className="product-page">
    <div className="page-heading"><div><span className="page-eyebrow">Billing workspace</span><h1>Invoices, with context.</h1><p>Create receivables, follow each balance, and keep the payment story attached to the invoice.</p></div><button className="button button-primary" onClick={() => setShowCreate(true)}>Create invoice <ProductIcon name="arrow" /></button></div>
    {error && <div className="form-error" role="alert">{error}</div>}
    {notice && <div className="form-notice" role="status"><ProductIcon name="check" />{notice}</div>}
    <section className="panel invoice-workspace">
      <div className="list-toolbar"><label><ProductIcon name="search" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search invoice number or customer" /></label><div className="filter-pills">{filters.map((item) => <button type="button" className={status === item ? "active" : ""} onClick={() => setStatus(item)} key={item}>{item.replace(/_/g, " ")}</button>)}</div></div>
      {loading ? <div className="list-loading">Loading invoices…</div> : <div className="invoice-list"><div className="invoice-list-head"><span>Invoice</span><span>Customer</span><span>Due date</span><span>Stage</span><span>Open balance</span><span /></div>{visibleInvoices.map((invoice) => <Link href={`/app/invoices/${invoice.id}`} className="invoice-list-row" key={invoice.id}><span><b>{invoice.invoiceNumber}</b><small>{invoice.description}</small></span><span>{invoice.customerName}</span><span>{invoice.dueDate}</span><span><em className={`status ${invoice.status}`}>{invoice.status.replace(/_/g, " ")}</em></span><strong>{money.format(invoice.outstanding)}</strong><ProductIcon name="arrow" /></Link>)}{!visibleInvoices.length && <div className="empty-list"><span className="empty-art">⌕</span><b>No invoices match this view</b><span>Try another filter or create a new receivable.</span></div>}</div>}
    </section>
    {showCreate && <div className="modal-backdrop" role="presentation" onMouseDown={() => setShowCreate(false)}><section className="modal invoice-modal" role="dialog" aria-modal="true" aria-labelledby="new-invoice-title" onMouseDown={(event) => event.stopPropagation()}><header><div><span className="section-kicker">New receivable</span><h2 id="new-invoice-title">Create an invoice</h2><p>It will appear in your collection workspace immediately.</p></div><button type="button" className="icon-button" onClick={() => setShowCreate(false)} aria-label="Close"><ProductIcon name="close" /></button></header><form onSubmit={createInvoice}><label>Customer<select name="customerId" required defaultValue=""><option value="" disabled>Select a customer</option>{customers.map((customer) => <option value={customer.id} key={customer.id}>{customer.name}</option>)}</select></label><div className="form-grid"><label>Invoice amount<input name="amount" type="number" min="1" max="999999999" step="0.01" required placeholder="50000" /></label><label>Purchase order<input name="purchaseOrder" maxLength={80} placeholder="Optional reference" /></label><label>Issue date<input name="issueDate" type="date" required defaultValue={today} /></label><label>Due date<input name="dueDate" type="date" min={today} required defaultValue={defaultDue} /></label></div><label>Description<textarea name="description" required minLength={3} maxLength={500} defaultValue="Professional services" /></label><footer><button type="button" className="button button-quiet" onClick={() => setShowCreate(false)}>Cancel</button><button className="button button-primary">Create invoice <ProductIcon name="arrow" /></button></footer></form></section></div>}
  </main>;
}
