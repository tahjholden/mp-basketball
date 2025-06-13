# MPB v2 Architecture  
A streamlined, high-efficiency implementation of the Max Potential Basketball (MPB) system that preserves the **Development ARC** philosophy and the ten critical functional pillars.

---

## 1 · Vision & Guiding Principles  
| Principle | Implementation Tactic |
|-----------|-----------------------|
| **Advancement** – continuous skill progress | Versioned PDP tags, real-time metrics, adaptive plan generator |
| **Responsibilities** – clarity & accountability | RLS-backed permissions, audit trail, role-based dashboards |
| **Collective Growth** – team & individual synergy | Overlay engines merge team blocks with player PDPs, shared reflection loops |

Efficiency is achieved through:  
* **Single-platform backend** – Supabase (Postgres + Edge Functions + Realtime) eliminates external workflow servers.  
* **Type-safe monorepo** – shared types generated from SQL power both Next.js 15 App Router and Edge Functions.  
* **Event-first design** – database NOTIFY + Realtime channels drive UI updates and analytics jobs without polling.

---

## 2 · High-Level System Diagram (text)  
```
[Next.js Frontend] ─▶ Supabase Edge Functions ─▶ Postgres DB
       ▲  │                                   ▲        │
       │  └──── Realtime (attendance, blocks) ┘        │
       │                                               │
       └── Media CDN (Supabase Storage) ◀──────────────┘
```
n8n/Make can remain optional for low-code orgs via webhooks, but core flows live in Edge Functions.

---

## 3 · Core Domain Model (recommended tables)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `person` | universal actors | `uid PK`, `name`, `email`, `role(enum: coach/player/parent/admin)` |
| `attendance` | who & when | `session_uid FK`, `person_uid FK`, `status(enum: present/absent)`, `timestamp` |
| `drill` | modular action bank | `uid PK`, `title`, `intent`, `supported_formats` (jsonb array), `base_constraints(jsonb)` |
| `constraint` | reusable overlay | `uid PK`, `title`, `level(enum: team/player)`, `payload jsonb` |
| `block` | instance of a drill in a plan | `uid PK`, `session_uid FK`, `drill_uid FK`, `order`, `applied_constraints jsonb`, `pdp_overlays jsonb` |
| `session` | practice/event | `uid PK`, `date`, `theme`, `status(enum: draft/active/completed)` |
| `pdp` | personal dev plan | `uid PK`, `person_uid FK`, `tag`, `priority`, `created_at` |
| `reflection` | text/media feedback | `uid PK`, `block_uid FK?`, `author_uid FK`, `content text`, `media_url`, `created_at` |
| `audit_log` | every change | `uid PK`, `table_name`, `record_uid`, `action`, `actor_uid`, `payload jsonb`, `created_at` |

All tables include `created_at`, `updated_at` triggers. RLS policies enforce role scopes; Supabase Auth JWT claims map to `person.uid`.

---

## 4 · Component Breakdown vs. 10 Critical Pieces  

| # | Component | Key Tech | Notes |
|---|-----------|----------|-------|
| 1 | **Modular Drill/Action Bank** | `drill`, `constraint` tables | JSON schema validates `supported_formats` & constraints |
| 2 | **Practice Plan Generator** | Edge Function `generate_plan` | SQL + PL/pgSQL assemble candidate blocks; returns editable array |
| 3 | **Attendance Engine** | Realtime listening UI + `attendance` table | UI defaults to all; quick toggles adjust counts |
| 4 | **PDP Overlay Engine** | Edge Function `overlay_pdp` | Merges PDP tags into blocks as `pdp_overlays` jsonb |
| 5 | **Constraint Library** | `constraint` table + UI palette | Drag-and-drop onto blocks |
| 6 | **Review/Approval Workflow** | Status field on `session`; RLS block edits after `active` | UI diff viewer; audit_log entry per change |
| 7 | **Analytics & Feedback Loop** | Materialized views + Supabase Dashboards | Example: `block_usage_mv`, `missed_overlay_view` |
| 8 | **Reflection & Media** | `reflection` table + Supabase Storage bucket | Upload via signed URLs; media linked by UID |
| 9 | **Audit & Permissions** | Postgres triggers + RLS + row-level JWT claims | Full history stored in `audit_log` |
|10 | **UI/UX Layer** | Next.js 15 AppRouter (server + client comps) | Tailwind UI kit; block editor using DnD Kit |

---

## 5 · Data-Flow Example (Practice Creation)

1. Coach opens **/sessions/new** – frontend fetches team ARC & recent friction.  
2. Coach marks attendance → rows inserted to `attendance`.  
3. Frontend calls `POST /generate-plan` Edge Function with session UID.  
4. Function queries `drill`, `attendance`, `pdp`, `constraint` and returns ordered `blocks`.  
5. Coach edits blocks; changes saved via optimistic mutations (supabase-js).  
6. Hitting **Finalize** sets `session.status = 'active'`; RLS locks editing for players; Realtime channel `session:uid` broadcasts update.  

---

## 6 · Efficiency Tactics  

| Concern | v2 Solution |
|---------|-------------|
| External workflow latency | Replace n8n with Edge Functions (cold-start ≈ <100 ms on Vercel-Edge) |
| Code duplication | `supabase gen types` in CI supplies `.generated/database.ts` for shared typing |
| Multiple deploy targets | Single Vercel app with `database`, `storage`, and `edge` configs auto-synced |
| Complexity of seed scripts | Use `supabase seed` with CSV + `row_security off` during seeding |
| Monitoring | Built-in Supabase Logs + Sentry for Next.js + pgAudit extension |

---

## 7 · Development Roadmap  

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| **0 · Repo Setup** | 1 day | Monorepo (turbo or pnpm workspace); commit schema & generated types |
| **1 · Auth & RLS** | 3 days | Supabase Auth config, role mapping, basic dashboard access control |
| **2 · Drill & Constraint Bank** | 1 week | CRUD UI, import CSV, validation hooks |
| **3 · Attendance & Plan Generator** | 1 week | Realtime attendance, `generate-plan` Edge Function, block editor |
| **4 · PDP Overlays & Review Flow** | 1 week | Overlay logic, session finalize, audit log UI |
| **5 · Reflection & Media** | 4 days | Upload flow, block-level reflections, storage rules |
| **6 · Analytics MVP** | 1 week | Materialized views, charts in coach dashboard |
| **7 · Polish & Mobile PWA** | ongoing | Offline-first tweaks, push notifications |

> CI/CD: Each phase merges only after `pnpm test` + migration diff pass.  
> Production preview: Vercel Preview + Supabase branch DB.

---

## 8 · Example Edge Function Snippet (TypeScript)

```ts
// supabase/functions/generate-plan.ts
import { createClient } from "https://deno.land/x/supabase/mod.ts";
import { z } from "https://deno.land/x/zod/mod.ts";

const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

export const handler = async (req: Request) => {
  const { session_uid } = await req.json();
  const attendance = await supabase
    .from("attendance")
    .select("person_uid")
    .eq("session_uid", session_uid)
    .eq("status", "present");

  // business logic omitted: choose drills, constraints, overlay PDP…

  return new Response(JSON.stringify({ blocks }), { headers: { "Content-Type": "application/json" } });
};
```

Edge Functions stay close to data, leverage Postgres functions when heavy logic is best expressed in SQL.

---

## 9 · Security & Compliance  

* **HIPAA/GDPR ready** – RLS, explicit consent tables, audit_log.  
* **Permissions matrix** stored in `role_permission` table; enforced in UI with Conditional Access wrapper.  
* **Backups** – Supabase Point-in-Time Recovery + nightly `pg_dump` artifact in Vercel block-storage.

---

## 10 · Conclusion  
MPB v2 merges the philosophical strength of Development ARC with a lean, modern tech stack:

* **Supabase-centric backend** for speed, cost, and real-time power.  
* **Next.js 15** front-end for rich, modular UX.  
* **Edge Functions** for deterministic, auditable logic without external orchestration.  

This architecture guarantees robustness **and** efficiency—ready to scale from a single club to 100+ organizations with minimal operational overhead.
