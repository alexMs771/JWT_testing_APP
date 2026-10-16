"use client";

import Link from "next/link";
import { FormEvent, useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { ProductIcon } from "@/components/product-icon";
import { apiMutation, apiRequest } from "@/lib/api";
import type { Invoice } from "@/types/api";

const money = new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 });

export default function InvoiceDetailPage() {
  const { invoiceId } = useParams<{ invoiceId: string }>();
  const [invoice, setInvoice] = useState<Invoice | null>(null);
  const [action, setAction] = useState<"payment" | "promise" | "dispute" | null>(null);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");

  useEffect(() => {
    let active = true;
    apiRequest<Invoice>(`/invoices/${invoiceId}`).then((result) => {
      if (!active) return;
      if (result.ok) setInvoice(result.data); else setError(result.error.message);
    });
    return () => { active = false; };
  }, [invoiceId]);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!action) return;
    setError("");
    setNotice("");
    const form = new FormData(event.currentTarget);
    const payload = action === "payment" ? { amount: Number(form.get("amount")), reference: form.get("reference") } : action === "promise" ? { promiseDate: form.get("promiseDate"), note: form.get("note") } : { reason: form.get("reason") };
    const result = await apiMutation<Invoice>(`/invoices/${invoiceId}/${action}`, payload);
    if (!result.ok) { setError(result.error.message); return; }
    setInvoice(result.data);
    setNotice(action === "payment" ? "Payment recorded and the balance is up to date." : action === "promise" ? "Payment commitment saved to the invoice timeline." : "Dispute opened for review.");
    setAction(null);
  }

  async function remind() {
    setError("");
    const result = await apiMutation<Invoice>(`/invoices/${invoiceId}/reminder`, { channel: "email" });
    if (!result.ok) setError(result.error.message);
    else { setInvoice(result.data); setNotice("Email reminder queued for this customer."); }
  }

  if (!invoice) return <main className="product-page"><p className="page-loading">{error || "Loading invoice…"}</p></main>;

  const isSettled = !invoice.outstanding;

  return <main className="product-page invoice-detail-page">
    <Link className="back-link" href="/app/invoices">← All invoices</Link>
    <div className="page-heading invoice-heading"><div><span className="page-eyebrow">{invoice.customerName}</span><h1>{invoice.invoiceNumber}</h1><p>Issued {invoice.issueDate} · payment due {invoice.dueDate}</p></div><em className={`status large ${invoice.status}`}>{invoice.status.replace(/_/g, " ")}</em></div>
    {error && <div className="form-error" role="alert">{error}</div>}{notice && <div className="form-notice" role="status"><ProductIcon name="check" />{notice}</div>}
    <div className="invoice-detail-grid"><section className="panel invoice-document"><header><div><span className="section-kicker">Invoice overview</span><h2>{invoice.description}</h2></div><span className="document-brand">DuePilot</span></header><div className="invoice-summary-grid"><div><small>Invoice total</small><b>{money.format(invoice.amount)}</b></div><div><small>Received</small><b>{money.format(invoice.paidAmount)}</b></div><div className="outstanding-summary"><small>Open balance</small><b>{money.format(invoice.outstanding)}</b></div></div><dl><div><dt>Customer</dt><dd>{invoice.customerName}</dd></div><div><dt>Purchase order</dt><dd>{invoice.purchaseOrder || "Not provided"}</dd></div><div><dt>Follow-ups</dt><dd>{invoice.reminderCount} reminder{invoice.reminderCount === 1 ? "" : "s"} sent</dd></div>{invoice.promiseDate && <div><dt>Payment promise</dt><dd>{invoice.promiseDate}</dd></div>}{invoice.disputeReason && <div><dt>Dispute in review</dt><dd>{invoice.disputeReason}</dd></div>}</dl></section><aside className="panel action-panel"><span className="section-kicker">Actions</span><h2>{isSettled ? "This invoice is settled" : "Move this balance forward"}</h2><p>{isSettled ? "The payment record is complete." : "Record only verified activity so the collection record stays trustworthy."}</p><button className="button button-primary button-block" disabled={isSettled} onClick={() => setAction("payment")}>Record payment <ProductIcon name="arrow" /></button><button className="button button-quiet button-block" disabled={isSettled} onClick={() => setAction("promise")}>Log payment promise</button><button className="button button-quiet button-block" disabled={isSettled} onClick={remind}>Send email reminder</button><button className="link-danger" disabled={isSettled} onClick={() => setAction("dispute")}>Open a dispute</button></aside></div>
    {action && <div className="modal-backdrop" onMouseDown={() => setAction(null)}><section className="modal compact" role="dialog" aria-modal="true" aria-labelledby="invoice-action-title" onMouseDown={(event) => event.stopPropagation()}><header><div><span className="section-kicker">Invoice action</span><h2 id="invoice-action-title">{action === "payment" ? "Record a payment" : action === "promise" ? "Log a payment promise" : "Open a dispute"}</h2></div><button type="button" className="icon-button" onClick={() => setAction(null)} aria-label="Close"><ProductIcon name="close" /></button></header><form onSubmit={submit}>{action === "payment" && <><label>Received amount<input name="amount" type="number" min="1" max={invoice.outstanding} step="0.01" defaultValue={invoice.outstanding} required /></label><label>Payment reference<input name="reference" maxLength={100} required placeholder="UTR or provider reference" /></label></>}{action === "promise" && <><label>Promised payment date<input name="promiseDate" type="date" min={new Date().toISOString().slice(0, 10)} required /></label><label>Context for your team<textarea name="note" maxLength={500} placeholder="What did the customer confirm?" /></label></>}{action === "dispute" && <label>Reason for review<textarea name="reason" minLength={10} maxLength={1000} required placeholder="Explain what needs review" /></label>}<footer><button type="button" className="button button-quiet" onClick={() => setAction(null)}>Cancel</button><button className="button button-primary">Confirm <ProductIcon name="arrow" /></button></footer></form></section></div>}
  </main>;
}
