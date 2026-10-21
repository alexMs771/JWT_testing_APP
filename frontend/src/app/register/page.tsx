"use client";

import Image from "next/image";
import Link from "next/link";
import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { ProductIcon } from "@/components/product-icon";
import { ThemeToggle } from "@/components/theme-toggle";
import { apiRequest } from "@/lib/api";
import type { Session } from "@/types/api";

const organizationTypes = [["business", "Business / professional services"], ["school", "School"], ["college", "College"], ["coaching", "Coaching centre"], ["property", "Property management"], ["healthcare", "Healthcare"], ["subscription", "Subscription business"], ["other", "Other"]] as const;

export default function RegisterPage() {
  const router = useRouter();
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    const form = new FormData(event.currentTarget);
    const workspaceName = String(form.get("workspaceName") || "").trim();
    const name = String(form.get("name") || "").trim();
    const email = String(form.get("email") || "").trim().toLowerCase();
    const password = String(form.get("password") || "");
    if (workspaceName.length < 2 || name.length < 2) { setError("Enter a workspace name and your full name."); return; }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) { setError("Enter a valid work email address."); return; }
    if (!/^(?=.*[A-Za-z])(?=.*\d).{12,200}$/.test(password)) { setError("Use 12 or more characters with at least one letter and one number."); return; }
    setSubmitting(true);
    const result = await apiRequest<Session>("/auth/register", { method: "POST", body: JSON.stringify({ workspaceName, organizationType: form.get("organizationType"), name, email, password }) });
    setSubmitting(false);
    if (!result.ok) { setError(result.error.message); return; }
    router.replace("/app/dashboard");
    router.refresh();
  }

  return <main className="auth-page">
    <section className="auth-panel"><div className="auth-top"><div className="auth-brand"><Link href="/" className="auth-logo" aria-label="DuePilot home"><Image src="/duepilot-logo.svg" alt="DuePilot" width={132} height={94} priority /></Link><Link href="/" className="auth-home-link">← Back to home</Link></div><ThemeToggle /></div><div className="auth-card auth-register-card"><span className="section-kicker">Start your workspace</span><h1>Bring your receivables into focus.</h1><p>Create the secure workspace your finance team will use every day. You will be its first administrator.</p>{error && <div className="form-error" role="alert">{error}</div>}<form onSubmit={submit}><label htmlFor="workspaceName">Workspace name<input id="workspaceName" name="workspaceName" autoComplete="organization" maxLength={120} required placeholder="Acme Services Pvt Ltd" /></label><label htmlFor="organizationType">Organization type<select id="organizationType" name="organizationType" defaultValue="business">{organizationTypes.map(([value, label]) => <option value={value} key={value}>{label}</option>)}</select></label><label htmlFor="name">Your full name<input id="name" name="name" autoComplete="name" maxLength={120} required placeholder="Your name" /></label><label htmlFor="email">Work email<input id="email" name="email" type="email" autoComplete="email" maxLength={254} required placeholder="you@company.com" /></label><div className="label-row"><label htmlFor="password">Create password</label><span>12+ chars, letter + number</span></div><div className="password-field"><input id="password" name="password" type={showPassword ? "text" : "password"} autoComplete="new-password" minLength={12} maxLength={200} required /><button type="button" onClick={() => setShowPassword((value) => !value)} aria-label={showPassword ? "Hide password" : "Show password"}>{showPassword ? "Hide" : "Show"}</button></div><button className="button button-primary button-large button-block" disabled={submitting}>{submitting ? "Creating workspace..." : <>Create workspace <ProductIcon name="arrow" /></>}</button></form><p className="auth-switch">Already have an account? <Link href="/login">Sign in</Link></p></div><p className="auth-legal">By creating a workspace, you agree to DuePilot&apos;s Terms and Privacy Policy.</p></section>
    <section className="auth-story"><div className="auth-story-copy"><span>Designed for cash clarity</span><h2>Every balance. One accountable workflow.</h2><p>Create invoices, record customer commitments, and make the next collection move with the right context.</p></div><div className="auth-preview"><div className="auth-preview-head"><span><i /> Your private workspace</span><b>Ready when you are</b></div><div className="auth-preview-stats"><div><small>INVOICES</small><b>Structured</b><em>One clear source of truth</em></div><div><small>COLLECTIONS</small><b>Focused</b><em>Follow-up with context</em></div><div><small>INSIGHTS</small><b>Evidence-led</b><em>Guidance you can trust</em></div></div><div className="auth-chart"><div><span>Create</span><i style={{ height: "38%" }} /></div><div><span>Track</span><i style={{ height: "54%" }} /></div><div><span>Follow up</span><i style={{ height: "70%" }} /></div><div><span>Collect</span><i style={{ height: "84%" }} /></div></div></div></section>
  </main>;
}
