"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { ProductIcon } from "@/components/product-icon";
import { apiRequest } from "@/lib/api";
import type { Invoice } from "@/types/api";

const money = new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 });

export default function CollectionsPage() {
  const [items, setItems] = useState<Invoice[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;
    apiRequest<Invoice[]>("/invoices").then((result) => {
      if (!active) return;
      if (result.ok) setItems(result.data.filter((item) => item.status !== "paid").sort((a, b) => b.daysOverdue - a.daysOverdue));
      else setError(result.error.message);
      setLoading(false);
    });
    return () => { active = false; };
  }, []);

  const overdueValue = useMemo(() => items.filter((item) => item.daysOverdue > 0).reduce((sum, item) => sum + item.outstanding, 0), [items]);

  return <main className="product-page">
    <div className="page-heading"><div><span className="page-eyebrow">Collection operations</span><h1>Make the next follow-up count.</h1><p>Work the highest-impact balances first, while keeping every promise, reminder, and dispute on record.</p></div><div className="heading-stat danger"><small>Overdue to resolve</small><strong>{money.format(overdueValue)}</strong></div></div>
    {error && <div className="form-error" role="alert">{error}</div>}
    {loading ? <div className="panel list-loading">Building your collection queue…</div> : <section className="collection-board">{items.map((invoice, index) => <article className="panel collection-card" key={invoice.id}><span className={`priority-number ${index < 2 ? "high" : "normal"}`}>{String(index + 1).padStart(2, "0")}</span><div><span className="section-kicker">{invoice.invoiceNumber}</span><h2>{invoice.customerName}</h2><p>{invoice.daysOverdue > 0 ? `${invoice.daysOverdue} days overdue` : `Due in ${invoice.daysUntilDue} days`} · {invoice.reminderCount} reminder{invoice.reminderCount === 1 ? "" : "s"} sent</p></div><span><em className={`status ${invoice.status}`}>{invoice.status.replace(/_/g, " ")}</em><small>{invoice.promiseDate ? `Promised ${invoice.promiseDate}` : "No recorded promise"}</small></span><strong>{money.format(invoice.outstanding)}</strong><Link href={`/app/invoices/${invoice.id}`}>Review record <ProductIcon name="arrow" /></Link></article>)}{!items.length && <div className="panel empty-list"><span className="empty-art">✓</span><b>Your collection queue is clear</b><span>There are no unpaid invoices requiring follow-up right now.</span></div>}</section>}
  </main>;
}
