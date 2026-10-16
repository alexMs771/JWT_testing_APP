import type { Metadata } from "next";
import "./globals.css";
import "./v1-features.css";
import "./landing.css";

export const metadata: Metadata = {
  title: { default: "DuePilot - Payment operations, under control", template: "%s | DuePilot" },
  description: "A multi-organization platform for billing, payments, collections and financial clarity.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
