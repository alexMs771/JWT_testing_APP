"use client";

import { useEffect, useMemo, useState } from "react";
import { ProductIcon } from "@/components/product-icon";
import { apiRequest } from "@/lib/api";
import type { Customer } from "@/types/api";

const money = new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 });

export default function CustomersPage() {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [query, setQuery] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

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

  return <main className="product-page">
    <div className="page-heading"><div><span className="page-eyebrow">Customer health</span><h1>Know every account.</h1><p>See the people behind each balance, their payment behaviour, and where a relationship needs attention.</p></div><div className="heading-stat"><small>Open across accounts</small><strong>{money.format(totalOpen)}</strong></div></div>
    {error && <div className="form-error" role="alert">{error}</div>}
    <section className="panel customer-workspace"><div className="list-toolbar"><label><ProductIcon name="search" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search customer, contact, or email" /></label><span className="result-count">{visible.length} account{visible.length === 1 ? "" : "s"}</span></div>{loading ? <div className="list-loading">Loading customer records…</div> : <div className="customer-grid">{visible.map((customer) => <article key={customer.id}><header><span className="customer-avatar">{customer.initials}</span><div><h2>{customer.name}</h2><p>{customer.contact}</p><a href={`mailto:${customer.email}`}>{customer.email}</a></div><em className={`health ${customer.health}`}>{customer.health.replace(/_/g, " ")}</em></header><div className="customer-stats"><span><small>Open balance</small><b>{money.format(customer.outstanding)}</b></span><span><small>Overdue</small><b>{money.format(customer.overdue)}</b></span><span><small>Invoices</small><b>{customer.invoiceCount}</b></span></div></article>)}{!visible.length && <div className="empty-list"><span className="empty-art">◉</span><b>No customer records match</b><span>Check the search term and try again.</span></div>}</div>}</section>
  </main>;
}
