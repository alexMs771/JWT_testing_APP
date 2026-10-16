type ProductIconName =
  | "dashboard"
  | "invoices"
  | "customers"
  | "collections"
  | "reports"
  | "settings"
  | "search"
  | "sparkle"
  | "sun"
  | "menu"
  | "arrow"
  | "close"
  | "check";

const glyphs: Record<ProductIconName, string> = {
  dashboard: "▦",
  invoices: "▤",
  customers: "◉",
  collections: "↗",
  reports: "◔",
  settings: "⚙",
  search: "⌕",
  sparkle: "✦",
  sun: "◐",
  menu: "☰",
  arrow: "→",
  close: "×",
  check: "✓",
};

export function ProductIcon({
  name,
  className = "",
}: {
  name: ProductIconName;
  className?: string;
}) {
  return <span className={`product-icon ${className}`} aria-hidden="true">{glyphs[name]}</span>;
}
