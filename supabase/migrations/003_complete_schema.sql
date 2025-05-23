-- 003_complete_schema.sql
-- Additional tables to align database with workflow schema

--------------------------------------------------------------------------------
-- flagged_entities (ensure table exists)
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS flagged_entities (
  uid         TEXT PRIMARY KEY,
  entity_uid  TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  reason      TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  org_uid     TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- TEAM table
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS team (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

--------------------------------------------------------------------------------
-- POD table
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pod (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  team_id    TEXT REFERENCES team(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

--------------------------------------------------------------------------------
-- SESSION table
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS session (
  id                    TEXT PRIMARY KEY,
  title                 TEXT,
  objective             TEXT,
  team_id               TEXT REFERENCES team(id),
  pod_id                TEXT REFERENCES pod(id),
  coach_id              TEXT,
  status                TEXT,
  planned_player_count  INT,
  session_notes         TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  advancement_levels    JSONB,
  responsibility_tiers  JSONB,
  collective_growth_phase TEXT,
  created_by            TEXT,
  last_updated          TIMESTAMPTZ,
  session_plan          JSONB,
  session_id            TEXT,
  session_date          DATE,
  start_time            TIME,
  end_time              TIME,
  duration_minutes      INT,
  location              TEXT,
  overall_theme_tags    JSONB,
  planned_attendance    JSONB,
  reflection_fields     JSONB
);

--------------------------------------------------------------------------------
-- MPB_DOCS table
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mpb_docs (
  id            TEXT PRIMARY KEY,
  file_path     TEXT,
  chunk_index   INT,
  content       TEXT,
  embedding     VECTOR(1536),
  player_uuid   TEXT,
  session_uuid  TEXT,
  tags          JSONB,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata      JSONB
);

--------------------------------------------------------------------------------
-- AGENT_EVENTS table
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS agent_events (
  id         TEXT PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  event_type TEXT,
  subject_id  TEXT,
  team_id    TEXT,
  agent_id   TEXT,
  details    JSONB,
  status     TEXT
);

--------------------------------------------------------------------------------
-- PDP table
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pdp (
  id                     TEXT PRIMARY KEY,
  subject_id              TEXT,
  is_current             BOOLEAN,
  skill_tags             JSONB,
  constraint_tags        JSONB,
  theme_tags             JSONB,
  pdp_text_full          TEXT,
  pdp_text_coach         TEXT,
  pdp_text_player        TEXT,
  source_observation_ids JSONB,
  previous_version_id    TEXT,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  skills_summary         TEXT,
  constraints_summary    TEXT,
  last_updated           TIMESTAMPTZ,
  advancement_level      TEXT,
  responsibility_tier    TEXT,
  collective_growth_phase TEXT,
  pdp_id                 TEXT,
  updated_at             TIMESTAMPTZ
);

--------------------------------------------------------------------------------
-- JOIN TABLES
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS player_team (
  subject_id TEXT,
  team_id   TEXT,
  PRIMARY KEY (subject_id, team_id)
);

CREATE TABLE IF NOT EXISTS player_pod (
  subject_id TEXT,
  pod_id    TEXT,
  PRIMARY KEY (subject_id, pod_id)
);

CREATE TABLE IF NOT EXISTS coach_team (
  coach_id TEXT,
  team_id  TEXT,
  PRIMARY KEY (coach_id, team_id)
);

CREATE TABLE IF NOT EXISTS coach_pod (
  coach_id TEXT,
  pod_id   TEXT,
  PRIMARY KEY (coach_id, pod_id)
);

