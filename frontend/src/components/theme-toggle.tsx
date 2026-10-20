"use client";

import { useEffect, useState } from "react";

export function ThemeToggle({ className = "" }: { className?: string }) {
  const [dark, setDark] = useState(() => typeof window !== "undefined" && localStorage.getItem("duepilot-theme") === "dark");

  useEffect(() => {
    document.documentElement.dataset.theme = dark ? "dark" : "light";
  }, [dark]);

  function toggleTheme() {
    const next = !dark;
    setDark(next);
    document.documentElement.dataset.theme = next ? "dark" : "light";
    localStorage.setItem("duepilot-theme", next ? "dark" : "light");
  }

  return <button className={`theme-switch ${dark ? "is-dark" : ""} ${className}`} type="button" onClick={toggleTheme} aria-label={`Switch to ${dark ? "light" : "dark"} mode`} aria-pressed={dark} title={`Switch to ${dark ? "light" : "dark"} mode`} suppressHydrationWarning>
    <span className="theme-switch-icon" aria-hidden="true">
      {dark ? <svg viewBox="0 0 24 24" focusable="false"><path d="M20.4 15.2A8.3 8.3 0 0 1 8.8 3.6a8.7 8.7 0 1 0 11.6 11.6Z" /></svg> : <svg viewBox="0 0 24 24" focusable="false"><circle cx="12" cy="12" r="4" /><path d="M12 2v2M12 20v2M4.93 4.93l1.42 1.42M17.65 17.65l1.42 1.42M2 12h2M20 12h2M4.93 19.07l1.42-1.42M17.65 6.35l1.42-1.42" /></svg>}
    </span>
  </button>;
}
