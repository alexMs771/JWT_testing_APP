import type { Session } from "@/types/api";

export type ToastTone = "success" | "info" | "warning" | "error";

export type ToastPayload = {
  tone: ToastTone;
  title: string;
  message: string;
  duration?: number;
  session?: Session;
};

export function notifyToast(payload: ToastPayload) {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new CustomEvent<ToastPayload>("duepilot:toast", { detail: payload }));
}
