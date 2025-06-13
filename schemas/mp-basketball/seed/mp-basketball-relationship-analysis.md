# MP Basketball – Repository Relationship Analysis  
*(mpb-web-v2 ↔ mp-basketball)*  

## 1. Executive Summary  
`mp-basketball` is the **backend / workflow nucleus** (Postgres + Supabase schema, n8n automations, seed data, CLI tooling).  
`mpb-web-v2` is a **minimal front-end scaffold** (Next.js 15 + Tailwind CSS + Supabase JS SDK) intended to surface those back-end capabilities to end-users.  
Together they form a classic **API-driven architecture**: `mp-basketball` supplies data integrity, business logic, and automation while `mpb-web-v2` delivers UX, auth flows, and real-time interactions.

The two repositories are currently loosely coupled (no shared environment files or CI links). A clear migration path is therefore required to evolve `mpb-web-v2` from a template into the production-ready interface for `mp-basketball`.

---

## 2. Current State Snapshots  

| Aspect | mpb-web-v2 | mp-basketball |
|-------|------------|---------------|
| **Primary Role** | Next.js front-end | Supabase schema + n8n workflows |
| **Key Files** | `src/app/page.tsx`, `package.json`, `globals.css` | `schemas/mp-basketball/migrations/**`, `workflows/*.json`, `MIGRATION_PLAN.md` |
| **Dependencies** | `next 15.3.3`, `@supabase/supabase-js 2.50.0`, Tailwind 4 | Node tooling, Python utilities, Jest tests; heavy Postgres SQL |
| **Data Models** | None defined in code yet (only Supabase client dep) | Comprehensive tables: `person`, `attendance`, `tag`, etc. (see `003_complete_schema.sql`) |
| **Automation** | N/A | n8n flows: `practice-planner-agent.json`, `pdp-agent.json`, etc. |
| **Testing** | Default Next.js dev server only | Jest + Dockerised Postgres (`tests/db.ts`); CI via GitHub Actions |

---

## 3. Architectural Alignment & Gaps  

### 3.1 Natural Integration Points  
1. **Supabase Client** – `mpb-web-v2/package.json` already includes `@supabase/supabase-js`; it should target the same project defined by `mp-basketball` migrations.  
2. **Row-Level Security (RLS)** – `mp-basketball` enables RLS in `008_enable_rls.sql`; the front-end must authenticate and pass JWTs accordingly.  
3. **Attendance-Driven Session Planning** – n8n workflow `practice-planner-agent.json` expects `attendance` records; web UI needs components to mark attendance and trigger the workflow.  
4. **Person/Role Model** – Front-end forms must create/update `person` and related `person_role` rows exposed by the schema.

### 3.2 Gaps to Close  
| Gap | Present Evidence | Required Work |
|-----|------------------|---------------|
| **Environment Wiring** | No `.env.local` in web repo | Add `NEXT_PUBLIC_SUPABASE_URL` & `NEXT_PUBLIC_SUPABASE_ANON_KEY` that point to the same DB used by CLI migrations |
| **Auth Flows** | No pages/components | Implement Next.js App Router auth using `@supabase/ssr` (server-side cookies) |
| **API Route Proxies** | None | Create `/api/` handlers for secure server actions (e.g., attendance POST) |
| **UI for n8n Triggers** | n/a | Webhooks or RPC endpoints to start/monitor n8n workflows |
| **Shared Types** | None | Generate types via `supabase gen types typescript --local` and import into web repo |

---

## 4. Roadmap to Convergence  

### Phase 0 – Foundations (1-2 days)  
1. Clone both repos into a mono-workspace or add Git submodules.  
2. Run `supabase db push` with `mp-basketball` migrations; verify local Postgres mirrors schema.  
3. Create `.env.local` in `mpb-web-v2` with Supabase URL & anon key.

### Phase 1 – Auth & Session Layer (3-5 days)  
1. Install `@supabase/ssr`.  
2. Implement `/login`, `/signup`, and middleware to refresh sessions (see Supabase docs).  
3. Protect a placeholder `/dashboard` route to prove RLS compliance.

### Phase 2 – Core Data Screens (1-2 weeks)  
1. **Attendance UI** – Table/List to mark players present → write to `attendance` table.  
2. **Person CRUD** – Forms to create players/coaches, leveraging generated types.  
3. **PDP Viewer** – Read‐only view of `pdp` rows (seeded in `/schemas/mp-basketball/seed/pdp_rows*.sql`).  

### Phase 3 – Workflow Orchestration (1 week)  
1. Expose an API route `/api/generate-session` that hits n8n’s REST endpoint for `practice-planner-agent`.  
2. Display workflow run status & output (session block JSON).  
3. Add manual approval UI that writes generated blocks back into `session` table.

### Phase 4 – Polish & CI/CD (ongoing)  
1. Tailwind design system for consistent theming.  
2. GitHub Actions:  
   - Web: lint, build on PR.  
   - Backend: run migrations & tests.  
3. Deploy to Vercel + connect Supabase via Vercel integration (auto-runs migrations).  

---

## 5. Implementation Recommendations  

1. **Shared Environment & Scripts**  
   - Store a root `supabase/config.toml`; both repos reference it via workspace scripts.  
   - Use `supabase gen types` in a post-build script; commit generated `database.types.ts` to `mpb-web-v2`.  

2. **Type Safety End-to-End**  
   - Adopt Zod schemas reflecting `mp-basketball` SQL types for front-end validation.  
   - Leverage `ts-jest` tests in web repo that spin up the same Docker Postgres (pattern in `mp-basketball/tests/db.ts`).  

3. **Decouple Workflow Secrets**  
   - Store n8n credentials in Supabase `secrets` table with RLS; front-end requests a short-lived signed JWT to invoke workflows.  

4. **Progressive Enhancement**  
   - Keep `mpb-web-v2` deployable even when workflows are offline by falling back to manual planning forms.  

5. **Monitoring & Audit**  
   - Expose `audit_log` (already in backend schema) via admin dashboard for transparency.  
   - Add Sentry to front-end, and n8n error trigger to Slack/Email.

---

## 6. Risks & Mitigations  

| Risk | Mitigation |
|------|------------|
| **Schema Drift** (multiple contributors) | Enforce PR pipeline that runs `tools/schema_diff.py` against preview DB. |
| **Auth Complexity (SSR cookies)** | Adopt Supabase’s reference Next.js App Router snippet verbatim; add Cypress tests for login flows. |
| **Workflow Latency** | Cache generated session plans in `session_plan_cache` table; fetch from cache before invoking n8n. |
| **Mobile UX** | Prioritise responsive Tailwind components; later wrap in React Native Web if native app required. |

---

## 7. Next Steps Checklist  

- [ ] Configure Supabase project & push `mp-basketball` migrations  
- [ ] Create `.env.local` in `mpb-web-v2`  
- [ ] Scaffold auth pages with `createClient()` util  
- [ ] Generate TypeScript types from DB  
- [ ] Build Attendance screen -> test write to DB  
- [ ] Wire `/api/generate-session` → n8n  
- [ ] Set up Vercel preview deploys linked to Supabase branch DBs  

---

### References  

*Backend Evidence*  
- Schema migrations: `schemas/mp-basketball/migrations/003_complete_schema.sql`, `010_create_attendance.sql`  
- Automation: `workflows/practice-planner-agent.json`, `pdp-agent.json`  
- Migration guidelines: `MIGRATION_PLAN.md`

*Front-end Evidence*  
- Supabase SDK dep: `mpb-web-v2/package.json`  
- App Router scaffold: `src/app/layout.tsx`, `src/app/page.tsx`  

By following the phased roadmap and recommendations above, the team can incrementally evolve `mpb-web-v2` from a boilerplate into the fully featured UI layer that operationalises the rich backend logic of `mp-basketball`.
