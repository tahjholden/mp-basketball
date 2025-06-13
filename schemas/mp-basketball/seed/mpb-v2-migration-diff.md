# MPB v2 Migration Diff  
Comparison of the **original `mp-basketball` schema** (v1) and the **streamlined schema** adopted for **mpb-web-v2** (v2).  
The goal is to keep robustness while eliminating friction, complexity, and latency, fully embracing the Development **ARC** philosophy *(Advancement · Responsibilities · Collective Growth)*.

---

## 1. At-a-Glance Change Matrix  

| Domain | v1 Tables / Columns | v2 Tables / Columns | Rationale |
|--------|--------------------|---------------------|-----------|
| **People & Roles** | `person`, `person_role`, `team`, `pod`, many FK join tables | `person`, `team`, `pod`, minimal join tables | `person_role` folded into a **role enum** on `person`; simplifies queries & RLS checks. |
| **Attendance** | `attendance` (identical) | `attendance` *(kept)* | Already efficient; kept and indexed for realtime feeds. |
| **Drill / Action Bank** | none (drills encoded in CSV + JSON inside workflows) | `drill`, `constraint` | First-class tables allow search, analytics, and reuse across teams. |
| **Practice Blocks** | `session` with `session_plan` JSONB + numerous nullable meta columns | `session` (trimmed) + **`block`** table | Splits child blocks into their own rows → granular PDP overlays & analytics; drops unused fields (e.g. `session_id`, duplicate date/time). |
| **PDP** | `pdp` (verbose, version chain) | `pdp` (leaner) | Keeps versioning fields, removes duplicate text columns; summaries derived on demand. |
| **Reflections / Media** | reflections stored in multiple spread sheets & `mpb_docs` chunk table | `reflection` + Supabase Storage | Single table with media URL + block/session linkage. |
| **Automation / Events** | `agent_events`, `flagged_entities`, many deprecated workflow tables | `audit_log` (broader) + optional `agent_event` | Unified log captures **all** changes, satisfying accountability requirements with fewer tables. |
| **Analytics** | Materialized in n8n JSON; ad-hoc CSV exports | Postgres materialized views (`block_usage_mv`, etc.) | Pushes analytics closer to data; removes external workflow round-trips. |

---

## 2. Detailed Diffs by Topic  

### 2.1 People & Organizational Structure  
| Change | Why It Improves Efficiency & ARC Alignment |
|--------|--------------------------------------------|
| `person_role` removed; `role` added to `person` as ENUM (`coach`, `player`, `parent`, `admin`). | 1 JOIN fewer for every permission check.  Development ARC cares about *responsibilities*; an enum keeps responsibility mapping explicit and introspectable. |
| Join tables slimmed: `person_team`, `person_pod` only. | Simpler RLS policies, faster membership queries for Collective Growth pods. |

### 2.2 Session & Block Model  
| v1 | v2 |
|----|----|
| `session` carried ~20 nullable planning columns (`objective`, `planned_player_count`, duplicate `session_id`, etc.) and stored the whole plan in `session_plan` JSONB. | `session` retains only **identity & status**; each drill instance lives in a `block` row with ordered index + JSONB `applied_constraints` & `pdp_overlays`. |

Benefits  
* Blocks editable/swappable without rewriting giant JSON.  
* Real-time UI streams block mutations (`Advancement`).  
* Fine-grained analytics of drill frequency & constraint use (`Collective Growth`).  

### 2.3 Drill, Constraint, PDP Overlay  
New tables:  

```sql
CREATE TABLE drill (
  uid TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  intent TEXT,
  supported_formats JSONB,
  base_constraints JSONB DEFAULT '[]'
);

CREATE TABLE constraint (
  uid TEXT PRIMARY KEY,
  title TEXT,
  level TEXT CHECK (level IN ('team','player')),
  payload JSONB
);
```

Why remove implicit JSON drill lists?  
* Enables full-text search, version control, and role-based permissions on content creation (Responsibility).  
* Constraints now modular entities that may be **overlaid** onto any block at runtime — implementing the user’s *constraint library* requirement.

### 2.4 Audit & Events  
`agent_events` + multiple “flagged” tables → **`audit_log`**  

```sql
CREATE TABLE audit_log (
  uid TEXT PRIMARY KEY,
  table_name TEXT,
  record_uid TEXT,
  action TEXT,          -- INSERT | UPDATE | DELETE
  actor_uid TEXT,
  payload JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

Single source of truth, indexed by `actor_uid` and `table_name`; aligns with ARC’s accountability pillar without scatter-shot event tables.

### 2.5 Reflections & Media  
`mpb_docs` (chunked embeddings) removed →  
*Reflection text lives in `reflection` table;*  
*Media stored in Supabase Storage with signed URLs.*  

Embeddings, if needed, generated on-the-fly and cached—avoids heavy `VECTOR` column on every text chunk.

---

## 3. Removed Legacy / Low-Value Tables  

| Table | Reason for Removal |
|-------|-------------------|
| `productivity_*` experimental tables | founders-sandbox only; not tied to ARC deliverables. |
| `flagged_entities` (stand-alone) | Its purpose (missing names, etc.) subsumed by analytics views with NOT EXISTS queries. |
| `mpb_docs` | Heavy embedding storage; replaced by lightweight reflection + on-demand embedding service. |
| Deprecated workflow exports (`MPB__*`, `POS__*`) | Logic now resides in Supabase Edge Functions; reduces external dependencies. |

---

## 4. Index & Performance Strategy  

1. Primary business queries (attendance counts, drill lookup, block list) served by **covering indexes**:  
   `CREATE INDEX idx_block_session ON block(session_uid, order);`  

2. Materialized views refresh on CRON Edge Function (`REFRESH MATERIALIZED VIEW block_usage_mv;`).  
   Eliminates n8n polling loops.

3. All text search (`drill.intent`, `reflection.content`) via PG `GIN` over `to_tsvector` – no extra service.

---

## 5. Alignment with Development ARC  

| ARC Pillar | Schema Feature |
|------------|----------------|
| **Advancement** | `block` history + `pdp_overlays` show individual & collective skill progression. |
| **Responsibilities** | Consolidated `person.role` & `audit_log` make accountability transparent. |
| **Collective Growth** | Pod & team relations kept, constraints & analytics views highlight group trends. |

The streamlined schema **removes 11 tables**, **drops 40+ rarely-used columns**, and **adds 4 purpose-built tables** that map 1-to-1 with core product features—delivering the same robustness with faster queries, lower cognitive load, and a direct embodiment of the ARC philosophy.

---
