import type { ApiResponse } from "@/types/api";
import type { Session } from "@/types/api";

export async function apiRequest<T>(path: string, init: RequestInit = {}): Promise<ApiResponse<T>> {
  try {
    const response = await fetch(`/api/backend/api/v1${path}`, {
      ...init,
      credentials: "include",
      headers: { "content-type": "application/json", ...init.headers },
    });
    const payload = await response.json().catch(() => null) as ApiResponse<T> | null;
    if (payload) return payload;
    return {
      ok: false,
      error: {
        code: response.status === 401 ? "AUTHENTICATION_REQUIRED" : "INVALID_RESPONSE",
        message: response.status === 401 ? "Your session has expired. Please sign in again." : "The server returned an unreadable response.",
      },
    };
  } catch {
    return { ok: false, error: { code: "NETWORK_ERROR", message: "DuePilot could not reach the workspace service. Check your connection and try again." } };
  }
}

export async function apiMutation<T>(path: string, body: unknown): Promise<ApiResponse<T>> {
  const session = await apiRequest<Session>("/auth/me");
  if (!session.ok) return session;
  return apiRequest<T>(path, {
    method: "POST",
    headers: { "x-csrf-token": session.data.csrfToken },
    body: JSON.stringify(body),
  });
}
