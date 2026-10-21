import type { Metadata } from "next";
import "@fontsource-variable/manrope/wght.css";
import "./globals.css";
import "./v1-features.css";
import "./landing.css";
import "./visual-refresh.css";
import "./font-system.css";
import "./brand-system.css";

export const metadata: Metadata = {
  title: { default: "DuePilot - Payment operations, under control", template: "%s | DuePilot" },
  description: "A multi-organization platform for billing, payments, collections and financial clarity.",
  icons: {
    icon: [{ url: "/favicon.svg", type: "image/svg+xml" }],
    shortcut: [{ url: "/favicon.svg", type: "image/svg+xml" }],
    apple: [{ url: "/duepilot-logo.svg", type: "image/svg+xml" }],
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
