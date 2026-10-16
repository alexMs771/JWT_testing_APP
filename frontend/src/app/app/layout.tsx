import { Suspense } from "react";
import { AppShell } from "@/components/app-shell";
import "./workspace-v2.css";

export default function WorkspaceLayout({ children }: { children: React.ReactNode }) {
  return <Suspense fallback={<div className="app-loading">Loading workspace...</div>}><AppShell>{children}</AppShell></Suspense>;
}
