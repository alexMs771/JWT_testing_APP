"use client";

import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { ThemeToggle } from "@/components/theme-toggle";
import "./demo-v2.css";

type Screen = "home" | "roles" | "personal" | "business" | "customer" | "school" | "parent" | "college" | "student" | "admin" | "reports" | "reconcile" | "ai" | "integrations" | "guide";
type BillType = "personal" | "business" | "school" | "college";
type BillStatus = "open" | "partial" | "paid";
type Bill = { id: number; recipient: string; type: BillType; title: string; amount: number; paid: number; due: string; status: BillStatus; source?: string; category?: string; reference?: string; period?: "past" | "current" | "next" };
type AutopayStatus = "active" | "paused" | "action_required";
type Autopay = { id: number; provider: string; title: string; category: string; amount: number; frequency: "Monthly" | "Quarterly" | "Annual"; nextRun: string; account: string; status: AutopayStatus; lastRun: string };
type SubscriptionStatus = "active" | "ending_soon" | "paused";
type Subscription = { id: number; name: string; category: string; amount: number; cycle: "Monthly" | "Quarterly" | "Annual"; nextBilling: string; status: SubscriptionStatus; renewalNote: string; autopayId?: number };
type PersonalReminder = { id: number; title: string; detail: string; due: string; kind: "autopay" | "subscription" | "recharge" | "due"; status: "unread" | "scheduled" | "done"; tone: "teal" | "amber" | "coral" };
type DemoStore = { bills: Bill[]; students: string[]; plan: "Growth" | "Business"; activities: string[]; receipts: string[]; reminders: string[]; autopays: Autopay[]; subscriptions: Subscription[]; personalReminders: PersonalReminder[] };

const original: DemoStore = {
  bills: [
    { id: 9001, recipient: "Alex Personal", type: "personal", title: "Electricity bill", amount: 2840, paid: 0, due: "24 Oct 2026", status: "open", source: "TANGEDCO", category: "Utilities", reference: "TN-EB-482913", period: "current" },
    { id: 9002, recipient: "Alex Personal", type: "personal", title: "Bike EMI", amount: 6120, paid: 0, due: "5 Nov 2026", status: "open", source: "HDFC Bank", category: "Vehicle", reference: "•••• 3812", period: "next" },
    { id: 9003, recipient: "Alex Personal", type: "personal", title: "Traffic challan", amount: 1000, paid: 0, due: "14 Oct 2026", status: "open", source: "Government e-Challan", category: "Government", reference: "TN-09-AB-2727", period: "past" },
    { id: 9004, recipient: "Alex Personal", type: "personal", title: "Mobile subscription", amount: 799, paid: 799, due: "1 Oct 2026", status: "paid", source: "Jio", category: "Subscriptions", reference: "•••• 9044", period: "past" },
    { id: 9005, recipient: "Alex Personal", type: "personal", title: "Mobile recharge", amount: 299, paid: 0, due: "22 Oct 2026", status: "open", source: "Jio", category: "Recharge", reference: "•••• 9044", period: "current" },
    { id: 9006, recipient: "Alex Personal", type: "personal", title: "DTH recharge", amount: 399, paid: 0, due: "29 Oct 2026", status: "open", source: "Tata Play", category: "Recharge", reference: "•••• 1288", period: "current" },
    { id: 1001, recipient: "Kavya Retail", type: "business", title: "Website support retainer", amount: 48000, paid: 0, due: "18 Oct 2026", status: "open" },
    { id: 1002, recipient: "Ravi Kumar", type: "school", title: "Term 2 tuition fee", amount: 32000, paid: 12000, due: "12 Oct 2026", status: "partial" },
    { id: 1003, recipient: "Ananya Iyer", type: "college", title: "Semester 3 assessment", amount: 68500, paid: 0, due: "28 Oct 2026", status: "open" }
  ],
  students: ["Ravi Kumar", "Meera Shah"],
  plan: "Growth",
  activities: ["Reminder draft prepared for Kavya Retail", "School payment allocation verified", "Demo workspace restored"],
  receipts: ["RCPT-2026-1041 - Ravi Kumar - INR 12,000"],
  reminders: [],
  autopays: [
    { id: 9101, provider: "TANGEDCO", title: "Electricity bill", category: "Utilities", amount: 2840, frequency: "Monthly", nextRun: "24 Oct 2026", account: "UPI AutoPay •••• 4321", status: "active", lastRun: "24 Sep 2026" },
    { id: 9102, provider: "HDFC Bank", title: "Bike EMI", category: "Vehicle", amount: 6120, frequency: "Monthly", nextRun: "5 Nov 2026", account: "HDFC account •••• 3812", status: "active", lastRun: "5 Oct 2026" },
    { id: 9103, provider: "Jio", title: "Mobile postpaid", category: "Mobile", amount: 799, frequency: "Monthly", nextRun: "1 Nov 2026", account: "UPI AutoPay •••• 9044", status: "action_required", lastRun: "1 Oct 2026" }
  ],
  subscriptions: [
    { id: 9201, name: "Jio Postpaid", category: "Mobile plan", amount: 799, cycle: "Monthly", nextBilling: "1 Nov 2026", status: "active", renewalNote: "Renews automatically", autopayId: 9103 },
    { id: 9202, name: "Hotstar Mobile", category: "Streaming", amount: 149, cycle: "Monthly", nextBilling: "26 Oct 2026", status: "ending_soon", renewalNote: "Plan ends in 6 days" },
    { id: 9203, name: "Google One", category: "Cloud storage", amount: 130, cycle: "Monthly", nextBilling: "12 Nov 2026", status: "active", renewalNote: "Renews automatically" },
    { id: 9204, name: "Canva Pro trial", category: "Productivity", amount: 499, cycle: "Monthly", nextBilling: "28 Oct 2026", status: "ending_soon", renewalNote: "Trial ends in 8 days" }
  ],
  personalReminders: [
    { id: 9301, title: "Autopay needs attention", detail: "Jio payment method needs review before the next bill.", due: "Before 1 Nov 2026", kind: "autopay", status: "unread", tone: "coral" },
    { id: 9302, title: "Hotstar plan ends soon", detail: "Review the renewal before your current plan ends.", due: "26 Oct 2026", kind: "subscription", status: "unread", tone: "amber" },
    { id: 9303, title: "Mobile recharge due", detail: "Jio line ending 9044 is due for a recharge.", due: "22 Oct 2026", kind: "recharge", status: "scheduled", tone: "teal" },
    { id: 9304, title: "Electricity autopay scheduled", detail: "TANGEDCO will attempt INR 2,840 from your linked account.", due: "24 Oct 2026", kind: "autopay", status: "scheduled", tone: "teal" }
  ]
};

const personas: { name: string; description: string; screen: Screen; code: string }[] = [
  { name: "Business owner", description: "Invoices, collections, customers, and cash visibility.", screen: "business", code: "BO" },
  { name: "Personal user", description: "See connected bills, dues, payment options, and history.", screen: "personal", code: "PU" },
  { name: "Customer", description: "Only your authorized invoices, payment history, and receipts.", screen: "customer", code: "CU" },
  { name: "School administrator", description: "Students, fee assessments, parent payment, and reports.", screen: "school", code: "SA" },
  { name: "Accountant", description: "Reconcile settlements, allocation rules, and exceptions.", screen: "reconcile", code: "AC" },
  { name: "Platform administrator", description: "Organizations, subscriptions, revenue, and platform controls.", screen: "admin", code: "PA" },
  { name: "Parent or guardian", description: "View only family fee statements and receipts.", screen: "parent", code: "PG" },
  { name: "College administrator", description: "Semester assessments, enrollment, and collection performance.", screen: "college", code: "CA" },
  { name: "College student", description: "View your semester dues and simulated receipt history.", screen: "student", code: "CS" },
  { name: "Collections officer", description: "Priority accounts, reminders, and payment commitments.", screen: "ai", code: "CO" },
  { name: "Organization administrator", description: "Workspace operations, roles, and reporting.", screen: "business", code: "OA" },
  { name: "Teacher", description: "Authorized class context without finance administration access.", screen: "school", code: "TE" },
  { name: "Branch manager", description: "Assigned operations and branch-level collections.", screen: "business", code: "BM" }
];

const money = (value: number) => `INR ${value.toLocaleString("en-IN")}`;
const cloneOriginal = () => JSON.parse(JSON.stringify(original)) as DemoStore;
const loadDemoStore = () => {
  const base = cloneOriginal();
  if (typeof window === "undefined") return base;
  try {
    const saved = JSON.parse(localStorage.getItem("duepilot-demo-v2") || "") as Partial<DemoStore>;
    if (!saved || !Array.isArray(saved.bills)) return base;
    return { ...base, ...saved, bills: [...base.bills.filter((bill) => bill.type === "personal"), ...saved.bills.filter((bill) => bill.type !== "personal")] } as DemoStore;
  } catch { return base; }
};
const outstanding = (bill: Bill) => bill.amount - bill.paid;

export function DemoCenter() {
  const router = useRouter();
  const [screen, setScreen] = useState<Screen>("home");
  const [history, setHistory] = useState<Screen[]>(["home"]);
  const [store, setStore] = useState<DemoStore>(loadDemoStore);
  const [notice, setNotice] = useState("");
  const [invoiceTitle, setInvoiceTitle] = useState("");
  const [studentName, setStudentName] = useState("");
  const [assessmentTitle, setAssessmentTitle] = useState("");
  const [checkoutId, setCheckoutId] = useState<number | null>(null);
  const [paymentOutcome, setPaymentOutcome] = useState<"success" | "failed" | "pending">("success");
  const [personalMobile, setPersonalMobile] = useState("");
  const [personalAuthed, setPersonalAuthed] = useState(false);
  const [personalPeriod, setPersonalPeriod] = useState<"all" | "past" | "current" | "next">("current");
  const [aiQuestion, setAiQuestion] = useState("Which account should my team follow up with first?");
  const [tourIndex, setTourIndex] = useState(0);

  useEffect(() => { localStorage.setItem("duepilot-demo-v2", JSON.stringify(store)); }, [store]);

  const totals = useMemo(() => {
    const workspaceBills = store.bills.filter((bill) => bill.type !== "personal");
    const billed = workspaceBills.reduce((sum, bill) => sum + bill.amount, 0);
    const paid = workspaceBills.reduce((sum, bill) => sum + bill.paid, 0);
    return { billed, paid, open: billed - paid, active: workspaceBills.filter((bill) => outstanding(bill) > 0).length };
  }, [store]);

  const go = (next: Screen) => {
    if (next === "home" && screen !== "home") {
      router.push("/");
      return;
    }
    setScreen(next);
    setHistory((current) => current.at(-1) === next ? current : [...current, next]);
  };
  const back = () => {
    if (history.length <= 1) return;
    const next = history.at(-2) || "home";
    setHistory((current) => current.slice(0, -1));
    setScreen(next);
  };
  const reset = () => {
    if (!window.confirm("Restore all original demo data? This affects only this browser.")) return;
    setStore(cloneOriginal());
    setNotice("Original demo data restored. No real workspace or payment was changed.");
  };
  const createInvoice = () => {
    const title = invoiceTitle.trim();
    if (title.length < 3) { setNotice("Enter an invoice title with at least 3 characters."); return; }
    setStore((current) => ({ ...current, bills: [...current.bills, { id: Date.now(), recipient: "Kavya Retail", type: "business", title, amount: 25000, paid: 0, due: "30 Oct 2026", status: "open" }], activities: [`Invoice created: ${title}`, ...current.activities] }));
    setInvoiceTitle("");
    setNotice("Invoice created. It is now visible to Kavya Retail in the Customer portal.");
  };
  const createStudent = () => {
    const name = studentName.trim();
    if (name.length < 2) { setNotice("Enter a student name with at least 2 characters."); return; }
    if (store.students.some((student) => student.toLowerCase() === name.toLowerCase())) { setNotice("That student already exists in the demo roster."); return; }
    setStore((current) => ({ ...current, students: [...current.students, name], activities: [`Student enrolled: ${name}`, ...current.activities] }));
    setStudentName("");
    setNotice("Student enrolled in the Demo School workspace.");
  };
  const createAssessment = (type: "school" | "college", recipient: string, fallback: string, amount: number) => {
    const title = assessmentTitle.trim() || fallback;
    setStore((current) => ({ ...current, bills: [...current.bills, { id: Date.now(), recipient, type, title, amount, paid: 0, due: "30 Oct 2026", status: "open" }], activities: [`${type === "school" ? "Fee" : "Semester"} assessment created: ${title}`, ...current.activities] }));
    setAssessmentTitle("");
    setNotice("Assessment created and scoped to the correct recipient portal.");
  };
  const completePayment = () => {
    const bill = store.bills.find((item) => item.id === checkoutId);
    if (!bill) return;
    if (paymentOutcome !== "success") {
      setStore((current) => ({ ...current, activities: [`${paymentOutcome === "failed" ? "Failed" : "Pending"} payment recorded for ${bill.title}`, ...current.activities] }));
      setNotice(paymentOutcome === "failed" ? "Simulated payment failed. The outstanding balance is unchanged." : "Simulated payment is pending. The outstanding balance is unchanged.");
      setCheckoutId(null);
      return;
    }
    const receipt = `RCPT-${Date.now().toString().slice(-6)} - ${bill.recipient} - ${money(outstanding(bill))}`;
    setStore((current) => ({ ...current, bills: current.bills.map((item) => item.id === bill.id ? { ...item, paid: item.amount, status: "paid" } : item), receipts: [receipt, ...current.receipts], activities: [`Payment received and allocated: ${bill.title}`, ...current.activities] }));
    setNotice(`Payment simulated successfully. Receipt ${receipt.split(" - ")[0]} was created and all demo reports were updated.`);
    setCheckoutId(null);
  };

  const billsFor = (type: BillType, recipient?: string) => store.bills.filter((bill) => bill.type === type && (!recipient || bill.recipient === recipient));
  const personalBills = billsFor("personal");
  const visiblePersonalBills = personalBills.filter((bill) => personalPeriod === "all" || bill.period === personalPeriod);
  const personalOpen = personalBills.filter((bill) => outstanding(bill) > 0);
  const personalPastDue = personalBills.filter((bill) => bill.period === "past" && outstanding(bill) > 0);
  const personalCurrentDue = personalBills.filter((bill) => bill.period === "current" && outstanding(bill) > 0);
  const signInPersonal = () => {
    const cleanMobile = personalMobile.replace(/\D/g, "");
    if (!/^[6-9]\d{9}$/.test(cleanMobile)) { setNotice("Enter a valid 10-digit Indian mobile number for the demo."); return; }
    setPersonalAuthed(true);
    setNotice("Demo identity verified. Only fictional linked dues are being shown.");
  };
  const toggleAutopay = (autopayId: number) => {
    const autopay = store.autopays.find((item) => item.id === autopayId);
    if (!autopay) return;
    const nextStatus: AutopayStatus = autopay.status === "active" ? "paused" : "active";
    setStore((current) => ({ ...current, autopays: current.autopays.map((item) => item.id === autopayId ? { ...item, status: nextStatus } : item), personalReminders: current.personalReminders.map((item) => item.id === 9304 && autopayId === 9101 ? { ...item, status: nextStatus === "active" ? "scheduled" : "done" } : item) }));
    setNotice(`${autopay.title} autopay ${nextStatus === "active" ? "enabled" : "paused"} for this demo.`);
  };
  const updatePersonalReminder = (reminderId: number, status: PersonalReminder["status"]) => {
    setStore((current) => ({ ...current, personalReminders: current.personalReminders.map((item) => item.id === reminderId ? { ...item, status } : item) }));
    setNotice(status === "done" ? "Reminder marked as handled." : "Reminder scheduled for this demo account.");
  };
  const invoiceTable = (items: Bill[], paymentAllowed = false) => <section className="dc-table-card"><header><div><span>LIVE DEMO RECORDS</span><h2>Financial records</h2></div><p>{items.length} record{items.length === 1 ? "" : "s"}</p></header><div className="dc-table-head"><span>Record</span><span>Status</span><span>Outstanding</span><span /></div>{items.map((bill) => <article key={bill.id}><div><b>{bill.title}</b><small>{bill.recipient} | Due {bill.due}</small></div><em className={bill.status}>{bill.status}</em><strong>{money(outstanding(bill))}</strong>{paymentAllowed && outstanding(bill) > 0 ? <button onClick={() => setCheckoutId(bill.id)}>Pay now</button> : <span className="dc-row-arrow">View</span>}</article>)}{!items.length && <div className="dc-empty">No authorized records are available for this persona.</div>}</section>;

  const nav: { label: string; target: Screen; icon: string }[] = [
    { label: "Personal dues", target: "personal", icon: "PD" }, { label: "Overview", target: "business", icon: "OV" }, { label: "Customers", target: "customer", icon: "CU" }, { label: "Billing", target: "business", icon: "BL" },
    { label: "Payments", target: "reconcile", icon: "PY" }, { label: "Collections", target: "ai", icon: "CL" }, { label: "Reports", target: "reports", icon: "RP" }, { label: "DuePilot AI", target: "ai", icon: "AI" }
  ];
  const shell = (title: string, subtitle: string, active: Screen, content: React.ReactNode) => <div className="dc-app"><aside className="dc-sidebar"><Link className="dc-brand" href="/" aria-label="Exit demo and return to DuePilot home"><Image src="/duepilot-logo.svg" alt="DuePilot" width={116} height={83} priority /></Link><button className="dc-tenant" onClick={() => go("roles")}><span>AT</span><div><small>Demo workspace</small><b>Apex Technologies</b></div><i>Switch</i></button><nav aria-label="Demo workspace navigation">{nav.map((item) => <button key={item.label} className={active === item.target ? "active" : ""} onClick={() => go(item.target)}><i>{item.icon}</i><span>{item.label}</span></button>)}</nav><div className="dc-sidebar-footer"><span>SIMULATED ENVIRONMENT</span><button onClick={() => go("guide")}>Guided tour</button><button onClick={() => go("integrations")}>Integrations</button><button onClick={reset}>Reset data</button></div></aside><section className="dc-app-main"><header className="dc-topbar"><div className="dc-breadcrumb"><Link className="dc-exit-demo" href="/">Main site</Link>{history.length > 1 && <button className="dc-back" onClick={back}>← Back</button>}<span>Demo mode</span><b>/</b><strong>{title}</strong></div><div><button className="dc-top-action" onClick={() => setNotice("Notification center: 3 collection reminders and 1 reconciliation exception are ready for review.")}>Notifications</button><button className="dc-top-action" onClick={() => go("guide")}>Help</button><ThemeToggle /><Link className="dc-live-login" href="/login">Sign in to live workspace</Link></div></header><main className="dc-app-content"><section className="dc-page-title"><div><span>DEMO MODE / {active.toUpperCase()}</span><h1>{title}</h1><p>{subtitle}</p></div><div className="dc-context"><i /> Sample data only<br/><b>{money(totals.open)} outstanding</b></div></section>{content}</main></section></div>;

  const home = <main className="dc-marketing"><header className="dc-marketing-nav"><Link href="/" className="dc-logo"><Image src="/duepilot-logo.svg" alt="DuePilot" width={130} height={93} priority /></Link><nav><button onClick={() => go("roles")}>Explore roles</button><button onClick={() => go("guide")}>How it works</button><button onClick={() => go("integrations")}>Integrations</button></nav><div><ThemeToggle /><Link href="/login">Live sign in</Link></div></header><section className="dc-hero"><div><span className="dc-kicker"><i /> SAFE, CLICKABLE PRODUCT TOUR</span><h1>Explore DuePilot <em>in action.</em></h1><p>One connected financial operations workspace for billing, collections, payments, and insight across businesses, schools, and colleges.</p><div className="dc-hero-actions"><button onClick={() => go("roles")}>Start exploring <b>{"->"}</b></button><button className="outline" onClick={() => go("guide")}>Take a guided tour</button><Link href="/login">Sign in to real workspace</Link></div><ul><li>No demo login required</li><li>Sample data only</li><li>No money is charged</li></ul></div><DashboardPreview totals={totals} /></section><section className="dc-explorer"><div className="dc-section-intro"><div><span className="dc-kicker">CHOOSE YOUR LENS</span><h2>Where would you like to start?</h2></div><p>Each role opens a focused workspace with the right data, actions, and permissions.</p></div><div className="dc-lens-grid">{personas.slice(0, 5).map((persona) => <button key={persona.name} onClick={() => go(persona.screen)}><span>{persona.code}</span><div><b>{persona.name}</b><small>{persona.description}</small></div><i>{"->"}</i></button>)}</div></section><section className="dc-story"><span className="dc-kicker">ONE ENGINE, EVERY CONTEXT</span><h2>Follow every due forward.</h2><p>Start a connected business, school, college, platform, or AI scenario without affecting the real product database.</p><div>{[["Business", "business"], ["School fees", "school"], ["College fees", "college"], ["Platform admin", "admin"], ["DuePilot AI", "ai"]].map(([label, target]) => <button key={label} onClick={() => go(target as Screen)}>{label} <b>{"->"}</b></button>)}</div></section></main>;

  const roles = <main className="dc-role-page"><header><span className="dc-kicker"><i /> DEMO PERSONAS</span><h1>Choose your demo <em>experience.</em></h1><p>Each entry is an isolated fictional tenant or authorized user view. Use the real sign-in only when you want to access your actual backend workspace.</p></header><section>{personas.map((persona) => <button key={persona.name} onClick={() => { go(persona.screen); setNotice(`${persona.name} opened with an appropriately scoped sample dataset.`); }}><span>{persona.code}</span><div><b>{persona.name}</b><small>{persona.description}</small></div><i>Enter {"->"}</i></button>)}</section><footer><Link href="/login">Already have a DuePilot account? Sign in to the live workspace {"->"}</Link></footer></main>;

  const personal = !personalAuthed ? <main className="dc-personal-login"><header><Link href="/demo" className="dc-logo"><Image src="/duepilot-logo.svg" alt="DuePilot" width={130} height={93} priority /></Link><span className="dc-kicker">PERSONAL DUES DEMO</span></header><section><div className="dc-personal-login-copy"><span className="dc-kicker"><i /> ONE VIEW FOR EVERY DUE</span><h1>Know what needs to be paid next.</h1><p>See connected electricity, vehicle, subscription, and government dues in one calm dashboard.</p><ul><li>Mobile number is used only to enter this demo</li><li>Sample sources and amounts only</li><li>No bank credentials or payment is collected</li></ul></div><form className="dc-personal-login-card" onSubmit={(event) => { event.preventDefault(); signInPersonal(); }}><span className="dc-kicker">DEMO IDENTITY</span><h2>Continue with mobile</h2><p>We’ll show a fictional personal account after validation.</p><label>Mobile number<input value={personalMobile} onChange={(event) => setPersonalMobile(event.target.value)} inputMode="numeric" autoComplete="tel" maxLength={10} placeholder="98765 43210" /></label><button type="submit">Open personal dashboard <b>{"->"}</b></button><small>Use any valid 10-digit Indian mobile number. No OTP is sent in this demo.</small></form></section><footer><button onClick={() => go("roles")}>Back to demo personas</button><Link href="/login">Sign in to live workspace</Link></footer></main> : shell("Alex’s personal dues", "A consent-based view of connected obligations, payment history, and what is coming next.", "personal", <><section className="dc-personal-summary"><div><span className="dc-kicker">CONNECTED PERSONAL ACCOUNT</span><h2>Good morning, Alex.</h2><p>Last synced just now · {personalBills.length} sample sources connected</p></div><button className="quiet" onClick={() => { setPersonalAuthed(false); setPersonalMobile(""); }}>Sign out demo</button></section><section className="dc-metrics"><Metric label="Total to pay" value={money(personalOpen.reduce((sum, bill) => sum + outstanding(bill), 0))} hint={`${personalOpen.length} open dues`} tone="coral" /><Metric label="Past due" value={money(personalPastDue.reduce((sum, bill) => sum + outstanding(bill), 0))} hint={`${personalPastDue.length} needs attention`} tone="amber" /><Metric label="Due this month" value={money(personalCurrentDue.reduce((sum, bill) => sum + outstanding(bill), 0))} hint="Current period obligations" tone="teal" /><Metric label="Paid history" value={money(personalBills.reduce((sum, bill) => sum + bill.paid, 0))} hint="Verified demo payments" tone="navy" /></section><section className="dc-personal-toolbar"><div><span className="dc-kicker">TIME VIEW</span><h2>Plan your payments</h2></div><div>{(["all", "past", "current", "next"] as const).map((period) => <button key={period} className={personalPeriod === period ? "active" : ""} onClick={() => setPersonalPeriod(period)}>{period === "all" ? "All dues" : period === "past" ? "Past month" : period === "current" ? "This month" : "Next month"}</button>)}</div></section><section className="dc-personal-grid"><section className="dc-due-list"><header><div><span className="dc-kicker">PAYMENT PLAN</span><h2>{personalPeriod === "all" ? "All connected dues" : personalPeriod === "past" ? "Past month" : personalPeriod === "current" ? "This month" : "Next month"}</h2></div><p>{visiblePersonalBills.length} item{visiblePersonalBills.length === 1 ? "" : "s"}</p></header>{visiblePersonalBills.map((bill) => <article className={`dc-due-card ${bill.status}`} key={bill.id}><span className="dc-due-icon">{bill.category?.slice(0, 2).toUpperCase()}</span><div><small>{bill.source} · {bill.category}</small><h3>{bill.title}</h3><p>{bill.reference} · Due {bill.due}</p></div><strong>{money(outstanding(bill))}</strong>{outstanding(bill) > 0 ? <button onClick={() => setCheckoutId(bill.id)}>Pay now <b>{"->"}</b></button> : <em>Paid</em>}</article>)}{!visiblePersonalBills.length && <div className="dc-empty">No dues are available for this time period.</div>}</section><aside className="dc-personal-side"><section><span className="dc-kicker">SMART PRIORITY</span><h2>Start with electricity.</h2><p>Your electricity bill is due this month and has the nearest active deadline. Pay it first to avoid late charges.</p><button onClick={() => setCheckoutId(personalCurrentDue[0]?.id || null)}>Review priority <b>{"->"}</b></button></section><section><span className="dc-kicker">CONNECTED SOURCES</span><h2>Your sources</h2>{personalBills.map((bill) => <p key={bill.source}><i />{bill.source}<small>{bill.category}</small></p>)}<button className="quiet" onClick={() => setNotice("Source connection is simulated. A live product would request consent and provider verification here.")}>Connect another source</button></section></aside></section></>);

  const business = shell("Apex Technologies", "A business-owner view of active receivables, collections, and customer payment activity.", "business", <><section className="dc-metrics"><Metric label="Collected this month" value={money(totals.paid)} hint="Sample allocation data" tone="teal" /><Metric label="Outstanding receivables" value={money(totals.open)} hint={`${totals.active} accounts need attention`} tone="navy" /><Metric label="Collection rate" value={`${totals.billed ? Math.round((totals.paid / totals.billed) * 100) : 0}%`} hint="Based on demo records" tone="amber" /><Metric label="Due today" value={`${totals.active} records`} hint="Open collection actions" tone="coral" /></section><section className="dc-two-column"><section className="dc-action-card"><span>CREATE RECEIVABLE</span><h2>Issue a new invoice</h2><p>Create a sample invoice for Kavya Retail. It becomes immediately visible in the scoped customer portal.</p><label>Invoice title<input value={invoiceTitle} onChange={(event) => setInvoiceTitle(event.target.value)} placeholder="Implementation milestone" /></label><button onClick={createInvoice}>Create simulated invoice</button></section><section className="dc-activity-card"><span>RECENT ACTIVITY</span><h2>What changed in this scenario</h2>{store.activities.slice(0, 4).map((item) => <p key={item}><i />{item}</p>)}<button className="quiet" onClick={() => go("ai")}>Open collection assistant</button></section></section>{invoiceTable(billsFor("business"))}</>);

  const customer = shell("Kavya Retail", "This customer portal only exposes invoices, payments, and receipts authorized for this fictional customer.", "customer", <><section className="dc-metrics"><Metric label="Outstanding" value={money(billsFor("business", "Kavya Retail").reduce((sum, bill) => sum + outstanding(bill), 0))} hint="Across permitted invoices" tone="coral" /><Metric label="Open invoices" value={`${billsFor("business", "Kavya Retail").filter((bill) => outstanding(bill) > 0).length}`} hint="Payment options available" tone="navy" /><Metric label="Receipts" value={`${store.receipts.length}`} hint="Demo receipt history" tone="teal" /></section>{invoiceTable(billsFor("business", "Kavya Retail"), true)}<section className="dc-receipts"><div><span>RECEIPTS AND HISTORY</span><h2>Payment history</h2></div>{store.receipts.slice(0, 3).map((receipt) => <p key={receipt}>{receipt}</p>)}</section></>);

  const school = shell("Greenfield Public School", "School administration with roster changes, fee assessment creation, and parent-scoped payments.", "school", <><section className="dc-metrics"><Metric label="Students" value={`${store.students.length}`} hint="Class 8A demo roster" tone="teal" /><Metric label="Fee outstanding" value={money(billsFor("school").reduce((sum, bill) => sum + outstanding(bill), 0))} hint="Across fee assessments" tone="coral" /><Metric label="Collection rate" value={`${billsFor("school").length ? Math.round((billsFor("school").reduce((sum, bill) => sum + bill.paid, 0) / billsFor("school").reduce((sum, bill) => sum + bill.amount, 0)) * 100) : 0}%`} hint="Current demo data" tone="navy" /></section><section className="dc-two-column"><section className="dc-action-card"><span>CLASSROOM ROSTER</span><h2>Enroll a student</h2><div className="dc-pill-list">{store.students.map((student) => <span key={student}>{student}</span>)}</div><label>Student name<input value={studentName} onChange={(event) => setStudentName(event.target.value)} placeholder="Student name" /></label><button onClick={createStudent}>Enroll student</button></section><section className="dc-action-card"><span>FEE ASSESSMENT</span><h2>Create an assessment</h2><p>This creates a fictional INR 18,000 assessment for Ravi Kumar and updates the Parent portal.</p><label>Assessment title<input value={assessmentTitle} onChange={(event) => setAssessmentTitle(event.target.value)} placeholder="Optional title" /></label><button onClick={() => createAssessment("school", "Ravi Kumar", "Activity fee assessment", 18000)}>Create assessment</button><button className="quiet" onClick={() => go("parent")}>Open Parent portal</button></section></section>{invoiceTable(billsFor("school"))}</>);

  const parent = shell("Ravi Kumar family", "A parent can see only their child fee statement, payment options, and receipts.", "parent", <><section className="dc-family"><span>RK</span><div><small>AUTHORIZED FAMILY</small><h2>Ravi Kumar | Class 8A</h2><p>Greenfield Public School, 2026-27 academic year</p></div><button className="quiet" onClick={() => go("school")}>Return to School Admin</button></section>{invoiceTable(billsFor("school", "Ravi Kumar"), true)}</>);

  const college = shell("Crescent College", "Semester collection controls for college administrators and a student-scoped fee portal.", "college", <><section className="dc-metrics"><Metric label="Current semester" value="Semester 3" hint="Computer Science" tone="navy" /><Metric label="Outstanding fees" value={money(billsFor("college").reduce((sum, bill) => sum + outstanding(bill), 0))} hint="Student assessment records" tone="coral" /><Metric label="Collection status" value="In progress" hint="Demo data" tone="teal" /></section><section className="dc-two-column"><section className="dc-action-card"><span>SEMESTER ASSESSMENT</span><h2>Create an assessment</h2><p>Create a fictional INR 42,000 assessment for Ananya Iyer. The Student portal updates at once.</p><label>Assessment title<input value={assessmentTitle} onChange={(event) => setAssessmentTitle(event.target.value)} placeholder="Optional title" /></label><button onClick={() => createAssessment("college", "Ananya Iyer", "Semester lab assessment", 42000)}>Create assessment</button></section><section className="dc-activity-card"><span>ACADEMIC CONTEXT</span><h2>Current enrollment</h2><p><i />Computer Science, B.Tech</p><p><i />Semester 3, 2026-27</p><p><i />Authorized student: Ananya Iyer</p><button className="quiet" onClick={() => go("student")}>Open Student portal</button></section></section>{invoiceTable(billsFor("college"))}</>);

  const student = shell("Ananya Iyer", "A college student sees only their enrollment, assessment records, payments, and receipt history.", "student", <><section className="dc-family"><span>AI</span><div><small>STUDENT PROFILE</small><h2>B.Tech Computer Science | Semester 3</h2><p>Crescent College, 2026-27 academic year</p></div><button className="quiet" onClick={() => go("college")}>Return to College Admin</button></section>{invoiceTable(billsFor("college", "Ananya Iyer"), true)}</>);

  const admin = shell("DuePilot Super Admin", "Platform-level visibility is separate from each organization private financial workspace.", "admin", <><section className="dc-metrics"><Metric label="Demo organizations" value="7" hint="5 active, 2 trial" tone="navy" /><Metric label="Active subscriptions" value="5" hint="Illustrative data" tone="teal" /><Metric label="Illustrative MRR" value="INR 2.84L" hint="Not real platform revenue" tone="amber" /><Metric label="Renewal alerts" value="2" hint="Next 30 days" tone="coral" /></section><section className="dc-two-column"><section className="dc-org-directory"><header><span>ORGANIZATION DIRECTORY</span><h2>Fictional tenants</h2></header>{[["Vasanth Electronics", "Business", "Growth"], ["Greenfield Public School", "Education", "Trial"], ["Crescent College", "Education", "Business"], ["Apex Technologies", "IT services", store.plan]].map(([name, type, plan]) => <p key={name}><span>{name.slice(0, 2).toUpperCase()}</span><b>{name}<small>{type}</small></b><em>{plan}</em></p>)}</section><section className="dc-action-card"><span>SUBSCRIPTION SIMULATION</span><h2>Plan controls</h2><p>Apex Technologies is currently on the <b>{store.plan}</b> plan. A simulated change updates this demo state only.</p><button onClick={() => { setStore((current) => ({ ...current, plan: current.plan === "Growth" ? "Business" : "Growth", activities: ["Subscription plan changed in Platform Admin demo", ...current.activities] })); setNotice("Demo subscription updated. No billing system or payment was contacted."); }}>Switch Growth / Business</button><button className="quiet" onClick={() => go("integrations")}>Open Integration Center</button></section></section></>);

  const reports = shell("Collection reports", "All figures are calculated from the current in-browser demo dataset.", "reports", <><section className="dc-metrics"><Metric label="Billed" value={money(totals.billed)} hint={`${store.bills.length} total records`} tone="navy" /><Metric label="Collected" value={money(totals.paid)} hint="Valid simulated allocations" tone="teal" /><Metric label="Outstanding" value={money(totals.open)} hint={`${totals.active} active records`} tone="coral" /><Metric label="Collection rate" value={`${totals.billed ? Math.round(totals.paid / totals.billed * 100) : 0}%`} hint="Across demo records" tone="amber" /></section><section className="dc-report-grid"><section className="dc-chart-card"><header><span>COLLECTION PERFORMANCE</span><h2>Payments and receivables</h2></header><div className="dc-bars">{[37, 53, 47, 68, 62, 82, 96].map((height, index) => <i key={index} style={{ height: `${height}%` }}><small>W{index + 1}</small></i>)}</div><footer><span><i /> Collected</span><span><i /> Expected</span></footer></section><section className="dc-aging"><header><span>RECEIVABLES AGING</span><h2>Open balances</h2></header>{[["0-30 days", 54], ["31-60 days", 29], ["61-90 days", 12], ["90+ days", 5]].map(([label, value]) => <p key={label}><span>{label}</span><b>{value}%</b><i><em style={{ width: `${value}%` }} /></i></p>)}</section></section>{invoiceTable(store.bills)}</>);

  const reconcile = shell("Reconciliation center", "Review matched, unmatched, and duplicate payment events without a real bank connection.", "reconcile", <section className="dc-reconcile-grid"><section className="dc-reconcile-card"><span className="success">MATCHED</span><h2>UPI-DP-10382</h2><p>Kavya Retail | INR 48,000</p><small>Matched by reference and amount. One valid allocation only.</small></section><section className="dc-reconcile-card"><span className="warning">REVIEW REQUIRED</span><h2>REF-8821</h2><p>Amount mismatch of INR 500</p><small>No balance was changed while the exception remains unresolved.</small><button onClick={() => { setStore((current) => ({ ...current, activities: ["Reconciliation discrepancy reviewed", ...current.activities] })); setNotice("Exception marked as reviewed in the simulated audit history."); }}>Mark reviewed</button></section><section className="dc-reconcile-card"><span className="neutral">DUPLICATE EVENT</span><h2>Webhook duplicate</h2><p>Duplicate payment notification</p><small>Protected from creating a second allocation.</small></section></section>);

  const ai = shell("DuePilot AI", "Guidance is evidence-led and needs human approval. This screen uses deterministic demo responses.", "ai", <section className="dc-ai-layout"><section className="dc-ai-chat"><header><span>AI FINANCIAL ASSISTANT</span><h2>Ask about this workspace</h2><small>Demo response; no external model is called from this screen.</small></header><div className="dc-ai-response"><p>{aiQuestion}</p><b>Prioritize Kavya Retail.</b><span>It has the largest open business balance, no recorded payment promise, and an upcoming due date. The recommendation is based on the current simulated records.</span><div><em>Evidence: {money(billsFor("business", "Kavya Retail").reduce((sum, bill) => sum + outstanding(bill), 0))} open balance</em><em>Human approval required</em></div></div><label>Ask another question<input value={aiQuestion} onChange={(event) => setAiQuestion(event.target.value)} /></label><button onClick={() => setNotice("Demo analysis refreshed from the current simulated dataset.")}>Generate demo answer</button></section><section className="dc-ai-actions"><span>RECOMMENDED NEXT ACTION</span><h2>Draft a reminder</h2><p>Prepare a polite reminder for Kavya Retail and retain human control over sending.</p><button onClick={() => { setStore((current) => ({ ...current, reminders: ["Reminder draft approved for Kavya Retail", ...current.reminders], activities: ["AI reminder draft approved for Kavya Retail", ...current.activities] })); setNotice("Reminder draft approved and recorded in demo communication history. Nothing was sent."); }}>Approve reminder draft</button><h3>Illustrative forecast</h3><p><b>7-day:</b> INR 32,000</p><p><b>30-day:</b> INR 1,16,500</p></section></section>);

  const integrations = shell("Integration center", "All statuses are intentionally truthful. Demo actions never connect to external services.", "integrations", <section className="dc-integrations">{[["Payment gateways", "Demo only", "Use simulated payment outcomes without collecting payment credentials."], ["Accounting software", "Configuration required", "Preview how invoices would sync after a connection is configured."], ["Bank settlements", "Not connected", "No bank account or settlement feed is linked in this demo."], ["WhatsApp messaging", "Disabled", "A reminder preview can be created but is not delivered."], ["CSV import", "Demo ready", "Review a safe sample import workflow."], ["AI services", "Available in live workspace", "Production AI configuration remains protected by environment settings."]].map(([name, status, description]) => <article key={name}><span className={status === "Demo ready" ? "ready" : ""}>{status}</span><h2>{name}</h2><p>{description}</p><button onClick={() => setNotice(`${name}: demo test completed. No external service was contacted.`)}>Run safe demo test</button></article>)}</section>);

  const tour = [
    ["Business owner", "Create a receivable and review the collection queue.", "business"], ["Customer portal", "Open only the customer invoices and choose a safe simulated payment outcome.", "customer"], ["School fees", "Enroll a student, create a fee assessment, then open the parent portal.", "school"], ["College fees", "Create a semester assessment and review the student-scoped experience.", "college"], ["Platform admin", "Review sample organizations and simulate a plan change.", "admin"], ["Reports and AI", "Inspect calculations, reconciliation rules, and deterministic AI guidance.", "reports"]
  ] as const;
  const guide = <main className="dc-guide"><header><span className="dc-kicker"><i /> HOW TO USE DUEPILOT</span><h1>Understand the product<br/><em>without a sales call.</em></h1><p>Follow a connected scenario, switch personas safely, or enter your actual workspace through the backend sign-in.</p></header><section className="dc-tour-card"><div><span>GUIDED TOUR</span><h2>{tour[tourIndex][0]}</h2><p>{tour[tourIndex][1]}</p><small>Step {tourIndex + 1} of {tour.length}</small></div><div><button className="quiet" disabled={tourIndex === 0} onClick={() => setTourIndex((value) => Math.max(0, value - 1))}>Previous</button><button onClick={() => go(tour[tourIndex][2] as Screen)}>Open step</button><button className="quiet" onClick={() => setTourIndex((value) => Math.min(tour.length - 1, value + 1))}>Next</button><button className="linkish" onClick={() => { setTourIndex(0); go("home"); }}>Exit tour</button></div></section><section className="dc-guide-grid">{tour.map(([title, text, target], index) => <button key={title} onClick={() => { setTourIndex(index); go(target as Screen); }}><span>{String(index + 1).padStart(2, "0")}</span><b>{title}</b><small>{text}</small><i>{"->"}</i></button>)}</section><Link className="dc-live-panel" href="/login"><span>LIVE WORKSPACE</span><b>Sign in with your real DuePilot account {"->"}</b><small>This opens the backend-backed application, separate from resettable demo data.</small></Link></main>;

  const personalEnhanced = personalAuthed ? shell("Alex’s personal dues", "Bills, autopay schedules, subscriptions, recharges, and reminders in one personal view.", "personal", <PersonalDashboard bills={personalBills} visibleBills={visiblePersonalBills} openBills={personalOpen} pastDue={personalPastDue} period={personalPeriod} setPeriod={setPersonalPeriod} autopays={store.autopays} subscriptions={store.subscriptions} reminders={store.personalReminders} onPay={(billId) => setCheckoutId(billId)} onToggleAutopay={toggleAutopay} onReminderAction={updatePersonalReminder} onNotice={setNotice} onSignOut={() => { setPersonalAuthed(false); setPersonalMobile(""); }} />) : personal;
  const content: Record<Screen, React.ReactNode> = { home, roles, personal: personalEnhanced, business, customer, school, parent, college, student, admin, reports, reconcile, ai, integrations, guide };
  const checkoutBill = store.bills.find((bill) => bill.id === checkoutId);
  return <>{content[screen]}{notice && <div className="dc-toast" role="status"><span>{notice}</span><button onClick={() => setNotice("")} aria-label="Dismiss notification">Close</button></div>}{checkoutBill && <Checkout bill={checkoutBill} outcome={paymentOutcome} setOutcome={setPaymentOutcome} close={() => setCheckoutId(null)} submit={completePayment} />}</>;
}

type PersonalDashboardProps = {
  bills: Bill[];
  visibleBills: Bill[];
  openBills: Bill[];
  pastDue: Bill[];
  period: "all" | "past" | "current" | "next";
  setPeriod: (period: "all" | "past" | "current" | "next") => void;
  autopays: Autopay[];
  subscriptions: Subscription[];
  reminders: PersonalReminder[];
  onPay: (billId: number) => void;
  onToggleAutopay: (autopayId: number) => void;
  onReminderAction: (reminderId: number, status: PersonalReminder["status"]) => void;
  onNotice: (message: string) => void;
  onSignOut: () => void;
};

function PersonalDashboard({ bills, visibleBills, openBills, pastDue, period, setPeriod, autopays, subscriptions, reminders, onPay, onToggleAutopay, onReminderAction, onNotice, onSignOut }: PersonalDashboardProps) {
  const rechargeBills = bills.filter((bill) => bill.category === "Recharge");
  const endingSubscriptions = subscriptions.filter((subscription) => subscription.status === "ending_soon");
  const openReminders = reminders.filter((reminder) => reminder.status !== "done");
  const periodTitle = period === "all" ? "All connected dues" : period === "past" ? "Past month" : period === "current" ? "This month" : "Next month";
  const statusLabel = (status: AutopayStatus) => status === "action_required" ? "Needs attention" : status === "paused" ? "Paused" : "Active";
  const subscriptionStatusLabel = (status: SubscriptionStatus) => status === "ending_soon" ? "Ending soon" : status === "paused" ? "Paused" : "Active";

  return <>
    <section className="dc-personal-summary">
      <div><span className="dc-kicker">CONNECTED PERSONAL ACCOUNT</span><h2>Good morning, Alex.</h2><p>Last synced just now · {bills.length} sample obligations and {autopays.length} payment schedules connected</p></div>
      <button className="quiet" onClick={onSignOut}>Sign out demo</button>
    </section>

    <section className="dc-metrics">
      <Metric label="Total to pay" value={money(openBills.reduce((sum, bill) => sum + outstanding(bill), 0))} hint={`${openBills.length} open dues`} tone="coral" />
      <Metric label="Past due" value={money(pastDue.reduce((sum, bill) => sum + outstanding(bill), 0))} hint={`${pastDue.length} needs attention`} tone="amber" />
      <Metric label="Autopay next" value={money(autopays.filter((item) => item.status === "active").sort((a, b) => a.nextRun.localeCompare(b.nextRun))[0]?.amount || 0)} hint={`${autopays.filter((item) => item.status === "active").length} active schedules`} tone="teal" />
      <Metric label="Renewals soon" value={`${endingSubscriptions.length}`} hint="Subscription plans to review" tone="navy" />
    </section>

    <section className="dc-personal-toolbar">
      <div><span className="dc-kicker">TIME VIEW</span><h2>Plan your payments</h2></div>
      <div>{(["all", "past", "current", "next"] as const).map((value) => <button key={value} className={period === value ? "active" : ""} onClick={() => setPeriod(value)}>{value === "all" ? "All dues" : value === "past" ? "Past month" : value === "current" ? "This month" : "Next month"}</button>)}</div>
    </section>

    <section className="dc-personal-grid">
      <section className="dc-due-list">
        <header><div><span className="dc-kicker">PAYMENT PLAN</span><h2>{periodTitle}</h2></div><p>{visibleBills.length} item{visibleBills.length === 1 ? "" : "s"}</p></header>
        {visibleBills.map((bill) => <article className={`dc-due-card ${bill.status}`} key={bill.id}><span className="dc-due-icon">{bill.category?.slice(0, 2).toUpperCase()}</span><div><small>{bill.source} · {bill.category}</small><h3>{bill.title}</h3><p>{bill.reference} · Due {bill.due}</p></div><strong>{money(outstanding(bill))}</strong>{outstanding(bill) > 0 ? <button onClick={() => onPay(bill.id)}>Pay now <b>{"->"}</b></button> : <em>Paid</em>}</article>)}
        {!visibleBills.length && <div className="dc-empty">No dues are available for this time period.</div>}
      </section>

      <section className="dc-personal-panel dc-autopay-panel">
        <header><div><span className="dc-kicker">AUTOPAY CONTROL</span><h2>Upcoming payments</h2></div><button className="dc-inline-link" onClick={() => onNotice("Live bank and UPI connections require explicit provider consent. This demo only shows fictional schedules.")}>Manage all</button></header>
        <div className="dc-autopay-list">{autopays.map((autopay) => <article key={autopay.id}><span className={`dc-status-dot ${autopay.status}`} /><div><b>{autopay.provider}</b><small>{autopay.title} · {autopay.frequency}</small><small>{autopay.account}</small></div><strong>{money(autopay.amount)}</strong><p>Next run <b>{autopay.nextRun}</b></p><div className="dc-autopay-actions">{autopay.status === "action_required" ? <button className="dc-mini-button alert" onClick={() => onNotice(`${autopay.provider} autopay needs a valid payment method before ${autopay.nextRun}.`)}>Review</button> : <button className="dc-mini-button" onClick={() => onToggleAutopay(autopay.id)}>{autopay.status === "paused" ? "Resume" : "Pause"}</button>}<em className={autopay.status}>{statusLabel(autopay.status)}</em></div></article>)}</div>
        <footer><span><i className="dc-legend active" /> Active</span><span><i className="dc-legend paused" /> Paused</span><span><i className="dc-legend action_required" /> Needs attention</span></footer>
      </section>
    </section>

    <section className="dc-personal-feature-grid">
      <section className="dc-personal-panel dc-subscription-panel">
        <header><div><span className="dc-kicker">SUBSCRIPTIONS</span><h2>Plans and renewals</h2></div><span className="dc-count-badge">{subscriptions.length} active plans</span></header>
        <div className="dc-subscription-list">{subscriptions.map((subscription) => <article key={subscription.id}><span className="dc-subscription-icon">{subscription.name.slice(0, 1)}</span><div><b>{subscription.name}</b><small>{subscription.category} · {subscription.cycle}</small><p>{subscription.renewalNote}</p></div><strong>{money(subscription.amount)}<small>/{subscription.cycle === "Annual" ? "yr" : "mo"}</small></strong><div><em className={subscription.status}>{subscriptionStatusLabel(subscription.status)}</em><button className="dc-inline-link" onClick={() => onNotice(`${subscription.name} details opened. Renewal controls are simulated in this demo.`)}>Details</button></div></article>)}</div>
      </section>

      <section className="dc-personal-panel dc-recharge-panel">
        <header><div><span className="dc-kicker">RECHARGE TRACKER</span><h2>Keep services active</h2></div><span className="dc-count-badge">{rechargeBills.length} due</span></header>
        <p className="dc-panel-description">Upcoming mobile and DTH recharges are separated from recurring bills so you never miss a service renewal.</p>
        <div className="dc-recharge-list">{rechargeBills.map((bill) => <article key={bill.id}><span className="dc-recharge-icon">{bill.source?.slice(0, 1)}</span><div><b>{bill.title}</b><small>{bill.source} · {bill.reference}</small></div><div><strong>{money(outstanding(bill))}</strong><small>Due {bill.due}</small></div><button onClick={() => onPay(bill.id)}>Recharge</button></article>)}</div>
      </section>
    </section>

    <section className="dc-reminder-panel">
      <header><div><span className="dc-kicker">REMINDER CENTER</span><h2>Nothing important should surprise you.</h2><p>Autopay, renewal, recharge, and due-date notifications are kept together.</p></div><span className="dc-reminder-count">{openReminders.length} open</span></header>
      <div className="dc-reminder-list">{reminders.map((reminder) => <article className={reminder.status === "done" ? "done" : ""} key={reminder.id}><span className={`dc-reminder-icon ${reminder.tone}`}>{reminder.kind === "autopay" ? "AP" : reminder.kind === "subscription" ? "RE" : reminder.kind === "recharge" ? "RC" : "DU"}</span><div><b>{reminder.title}</b><p>{reminder.detail}</p><small>{reminder.due}</small></div><em className={reminder.status}>{reminder.status === "unread" ? "Unread" : reminder.status === "scheduled" ? "Scheduled" : "Handled"}</em>{reminder.status !== "done" && <button className="dc-mini-button" onClick={() => onReminderAction(reminder.id, "done")}>Mark handled</button>}</article>)}{!reminders.length && <div className="dc-empty">You have no personal reminders.</div>}</div>
    </section>

    <p className="dc-personal-disclaimer">Demo data only. DuePilot would request consent before connecting a bank, biller, recharge provider, or payment method. No real autopay is created from this page.</p>
  </>;
}

function Metric({ label, value, hint, tone }: { label: string; value: string; hint: string; tone: string }) { return <article className={`dc-metric ${tone}`}><span>{label}</span><strong>{value}</strong><small>{hint}</small></article>; }
function DashboardPreview({ totals }: { totals: { paid: number; open: number; active: number } }) { return <div className="dc-dashboard-preview" aria-label="Illustrative collection dashboard"><header><b>Collections overview</b><span>Live demo</span></header><small>Collected this month</small><strong>{money(totals.paid || 1842680)}</strong><em>Up 14.8% from last month</em><div className="dc-preview-line"><i /><i /><i /><i /><i /><i /><i /></div><footer><span>Outstanding<b>{money(totals.open || 680000)}</b></span><span>Collection rate<b>72.4%</b></span><span>Open actions<b>{totals.active || 18}</b></span></footer><aside><b>Payment received</b><small>INV-DEMO-1002 | INR 24,000</small></aside></div>; }
function Checkout({ bill, outcome, setOutcome, close, submit }: { bill: Bill; outcome: "success" | "failed" | "pending"; setOutcome: (value: "success" | "failed" | "pending") => void; close: () => void; submit: () => void }) { return <div className="dc-modal-backdrop" role="dialog" aria-modal="true" aria-labelledby="checkout-title"><section className="dc-checkout"><header><div><span>SIMULATED PAYMENT</span><h2 id="checkout-title">Pay {bill.title}</h2><p>No money, credentials, card number, UPI PIN, or OTP is collected.</p></div><button onClick={close} aria-label="Close checkout">Close</button></header><div className="dc-checkout-amount"><span>Outstanding amount</span><strong>{money(outstanding(bill))}</strong><small>{bill.recipient} | Due {bill.due}</small></div><fieldset><legend>Choose a safe demo outcome</legend>{(["success", "failed", "pending"] as const).map((value) => <label key={value}><input type="radio" checked={outcome === value} onChange={() => setOutcome(value)} />{value[0].toUpperCase() + value.slice(1)} {value === "success" ? "- creates receipt and allocation" : "- does not reduce the balance"}</label>)}</fieldset><footer><button className="quiet" onClick={close}>Cancel</button><button onClick={submit}>Complete simulated payment</button></footer></section></div>; }
