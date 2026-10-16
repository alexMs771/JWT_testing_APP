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

  return <button className={`theme-switch ${dark ? "is-dark" : ""} ${className}`} type="button" onClick={toggleTheme} aria-label={`Switch to ${dark ? "light" : "dark"} mode`} aria-pressed={dark} suppressHydrationWarning><span className="theme-glyph theme-sun" aria-hidden="true" /><span className="theme-glyph theme-moon" aria-hidden="true" /><i /></button>;
}
