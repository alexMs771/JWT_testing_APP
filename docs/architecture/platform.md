# DuePilot platform architecture

## Product boundary

DuePilot is a multi-tenant payment-operations platform. It has one shared
billing, payment, collection, notification, reporting and AI foundation, with
sector modules that change terminology and workflows for businesses, schools,
coaching centres, properties and utilities.

The first production slice is deliberately a business workspace. A second
school slice will validate that the shared engine is genuinely reusable before
additional sectors are introduced.

## Runtime topology

```text
Browser
  |
  | HTTPS, same origin
  v
Next.js frontend / backend-for-frontend
  |
  | private HTTP, JSON, forwarded secure session
  v
ColdBox REST API on BoxLang
  |              |                |
  v              v                v
PostgreSQL     Groq AI       Payment/notification providers
```

The browser never receives database credentials, JWT signing secrets, payment
secrets or AI provider keys. The Next.js backend-for-frontend proxy keeps the
backend address private and avoids broad cross-origin cookie rules.

## Repository boundaries

```text
frontend/                 Next.js 16, React 19, TypeScript, App Router
app/                      ColdBox handlers, domain services and repositories
public/                   Legacy ColdBox web root during migration
database/migrations/      Ordered PostgreSQL schema migrations
docker/                   Local full-stack orchestration and backend image
docs/architecture/        Product and technical decisions
```

The legacy ColdBox views remain available during migration. New product work
targets the versioned API and Next.js interface. They can be retired only after
equivalent workflows pass end-to-end tests.

## Request lifecycle

1. The browser sends a request to Next.js.
2. Public pages render directly in Next.js.
3. Product data requests use `/api/backend/*` on the same origin.
4. The route handler forwards method, body and cookies to ColdBox.
5. ColdBox authenticates the session and resolves the active workspace.
6. Permission checks run before repositories are called.
7. Repository queries always include the active `workspace_id`.
8. ColdBox returns the versioned JSON envelope.
9. Next.js forwards status, response and rotated cookies to the browser.

## API response contract

Successful response:

```json
{
  "ok": true,
  "data": {},
  "meta": {
    "apiVersion": "v1",
    "requestId": "uuid",
    "timestamp": "ISO-8601"
  }
}
```

Failure response:

```json
{
  "ok": false,
  "error": {
    "code": "STABLE_MACHINE_CODE",
    "message": "Safe user-facing explanation",
    "details": []
  },
  "meta": {
    "apiVersion": "v1",
    "requestId": "uuid"
  }
}
```

## Authentication direction

The current preview uses the existing token manager and a server session. The
production identity implementation will store password hashes and refresh-token
hashes in PostgreSQL. Access credentials remain short lived; refresh credentials
are HttpOnly, Secure and rotated. Logout revokes the refresh session as well as
clearing application state.

## Tenant isolation

Workspace-owned tables carry `workspace_id`. The backend derives the active
workspace from the authenticated membership, never from an untrusted query
alone. Repository methods accept an authorization context and scope every
read/write to that workspace. Financial mutations also create audit events.

## Financial integrity rules

- Payment provider return pages never mark an invoice paid.
- Only verified, idempotently processed webhooks or authorized manual entries
  create successful payments.
- Invoice balances are derived from traceable ledger records and validated in a
  database transaction.
- Provider event IDs and payment references are unique within their scope.
- Refunds and adjustments are new records, not destructive edits.
- Forecast values are labelled separately from verified collections.

## AI safety boundary

The AI assistant calls permission-checked backend tools. It receives the minimum
workspace context required for the request. It may explain data, retrieve
records, draft communication and recommend actions. It cannot mark payments,
delete financial records, issue refunds or send bulk messages without a normal
authorized product workflow and explicit confirmation.

## Delivery sequence

1. Platform foundation: frontend, REST API, PostgreSQL and Docker.
2. Identity: registration, verification, reset, refresh sessions and protected routes.
3. Workspaces: onboarding, selection, invitations, roles and permissions.
4. Business workflow: customer, invoice, portal, verified payment and reports.
5. Notifications and collection automation.
6. AI tools, provider controls, limits and observability.
7. School/coaching module on the shared financial engine.
8. Advanced payment reconciliation, exports and additional sectors.

## Environment model

Development, staging and production use separate databases, secrets and provider
accounts. Docker is the local contract. Production hosting stays provider-neutral
until the operational target is selected; Render-specific configuration has been
removed.
