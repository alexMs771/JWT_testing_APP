import type { ApiResponse } from "@/types/api";

const ACCESS_TOKEN_KEY = "duepilot-access-token";

function readAccessToken(): string {
  if (typeof window === "undefined") return "";
  try {
    return window.localStorage.getItem(ACCESS_TOKEN_KEY) ?? "";
  } catch {
    return "";
  }
}

function storeAccessToken(token: string): void {
  if (typeof window === "undefined" || !token) return;
  try {
    window.localStorage.setItem(ACCESS_TOKEN_KEY, token);
  } catch {
    // Private browsing or a storage policy can disable localStorage. The
    // current request can still succeed with its in-memory response token.
  }
}

function clearAccessToken(): void {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.removeItem(ACCESS_TOKEN_KEY);
  } catch {
    // Ignore storage cleanup failures during sign-out.
  }
}

function tokenFromPayload(payload: ApiResponse<unknown>): string {
  if (!payload.ok || !payload.data || typeof payload.data !== "object") return "";
  const data = payload.data as { accessToken?: unknown; session?: { accessToken?: unknown } };
  if (typeof data.accessToken === "string") return data.accessToken;
  return typeof data.session?.accessToken === "string" ? data.session.accessToken : "";
}

async function refreshAccessToken(): Promise<string> {
  try {
    const response = await fetch("/api/backend/api/v1/auth/refresh", {
      method: "POST",
      cache: "no-store",
      credentials: "include",
      headers: { accept: "application/json", "content-type": "application/json" },
    });
    const rawBody = await response.text();
    let payload: ApiResponse<{ accessToken?: string }> | null = null;
    try {
      payload = rawBody ? JSON.parse(rawBody) as ApiResponse<{ accessToken?: string }> : null;
    } catch {
      payload = null;
    }
    const token = payload?.ok && typeof payload.data?.accessToken === "string" ? payload.data.accessToken : "";
    if (token) storeAccessToken(token);
    if (!token && response.status === 401) clearAccessToken();
    return token;
  } catch {
    return "";
  }
}

function canRefreshFor(path: string): boolean {
  return !["/auth/login", "/auth/register", "/auth/refresh"].includes(path);
}

export async function apiRequest<T>(path: string, init: RequestInit = {}, allowRefresh = true): Promise<ApiResponse<T>> {
  try {
    // Subscription details are read-only. Keep this request GET even if an
    // older client component still passes a stale RequestInit object after a
    // hot reload or client-side navigation.
    const method = path === "/subscription" ? "GET" : (init.method ?? "GET");
    const headers = new Headers(init.headers);
    if (!headers.has("accept")) headers.set("accept", "application/json");
    if (!headers.has("content-type")) headers.set("content-type", "application/json");
    const accessToken = readAccessToken();
    if (accessToken) headers.set("authorization", `Bearer ${accessToken}`);

    const response = await fetch(`/api/backend/api/v1${path}`, {
      ...init,
      method,
      cache: method === "GET" ? "no-store" : init.cache,
      credentials: "include",
      headers,
    });

    const responseToken = response.headers.get("x-new-access-token");
    if (responseToken) storeAccessToken(responseToken);

    // Read once and parse explicitly. A ColdBox exception, reverse-proxy
    // error, or stale backend can return HTML/plain text; calling response.json
    // alone hides the useful status and leaves the user with a vague error.
    const rawBody = await response.text();
    let payload: ApiResponse<T> | null = null;
    try {
      payload = rawBody ? JSON.parse(rawBody) as ApiResponse<T> : null;
    } catch {
      payload = null;
    }

    if (payload) {
      const payloadToken = tokenFromPayload(payload);
      if (payloadToken) storeAccessToken(payloadToken);
      if (path === "/auth/logout" && payload.ok) clearAccessToken();

      if (response.status === 401 && allowRefresh && canRefreshFor(path)) {
        const refreshedToken = await refreshAccessToken();
        if (refreshedToken) return apiRequest<T>(path, init, false);
      }
      return payload;
    }

    if (response.status === 401 && allowRefresh && canRefreshFor(path)) {
      const refreshedToken = await refreshAccessToken();
      if (refreshedToken) return apiRequest<T>(path, init, false);
    }

    const readableBody = rawBody
      .replace(/<[^>]*>/g, " ")
      .replace(/\s+/g, " ")
      .trim()
      .slice(0, 240);
    return {
      ok: false,
      error: {
        code: response.status === 401 ? "AUTHENTICATION_REQUIRED" : `HTTP_${response.status}`,
        message: response.status === 401
          ? "Your session has expired. Please sign in again."
          : readableBody || `The workspace service returned HTTP ${response.status}.`,
      },
    };
  } catch {
    return { ok: false, error: { code: "NETWORK_ERROR", message: "DuePilot could not reach the workspace service. Check your connection and try again." } };
  }
}

export async function apiMutation<T>(path: string, body: unknown): Promise<ApiResponse<T>> {
  return apiRequest<T>(path, {
    method: "POST",
    body: JSON.stringify(body),
  });
}
