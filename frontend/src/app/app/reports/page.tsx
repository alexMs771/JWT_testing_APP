"use client";

import { useEffect, useState } from "react";
import { ProductIcon } from "@/components/product-icon";
import { apiRequest } from "@/lib/api";
import type { Report } from "@/types/api";

const money = new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 });

export default function ReportsPage() {
  const [report, setReport] = useState<Report | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;
    apiRequest<Report>("/reports").then((result) => {
      if (!active) return;
      if (result.ok) setReport(result.data);
      else setError(result.error.message);
    });
    return () => { active = false; };
  }, []);

  if (error) return <main className="product-page"><div className="form-error" role="alert">{error}</div></main>;
  if (!report) return <main className="product-page"><div className="skeleton heading-skeleton" /></main>;

  const maxMonthly = Math.max(...report.monthly.map((item) => item.billed), 1);
  const aging = [["Current", report.aging.current], ["1–30 days", report.aging.oneToThirty], ["31–60 days", report.aging.thirtyOneToSixty], ["Over 60 days", report.aging.overSixty]] as const;

  return <main className="product-page">
    <div className="page-heading"><div><span className="page-eyebrow">Decision support</span><h1>See the shape of cash.</h1><p>Track collections performance, receivables risk, and customer concentration from verified workspace activity.</p></div><button className="button button-quiet" onClick={() => window.print()}>Export view <ProductIcon name="arrow" /></button></div>
    <section className="report-kpis"><article><small>Collection rate</small><strong>{report.collectionRate}%</strong><span>Verified cash received against billing</span></article><article><small>Average days to pay</small><strong>{report.avgDaysToPay}</strong><span>Across fully paid invoices</span></article><article><small>Promises kept</small><strong>{report.promiseKept}%</strong><span>Customer commitments honoured</span></article></section>
    <div className="report-grid"><section className="panel monthly-report"><header><div><span className="section-kicker">Cash performance</span><h2>Billed versus collected</h2><p>Monthly momentum across your receivables workflow.</p></div></header><div className="monthly-bars">{report.monthly.map((item) => <div key={item.label}><span>{item.label}</span><i><b style={{ width: `${(item.billed / maxMonthly) * 100}%` }} /><em style={{ width: `${(item.collected / maxMonthly) * 100}%` }} /></i><strong>{money.format(item.collected)}</strong></div>)}</div><footer><span><i className="billed" /> Billed</span><span><i /> Collected</span></footer></section><section className="panel aging-report"><header><div><span className="section-kicker">Receivables risk</span><h2>Aging breakdown</h2><p>Where open cash is sitting today.</p></div></header><div>{aging.map(([label, amount]) => <article key={label}><span><b>{label}</b><small>{report.aging.total ? Math.round((amount / report.aging.total) * 100) : 0}% of open receivables</small></span><strong>{money.format(amount)}</strong><i><b style={{ width: `${report.aging.total ? (amount / report.aging.total) * 100 : 0}%` }} /></i></article>)}</div></section></div>
    <section className="panel top-customer-report"><header><div><span className="section-kicker">Concentration</span><h2>Customers with the highest open balance</h2></div></header><div>{report.topCustomers.map((customer, index) => <article key={customer.id}><span>{String(index + 1).padStart(2, "0")}</span><div><b>{customer.name}</b><small>{customer.invoiceCount} invoice{customer.invoiceCount === 1 ? "" : "s"} · {customer.health.replace(/_/g, " ")}</small></div><strong>{money.format(customer.outstanding)}</strong></article>)}</div></section>
  </main>;
}
