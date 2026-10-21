import { Suspense } from "react";
import { AppShell } from "@/components/app-shell";
import "./workspace-v2.css";
import "./workspace-brand.css";
import "./workspace-modern.css";
import "./billing-modern.css";
import "./workspace-polish.css";
import "./toast.css";
import "./workspace-refinement.css";

export default function WorkspaceLayout({ children }: { children: React.ReactNode }) {
  return <Suspense fallback={<div className="app-loading">Loading workspace...</div>}><AppShell>{children}</AppShell></Suspense>;
}
