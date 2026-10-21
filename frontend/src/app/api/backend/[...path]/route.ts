import type { NextRequest } from "next/server";

const backendUrl = process.env.DUEPILOT_API_URL ?? "http://127.0.0.1:8080";
const blockedResponseHeaders = new Set(["connection", "content-length", "content-encoding", "transfer-encoding"]);

async function proxy(request: NextRequest, context: { params: Promise<{ path: string[] }> }) {
  const { path } = await context.params;
  const upstream = new URL(path.join("/"), `${backendUrl.replace(/\/$/, "")}/`);
  upstream.search = request.nextUrl.search;
  const endpointPath = path.join("/");

  // An allow-list prevents browser hop-by-hop transport headers from being
  // passed to Node's fetch implementation. The browser sends the access token
  // as a bearer header while the refresh session remains in the HttpOnly cookie.
  const headers = new Headers({ accept: "application/json" });
  for (const name of ["content-type", "cookie", "authorization"]) {
    const value = request.headers.get(name);
    if (value) headers.set(name, value);
  }

  try {
    let response = await fetch(upstream, {
      method: request.method,
      headers,
      body: request.method === "GET" || request.method === "HEAD" ? undefined : await request.arrayBuffer(),
      cache: "no-store",
      redirect: "manual",
    });

    // A browser tab can keep an older bundle alive during a hot reload. If
    // that bundle sends POST to this read-only endpoint, recover by retrying
    // only this safe subscription read as GET. Direct API callers still get
    // the correct 405 response from ColdBox.
    if (endpointPath === "api/v1/subscription" && request.method !== "GET" && response.status === 405) {
      response = await fetch(upstream, {
        method: "GET",
        headers,
        cache: "no-store",
        redirect: "manual",
      });
    }
    const responseHeaders = new Headers();
    response.headers.forEach((value, name) => {
      if (!blockedResponseHeaders.has(name.toLowerCase())) responseHeaders.append(name, value);
    });
    responseHeaders.set("cache-control", "no-store");
    return new Response(await response.arrayBuffer(), { status: response.status, headers: responseHeaders });
  } catch {
    return Response.json({ ok: false, error: { code: "BACKEND_UNAVAILABLE", message: "DuePilot API is temporarily unavailable." } }, { status: 502 });
  }
}

export const GET = proxy;
export const POST = proxy;
export const PUT = proxy;
export const PATCH = proxy;
export const DELETE = proxy;
