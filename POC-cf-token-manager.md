# Proof of Concept (POC)
# cf-token-manager — A JWT Access & Refresh Token Lifecycle Package for CFML / ColdBox

| | |
| --- | --- |
| **Package name** | `cf-token-manager` |
| **Version** | `1.0.0` |
| **Type** | ColdBox Module (service-only, no inbound routes) |
| **Platform** | CommandBox + ColdBox (MVC) |
| **Engine support** | Adobe ColdFusion `>=2021`, Lucee `>=5.3`, BoxLang `>=1.0.0` |
| **Distribution** | ForgeBox (planned public release) |
| **License** | MIT |
| **Status** | POC validated against a live ColdBox host application |

---

## 1. Executive Summary

`cf-token-manager` is a CommandBox/ColdBox package that provides a **complete JWT token
lifecycle** — not just raw encode/decode. Our team analysed the JWT packages already
available on ForgeBox and found that, while there are many of them, they generally stop at
low-level primitives (`encode()`, `decode()`, `verify()`) and leave the developer to hand-build
payloads, expiry policy, and — most importantly — the **access-token / refresh-token flow**.

There was **no existing package that packages the access + refresh token concept** as a
first-class, opinionated, developer-ready API. This POC fills that gap.

The package deliberately builds **on top of** the proven low-level JWT engine and wraps it in an
authentication-aware lifecycle layer, so developers get a standardised, batteries-included API:

```cfml
issue()    // mint an access + refresh token pair for a subject
verify()   // is this token authentic, unexpired and the right type?
decode()   // read the claims of a token
refresh()  // exchange a valid refresh token for a new access token
```

Signing is performed through the **JVM's `javax.crypto` classes**, so behaviour is identical
across all three CFML engines (Adobe CF, Lucee, BoxLang).

---

## 2. Background & Motivation

### 2.1 The task
The ColdFusion team lead assigned a POC to build a reusable JWT token package via
CommandBox/ColdBox, with the intent of **contributing it to ForgeBox** as an open-source
package.

### 2.2 The gap we found
After surveying the existing ForgeBox ecosystem:

- Plenty of JWT packages exist, but they are **low-level engines** — they produce and verify a
  single token and stop there.
- The **access-token + refresh-token pattern** (short-lived access token, long-lived refresh
  token, silent renewal, forced logout on refresh expiry) is something **every real application
  needs**, but developers have to re-implement it by hand every time.
- There was **no package** that made this lifecycle a standardised, drop-in concept.

### 2.3 Our idea
- Reuse a full, existing JWT engine for the raw crypto/token work (don't reinvent signing).
- Build a **second layer / module on top** that adds the access & refresh token concept, plus
  `verify`, `decode`, and `refresh`.
- Ship a **standard, opinionated, developer-friendly** API with sensible defaults and clear
  error reporting.
- Support **all CF engines** by using Java libraries for signing.
- Release this as **Version 1**, with **role-based authentication** planned for the next version.

---

## 3. Scope

### 3.1 In scope (Version 1 — this POC)
- Issue an **access + refresh token pair** from a subject struct.
- **Verify** a token (authenticity + expiry + type).
- **Decode** claims from a token.
- **Refresh** an access token using a valid refresh token.
- Precise diagnostics (`validate()` throwing typed exceptions, `diagnose()` non-throwing).
- Configurable policy (secret, algorithm, access/refresh TTL, issuer).
- Cross-engine HMAC signing (HS256 / HS384 / HS512) via Java crypto.

### 3.2 Out of scope (planned for future versions)
- **Role-based authentication** (e.g. `user`, `admin`, `subscribed` users) — **Version 2**.
- Token revocation / blocklist store.
- Asymmetric algorithms (RS/ES families).
- Persistent refresh-token rotation store.

---

## 4. Architecture

The package is intentionally split into **two layers** so that the reusable engine and the
opinionated lifecycle policy are cleanly separated.

```
Host ColdBox Application
        │  inject="TokenManager@cf-token-manager"
        ▼
TokenManager.cfc      ← PUBLIC lifecycle API
        │               issue() / verify() / decode() / refresh()
        │               validate() / diagnose()
        │               (owns policy: TTLs, access vs refresh, iat/exp/iss claims)
        ▼
JWTService.cfc        ← INTERNAL JWT engine
                        encode() / decode() / verifySignature()
                        (Java HMAC signing, base64url, constant-time compare)
        ▼
JVM javax.crypto (Mac / SecretKeySpec)
```

| Layer | File | Responsibility |
| --- | --- | --- |
| Lifecycle (public) | `models/TokenManager.cfc` | Access/refresh concept, expiry policy, type checking, claim stamping, precise error diagnostics. **This is the only component host apps use.** |
| Engine (internal) | `models/JWTService.cfc` | Encode/decode/sign/verify a single JWT. No concept of access vs refresh. Host apps should **not** inject this directly. |
| Module wiring | `ModuleConfig.cfc` | Registers models under the `cf-token-manager` namespace, exposes overridable settings. |

### 4.1 Why two layers?
- The **engine** can be swapped or upgraded without touching application code.
- The **lifecycle layer** encodes all the opinionated "correct behaviour" (short access token,
  long refresh token, type enforcement) so developers don't repeat it.
- Reserved control claims (`type`, `iat`, `exp`, `iss`) are managed by the package and cannot be
  spoofed by the caller.

---

## 5. Public API Reference

Inject the manager anywhere in the host app:

```cfml
property name="tokenManager" inject="TokenManager@cf-token-manager";
```

### 5.1 `issue( struct subject )`
Mints a fresh **access + refresh** token pair.

```cfml
var tokens = tokenManager.issue( { id : 101, role : "admin", email : "a@b.io" } );
// {
//   "accessToken"  : "eyJ0eX...",   // type=access,  short-lived
//   "refreshToken" : "eyJ0eX..."    // type=refresh, long-lived
// }
```
- The `id` (or `sub`) key becomes the JWT `sub` claim.
- All other business keys (`role`, `email`, …) are carried into the token verbatim.
- Claim names are lower-cased for predictable behaviour across engines (Adobe CF otherwise
  upper-cases unquoted struct keys).
- Throws `cftokenmanager.InvalidSubject` if neither `id` nor `sub` is present.

### 5.2 `verify( string token, string type = "access" )` → boolean
Non-throwing boolean check: authentic **and** unexpired **and** the expected type.

### 5.3 `decode( string token )` → struct
Returns the claims struct **without** verifying the signature (use `verify()` first when the
result must be trusted).

### 5.4 `refresh( string refreshToken )` → struct
Exchanges a valid **refresh** token for a **new access token** (same subject, fresh `iat`/`exp`).

```cfml
var fresh = tokenManager.refresh( refreshToken );
// { "accessToken" : "<new access jwt>" }
```
- Rejects an expired/tampered refresh token.
- Rejects an **access** token passed where a refresh token is expected (wrong type).

### 5.5 Diagnostics — `validate()` and `diagnose()`
When you need to tell the client **why** a token was rejected:

- `validate( token, type )` — throws a **typed exception** and returns claims on success.
- `diagnose( token, type )` — non-throwing; returns `{ valid, code, message }`.

| `diagnose()` code | Thrown exception type | Meaning |
| --- | --- | --- |
| `VALID` | — | Authentic, unexpired, correct type |
| `MISSING_TOKEN` | `cftokenmanager.MissingToken` | Empty / no token supplied |
| `MALFORMED_TOKEN` | `cftokenmanager.MalformedToken` | Not a 3-segment JWT / unparseable body |
| `INVALID_SIGNATURE` | `cftokenmanager.InvalidSignature` | Signature does not match the secret (tampered / wrong secret) |
| `TOKEN_EXPIRED` | `cftokenmanager.ExpiredToken` | `exp` claim is in the past |
| `INVALID_TOKEN_TYPE` | `cftokenmanager.InvalidTokenType` | e.g. a refresh token used on an access endpoint |

---

## 6. Configuration

Defaults live in `ModuleConfig.cfc` and are overridable from the host app's
`config/Coldbox.cfc` → `moduleSettings`:

```cfml
moduleSettings = {
    "cf-token-manager" : {
        secret             : getSystemSetting( "JWT_SECRET", "change-me" ),
        algorithm          : "HS512",   // HS256 | HS384 | HS512
        accessTokenExpiry  : 900,       // seconds (15 min)
        refreshTokenExpiry : 2592000,   // seconds (30 days)
        issuer             : "my-app"
    }
};
```

| Setting | Default | Notes |
| --- | --- | --- |
| `secret` | `cf-token-manager-default-secret-change-me` | **Always override in production** (e.g. from `.env` `JWT_SECRET`). |
| `algorithm` | `HS512` | Supported: `HS256`, `HS384`, `HS512`. |
| `accessTokenExpiry` | `900` (15 min) | Short-lived. |
| `refreshTokenExpiry` | `2592000` (30 days) | Long-lived. |
| `issuer` | `cf-token-manager` | Stamped as the `iss` claim. |

---

## 7. Security Design Notes

- **Java-based HMAC signing** via `javax.crypto.Mac` + `SecretKeySpec` → identical, portable
  behaviour across Adobe CF, Lucee and BoxLang.
- **Constant-time signature comparison** (`constantTimeEquals`) mitigates timing attacks when
  comparing signatures.
- **base64url** encoding/decoding (URL-safe, no padding) per the JWT spec.
- **Reserved claims** (`type`, `iat`, `exp`, `iss`) are owned by the package and stripped from
  any caller-supplied subject, so a caller cannot forge token type or expiry.
- **Signature verified before claims are trusted** — `validate()` checks the signature first,
  then reads `exp`/`type`.
- Epoch timestamps are cast to a Java `long` so `NumericDate` claims serialise as plain integers
  (never scientific notation like `1.78E9`).

---

## 8. Validation — How the POC Was Tested

The package was integrated into a live ColdBox host application (this `TestingApp`) and exercised
in **two complementary ways**: an automated engineering self-test console and a real end-to-end
authentication flow.

### 8.1 Engineering self-test console — `TokenDemo` handler → `/demo`
`app/handlers/TokenDemo.cfc` renders a **self-test matrix** that runs on every page load and
reports **expected vs actual** for every public function across all success and failure
dimensions:

| Function | Scenarios covered |
| --- | --- |
| `issue()` | Mint a valid pair; reject a subject with no `id`/`sub`. |
| `decode()` | Read claims from a token **without** verifying the signature. |
| `verify()` | Accept a valid access token; reject a tampered token. |
| `diagnose()` | `VALID`, tampered signature, wrong secret, expired, malformed, missing, and wrong-type (access used as refresh). |
| `refresh()` | Valid refresh → new access token diagnoses `VALID`; reject an access token used as a refresh token. |

Failure-mode fixtures (expired token, wrong-secret token, tampered token) are crafted on purpose
using the low-level engine, while everything else calls the **public API exactly as a host app
would**. The console also offers interactive `issue()`, `refresh()`, and an `inspect()` form that
runs `decode()` + `verify()` + `diagnose()` on any pasted token.

### 8.2 Real authentication flow — `Security` handler + live dashboard
`app/handlers/Security.cfc` + `app/views/security/dashboard.cfm` demonstrate the lifecycle the way
a production app uses it:

1. **Login** → `issue()` mints the first access + refresh pair (stored in session).
2. **Dashboard** → `decode()` reads `iat`/`exp` to drive live countdown timers and progress bars.
3. **Access token expires** → the browser calls the `/refresh` JSON endpoint, which uses
   `diagnose()` to confirm the refresh token is still good, then `refresh()` to silently mint a
   **new access token** — the user stays logged in.
4. **Refresh token expires** → `diagnose()` reports it, the session is killed, and the user is
   **logged out automatically**.

To make the full lifecycle observable in ~2 minutes during a live review, the demo config uses
short TTLs (`app/config/Coldbox.cfc`):

```cfml
"cf-token-manager" : {
    accessTokenExpiry  : 30,   // access token lives 30 seconds
    refreshTokenExpiry : 120   // refresh token lives 2 minutes
}
```
(Production values would typically be `900` / `2592000`.)

### 8.3 Demo routes

| Route | Maps to | Purpose |
| --- | --- | --- |
| `/login`, `/dashboard`, `/refresh`, `/logout` | `security.*` | End-to-end auth lifecycle |
| `/demo` | `tokenDemo.index` | Self-test matrix + interactive console |
| `/demo/issue` | `tokenDemo.issue` | Interactive `issue()` |
| `/demo/refresh` | `tokenDemo.refresh` | Interactive `refresh()` |
| `/demo/inspect` | `tokenDemo.inspect` | `decode()` + `verify()` + `diagnose()` on any token |

---

## 9. Test Results Summary

| Dimension | Function(s) | Expected | Result |
| --- | --- | --- | --- |
| Mint valid pair | `issue()` | Two 3-segment JWTs | PASS |
| Reject subject with no id/sub | `issue()` | `InvalidSubject` thrown | PASS |
| Read claims without verifying | `decode()` | Claims returned | PASS |
| Valid access token | `verify()` | `true` | PASS |
| Tampered token | `verify()` / `diagnose()` | `false` / `INVALID_SIGNATURE` | PASS |
| Wrong secret | `diagnose()` | `INVALID_SIGNATURE` | PASS |
| Expired token | `diagnose()` | `TOKEN_EXPIRED` | PASS |
| Malformed token | `diagnose()` | `MALFORMED_TOKEN` | PASS |
| Missing token | `diagnose()` | `MISSING_TOKEN` | PASS |
| Wrong type (access as refresh) | `diagnose()` | `INVALID_TOKEN_TYPE` | PASS |
| Valid refresh → new access | `refresh()` | New access token is `VALID` | PASS |
| Access token used as refresh | `refresh()` | `InvalidTokenType` thrown | PASS |

The self-test matrix reports **all checks passing** on page load and re-runs live, so regressions
are visible immediately during any demo or review.

---

## 10. Installation & Usage (for host apps)

`box.json` dependency (as used in this POC):

```json
"dependencies" : {
    "coldbox"          : "^8.0.0",
    "cf-token-manager" : "github:alexMs771/cf-token-manager"
}
```

Install and wire up:

```cfml
// 1. install
// box install

// 2. inject the manager in any handler/model
property name="tokenManager" inject="TokenManager@cf-token-manager";

// 3. on login
session.tokens = tokenManager.issue( { id : username, role : "customer" } );

// 4. on a protected request
if ( tokenManager.verify( session.tokens.accessToken ) ) {
    var claims = tokenManager.decode( session.tokens.accessToken );
}

// 5. when the access token expires
var fresh = tokenManager.refresh( session.tokens.refreshToken );
```

---

## 11. Roadmap

| Version | Feature set |
| --- | --- |
| **v1.0.0 (this POC)** | Access + refresh token lifecycle: `issue`, `verify`, `decode`, `refresh`, plus `validate`/`diagnose` diagnostics; configurable policy; HS256/384/512; Adobe CF / Lucee / BoxLang support. |
| **v2 (planned)** | **Role-based authentication** — first-class roles such as `user`, `admin`, and `subscribed`, with helpers to guard routes/actions by role. |
| **Future** | Token revocation / blocklist, refresh-token rotation store, asymmetric algorithms (RS/ES). |

---

## 12. Conclusion

The POC demonstrates that `cf-token-manager` successfully closes a real gap in the ForgeBox
ecosystem: a **standardised, developer-ready access & refresh token lifecycle** for CFML/ColdBox,
built on a proven JWT engine and portable across all CF engines via Java crypto. Every public
function was validated across all success and failure dimensions through both an automated
self-test matrix and a real end-to-end authentication flow.

**Recommendation:** proceed to package polish and publish **Version 1** to ForgeBox, then begin
**Version 2** (role-based authentication).

---

*Package tested with the `TestingApp` ColdBox application (Adobe ColdFusion 2025 via CommandBox).*
