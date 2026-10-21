# DuePilot

DuePilot is a ColdBox accounts-receivable command center for service businesses. It gives finance teams one place to track invoices, prioritize collections, record customer promises and disputes, and share a secure payment portal.

Version 1 runs in **demo mode by default**. It includes realistic seeded data and every core workflow, so no database credentials are required to evaluate it.

## Included in version 1

- JWT-backed sign-in and session lifecycle using `cf-token-manager`
- Role-aware workspace access with separate Free / Plus / Pro entitlements
- Server-side annual subscriptions, AI quotas and nested-workspace limits
- Token-manager entitlement lab: 5-minute Free, 2-minute Plus and 3-minute Pro demo TTLs
- Receivables dashboard with aging, collection rate and cash forecast
- Invoice search, status filters, detail pages and invoice creation
- Payment recording, reminders, payment promises and disputes
- Customer directory with account-level exposure and payment behaviour
- Prioritized collection queue
- Collection and aging reports
- Public customer payment portal with demo UPI checkout
- Short-lived JWT bearer access tokens with server-held refresh sessions for the Next.js API
- Responsive product UI for desktop, tablet and mobile
- Persistent light/dark/system theme with accessible controls
- DuePilot AI receivables copilot with guided offline mode and Groq live mode
- MySQL 8 production schema for the persistent repository phase
- Render/Docker deployment configuration and health check

## Run locally

Requirements: Java 21 and CommandBox 6+. The project uses BoxLang, which CommandBox installs automatically on first start.

```bash
box install
box server start
```

Open <http://127.0.0.1:8080/login>.

Demo credentials:

```text
Email:    alex@duepilot.app
Password: demo123
```

The alternative compatibility account is `test` / `test`.

## Enable DuePilot AI with Groq

DuePilot uses the official BoxLang `bx-ai` module and its native Groq provider. The server supplies a restricted receivables snapshot to the model; API keys, portal tokens and customer contact details are never sent to the browser.

The assistant works immediately in **guided mode** without an API key. It can summarize exposure, explain aging, rank collection work and draft a reminder from deterministic demo data. To enable live LLM conversations:

1. Create a Groq API key in the Groq console.
2. Open the ignored local `.env` file in the project root.
3. Set `GROQ_API_KEY=your-key` there. Do not paste the key into chat, source files or browser JavaScript.
4. Restart the application with `box server restart`.

For controlled failover, add up to three optional server-side keys:

```dotenv
GROQ_API_KEY=primary-key
GROQ_API_KEY_2=secondary-key
GROQ_API_KEY_3=third-key
GROQ_API_KEY_4=fourth-key
```

DuePilot deduplicates the pool and rotates the starting slot across requests. A second key is tried only for authentication, quota, rate-limit, timeout, connection, or provider-availability failures; invalid prompts or configuration errors are not repeated against every key. The keys are never combined into one provider request.

The remaining defaults are already configured:

```dotenv
AI_ASSISTANT_ENABLED=true
AI_FALLBACK_ENABLED=true
GROQ_MODEL=openai/gpt-oss-20b
GROQ_TIMEOUT_SECONDS=12
GROQ_MAX_TOKENS=700
```

The assistant is read-only in version 1. It can recommend a workflow but cannot send reminders, change invoices or record payments. Requests require a valid JWT bearer access token, are limited to 2,000 characters and are rate-limited to 10 per minute per session. Provider failures fall back to guided mode without exposing provider errors or secrets.

## Application structure

```text
app/
  handlers/AiAssistant.cfc       Authenticated assistant JSON API
  handlers/DuePilot.cfc         Product request workflows
  models/DuePilotAiService.cfc  Groq/BoxLang AI integration and safe fallback
  models/SubscriptionService.cfc Server-side plans, quotas and nested workspaces
  models/DuePilotService.cfc    Receivables domain and demo repository
  views/duePilot/               Product and customer portal screens
  layouts/                      Auth, application and portal shells
public/assets/                  DuePilot CSS and JavaScript
resources/database/schema/     MySQL production schema
```

Only `public/` is web-accessible. The ColdBox application, JWT module and business logic remain outside the web root.

## Data modes

The current release uses `DATA_MODE=demo`. Data lives in application memory and resets when the application restarts. You can also restore it manually from **Settings → Reset demo workspace**.

For persistent customer data and plan-aware authorization:

1. Start PostgreSQL with `docker compose --env-file .env -f docker/docker-compose.yml up -d postgres`.
2. New databases apply migrations `001` through `004`; an existing volume must apply [`database/migrations/004_subscriptions_and_nested_workspaces.sql`](database/migrations/004_subscriptions_and_nested_workspaces.sql) once.
3. Copy `.env.example` to `.env`, set the `DB_*` values and use `DATA_MODE=postgres`.
4. Start the backend and frontend. Registration creates the user's root workspace on the Free plan.

The schema covers users, tenant workspaces, member roles, invoices, payments, promises, disputes, reminders, AI usage, subscriptions and the activity audit trail. Do not store real customer or payment data in demo mode.

### Plan and RBAC rules

`owner`, `admin`, `manager`, `finance` and `member` are identity roles. `free`, `plus` and `pro` are workspace entitlements. A subscription never silently changes a user's identity role. The signed access token includes a plan snapshot, but every protected API request re-checks the current subscription in PostgreSQL and rotates stale claims. Plus and Pro may create nested workspaces; Free cannot. Plus has a monthly guided-AI quota, while Pro has no monthly quota (the per-minute abuse guard still applies).

The billing screen currently uses an internal test activation so the workflow can be demonstrated without a payment provider. Before charging customers, replace that endpoint with verified Razorpay/Stripe/Cashfree webhook processing and keep the entitlement service as the single authorization boundary.

## Security and external integrations

Set a long random `JWT_SECRET` in every non-local environment. Never commit the production secret.

Version 1 records reminder and payment workflow events but does not send real email/WhatsApp messages or move money. Production integrations should use provider webhooks and idempotency keys:

- Payment gateway: Razorpay, Cashfree, Stripe or another approved provider
- Email: Postmark, Amazon SES, Resend or equivalent
- WhatsApp/SMS: Meta Cloud API, Twilio or an approved BSP

The public portal currently labels checkout as a demo, so users cannot mistake it for a real payment.

## Tests and diagnostics

```bash
box testbox run runner=http://127.0.0.1:8080/tests/runner.cfm
box cfformat check app/handlers app/models app/config
```

- Health check: `/healthcheck`
- JWT diagnostics lab: `/demo`

The AI test suite never requires a real API key. Live provider calls are only made through the signed-in application after `GROQ_API_KEY` is configured.

## Deployment

`render.yaml` and `docker/Dockerfile` deploy DuePilot on BoxLang. Render receives `PORT` automatically and generates `JWT_SECRET` from the blueprint.

The container uses a constrained JVM configuration from `server.json`. BoxLang is the practical choice for the 512 MB Render tier, though a production service with real traffic should still use at least 1 GB RAM.

For a production-like local Docker run from the project root:

```bash
docker compose --env-file .env -f docker/docker-compose.yml up --build
```

The compose stack builds the same Dockerfile used by Render, waits for PostgreSQL health, caps the app container at 512 MB and exposes DuePilot at <http://127.0.0.1:8080>. The `.dockerignore` explicitly excludes `.env`, so the Groq and JWT secrets are injected at runtime instead of being copied into the image.

On Render, add `GROQ_API_KEY` and any optional `GROQ_API_KEY_2` through `GROQ_API_KEY_4` values under **Service → Environment** as secret values, then redeploy. `render.yaml` contains the non-secret AI defaults and deliberately leaves every key unsynchronized.

Before serving real customers, add persistent storage, password hashing, email verification, rate limiting, provider webhook verification, backups and operational monitoring.
