"use client";

import Image from "next/image";
import Link from "next/link";
import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { ProductIcon } from "@/components/product-icon";
import { ThemeToggle } from "@/components/theme-toggle";
import { apiRequest } from "@/lib/api";
import type { User, Workspace } from "@/types/api";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    const cleanEmail = email.trim().toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(cleanEmail)) { setError("Enter a valid work email address."); return; }
    if (password.length < 12) { setError("Your password must contain at least 12 characters."); return; }
    setSubmitting(true);
    const result = await apiRequest<{ user: User; workspace: Workspace }>("/auth/login", { method: "POST", body: JSON.stringify({ email: cleanEmail, password }) });
    setSubmitting(false);
    if (!result.ok) { setError(result.error.message); return; }
    router.push(result.data.user.isPlatformAdmin ? "/admin" : "/app/dashboard");
    router.refresh();
  }

  return <main className="auth-page">
    <section className="auth-panel">
      <div className="auth-top"><Link href="/" className="auth-logo" aria-label="DuePilot home"><Image src="/duepilot-logo.svg" alt="DuePilot" width={132} height={94} priority /></Link><ThemeToggle /></div>
      <div className="auth-card"><span className="section-kicker">Welcome back</span><h1>Continue to your workspace.</h1><p>See your current balances, collection priorities, and payment activity in one place.</p>{error && <div className="form-error" role="alert">{error}</div>}<form onSubmit={submit}><label htmlFor="email">Work email</label><input id="email" type="email" autoComplete="username" value={email} onChange={(event) => setEmail(event.target.value)} required maxLength={254} aria-invalid={Boolean(error)} /><div className="label-row"><label htmlFor="password">Password</label><a href="mailto:support@duepilot.app">Need help?</a></div><div className="password-field"><input id="password" type={showPassword ? "text" : "password"} autoComplete="current-password" value={password} onChange={(event) => setPassword(event.target.value)} required minLength={12} maxLength={200} aria-invalid={Boolean(error)} /><button type="button" onClick={() => setShowPassword((value) => !value)} aria-label={showPassword ? "Hide password" : "Show password"}>{showPassword ? "Hide" : "Show"}</button></div><button className="button button-primary button-large button-block" disabled={submitting}>{submitting ? "Signing in..." : <>Open workspace <ProductIcon name="arrow" /></>}</button></form><p className="auth-switch">New to DuePilot? <Link href="/register">Create your workspace</Link></p></div>
      <p className="auth-legal">By continuing, you agree to DuePilot&apos;s Terms and Privacy Policy.</p>
    </section>
    <section className="auth-story"><div className="auth-story-copy"><span>Receivables, under control</span><h2>Turn every balance into a clear next move.</h2><p>One workspace for billing, collections, customer context, and trusted cashflow intelligence.</p></div><div className="auth-preview"><div className="auth-preview-head"><span><i /> Operating today</span><b>Your workspace</b></div><div className="auth-preview-stats"><div><small>OPEN RECEIVABLES</small><b>In focus</b><em>Keep every balance visible</em></div><div><small>COLLECTIONS</small><b>On track</b><em>Work from clear priorities</em></div><div><small>CONTEXT</small><b>Connected</b><em>Every action is recorded</em></div></div><div className="auth-chart"><div><span>Create</span><i style={{ height: "38%" }} /></div><div><span>Track</span><i style={{ height: "54%" }} /></div><div><span>Follow up</span><i style={{ height: "70%" }} /></div><div><span>Collect</span><i style={{ height: "84%" }} /></div></div></div></section>
  </main>;
}
