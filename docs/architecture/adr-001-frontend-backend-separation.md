# ADR-001: Separate Next.js frontend and ColdBox API

Status: Accepted

## Decision

Use Next.js with React and TypeScript for all new user interfaces. Retain ColdBox
on BoxLang as the authoritative REST API and business layer. Persist production
records in PostgreSQL. Place a Next.js backend-for-frontend route between the
browser and ColdBox.

## Why

- Next.js provides the required marketing, onboarding and application UX.
- Existing JWT, ColdBox and domain knowledge remains valuable.
- ColdBox owns authorization and financial invariants in one place.
- PostgreSQL provides transactional consistency, constraints and reporting.
- A same-origin proxy simplifies secure cookies and deployment topology.

## Consequences

- Frontend and backend can be deployed and scaled independently.
- API contracts must be versioned and tested.
- Two runtimes must be monitored.
- UI validation improves usability, but backend validation remains mandatory.
- Legacy ColdBox views are temporary compatibility surfaces, not the destination.
