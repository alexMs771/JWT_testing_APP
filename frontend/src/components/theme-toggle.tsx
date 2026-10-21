"use client";

import { useEffect, useSyncExternalStore } from "react";

const THEME_EVENT = "duepilot-theme-change";

function getThemeSnapshot() {
  if (typeof window === "undefined") return false;
  try {
    return window.localStorage.getItem("duepilot-theme") === "dark";
  } catch {
    return false;
  }
}

function subscribeToTheme(onChange: () => void) {
  const notify = () => onChange();
  window.addEventListener("storage", notify);
  window.addEventListener(THEME_EVENT, notify);
  return () => {
    window.removeEventListener("storage", notify);
    window.removeEventListener(THEME_EVENT, notify);
  };
}

function getServerThemeSnapshot() {
  return false;
}

export function ThemeToggle({ className = "" }: { className?: string }) {
  // useSyncExternalStore guarantees the same snapshot during SSR and the
  // hydration pass, then reads the saved browser preference safely afterward.
  const dark = useSyncExternalStore(subscribeToTheme, getThemeSnapshot, getServerThemeSnapshot);

  useEffect(() => {
    document.documentElement.dataset.theme = dark ? "dark" : "light";
  }, [dark]);

  function toggleTheme() {
    const next = !dark;
    document.documentElement.dataset.theme = next ? "dark" : "light";
    try {
      window.localStorage.setItem("duepilot-theme", next ? "dark" : "light");
      window.dispatchEvent(new Event(THEME_EVENT));
    } catch {
      // The visual toggle still works when browser storage is unavailable.
    }
  }

  return <button className={`theme-switch ${dark ? "is-dark" : ""} ${className}`} type="button" onClick={toggleTheme} aria-label={`Switch to ${dark ? "light" : "dark"} mode`} aria-pressed={dark} title={`Switch to ${dark ? "light" : "dark"} mode`} suppressHydrationWarning>
    <span className="theme-switch-icon" aria-hidden="true">
      {dark ? <svg viewBox="0 0 24 24" focusable="false"><path d="M20.4 15.2A8.3 8.3 0 0 1 8.8 3.6a8.7 8.7 0 1 0 11.6 11.6Z" /></svg> : <svg viewBox="0 0 24 24" focusable="false"><circle cx="12" cy="12" r="4" /><path d="M12 2v2M12 20v2M4.93 4.93l1.42 1.42M17.65 17.65l1.42 1.42M2 12h2M20 12h2M4.93 19.07l1.42-1.42M17.65 6.35l1.42-1.42" /></svg>}
    </span>
  </button>;
}
