# Storefront Companion Repo Prompt

Use the following prompt when spawning a brand-new repository for the hybrid storefront companion that sits alongside our main Godot project. It captures the architectural decisions made in `README.md` and `TODO.yaml` and instructs the next agent to follow Context7-driven development practices.

```
You are an autonomous repo bootstrapper. Spin up a new public repository named `godot-commerce-hub` that delivers a fully standalone, game-agnostic commerce stack (backend + dashboard + Godot add-on). Honor the following requirements:

Context & Goals
- The main game currently relies on Talo for auth/analytics, but the commerce suite must stand on its own: no Talo code, naming, or runtime dependencies. Instead, review the official docs (https://docs.trytalo.com/docs/intro) plus the upstream repo for inspiration on ergonomics, API shape, and deployment discipline, then reimagine those ideas inside this independent stack.
- Ship three deliverables in one monorepo: (1) a TypeScript/Node backend (Fastify or Express) with Postgres that signs purchases, persists receipts, manages tenants, and emits webhooks/inventory updates; (2) a React + Vite dashboard for SKU/pricing management, seasonal offers, and ops tooling; and (3) a Godot 4 add-on client that can plug into any project (Talo users or not) via clean REST/WebSocket APIs.
- Support true multi-tenancy. Each tenant (game/app) configures its own catalog, currencies, and entitlement rules without forking the repo. Provide RBAC + tenant scoping in the dashboard/API and allow per-tenant webhooks/credentials. Egg packs remain sample fixture data to demonstrate the schema.
- Provide a flexible catalog/offer data model so purchasables are not hard-coded to eggs. Define entities like `Sku`, `Bundle`, `Offer`, `Currency`, and `Entitlement` (or similar) that let ops teams mix-and-match inventory types, pricing, limited-time rotations, and entitlement payloads.

Process Expectations
- Follow best agent practices: document-first, strict typing end-to-end, Conventional Commits, and per-directory `AGENTS.md` overrides where helpful.
- Before authoring integrations, study the Talo docs linked above plus any relevant upstream modules, noting key takeaways inside `docs/integrations/talo.md`. Use those findings to validate interfaces but ensure the implementation works even if Talo is absent.
- Use Context7 for any framework/library syntax lookups, API references, or verification of TypeScript/React/GDScript usage. Call `resolve-library-id` before `get-library-docs` and summarize insights back in code comments or docs.
- Produce a top-level plan (PLAN.md) before editing, keep `TODO.yaml` curated, and update `README.md`, root `AGENTS.md`, and `ROADMAP.md` in the first pass.

Repository Structure
- `apps/backend/`: Fastify/TypeScript service with Dockerfile, env samples, and Prisma schema; exposes `/tenants`, `/skus`, `/bundles`, `/offers`, `/purchases`, `/entitlements`, and `/integrations/talo` endpoints plus OpenAPI docs. Include per-tenant auth middleware, migration strategy, and seed scripts for sample tenants/items.
- `apps/dashboard/`: React + Vite admin SPA using TypeScript, Tailwind, and TanStack Query; authenticate via shared API tokens for now; includes SKU CRUD, offer scheduling, entitlement audit trails, and purchase log viewers.
- `addons/commerce_client/`: Godot 4 plugin mirroring best-practice add-on layouts. Provide a strictly typed GDScript autoload that fetches offers, initiates purchases, polls order status, and emits signals for UI binding. Include `demo/` scene(s) showcasing integration in a blank Godot project with and without Talo tokens.
- `docs/`: `architecture.md`, `api.md`, `ops.md`, `testing.md`, and `integrations/talo.md` (summaries of the referenced docs + how to wire optional compatibility layers), plus roadmap/planning artifacts.
- Configuration: shared `pnpm-workspace.yaml` or npm workspaces to manage TypeScript packages; ESLint + Prettier + EditorConfig; GitHub Actions workflow that lints, runs tests, builds Docker images, and packages the Godot add-on.

Acceptance Criteria
- `README.md` covers purpose, topology diagram, setup instructions (Docker + pnpm), multi-tenant concepts (tenants, catalogs, credentials), and outlines optional adapters for Talo-inspired deployments with links back to https://docs.trytalo.com/docs/intro.
- `AGENTS.md` enumerates repo-wide guidelines plus constraints on touching vendored dependencies and third-party libs.
- `TODO.yaml` lists short-term tasks for backend MVP, dashboard polish, Godot plugin parity, adapter support (including Talo), multi-tenant hardening, and security improvements.
- Provide seed data for tenants, SKUs/offers, plus a fake payment provider stub so tests can assert purchase flows end-to-end.
- Include automated tests: backend unit tests (Vitest/Jest), dashboard component tests (Vitest/Testing Library), and Godot GDScript unit tests (or smoke scripts verifying exported plugins).

Deliver a concise final summary plus follow-up recommendations once the repo skeleton is ready.
```
