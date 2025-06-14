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
CREATE INDEX IF NOT EXISTS idx_pod_team ON pod(team_id);

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
CREATE INDEX IF NOT EXISTS idx_session_team ON session(team_id);
CREATE INDEX IF NOT EXISTS idx_session_pod ON session(pod_id);

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
  player_id  TEXT,
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
  player_id              TEXT,
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
CREATE INDEX IF NOT EXISTS idx_pdp_player ON pdp(player_id);

--------------------------------------------------------------------------------
-- JOIN TABLES
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS person_team (
  person_uid TEXT NOT NULL REFERENCES person(uid) ON DELETE CASCADE,
  team_id    TEXT NOT NULL REFERENCES team(id),
  PRIMARY KEY (person_uid, team_id)
);

CREATE TABLE IF NOT EXISTS person_pod (
  person_uid TEXT NOT NULL REFERENCES person(uid) ON DELETE CASCADE,
  pod_id     TEXT NOT NULL REFERENCES pod(id),
  PRIMARY KEY (person_uid, pod_id)
);

--------------------------------------------------------------------------------
-- Indexes for foreign keys introduced in this migration
--------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_flagged_entities_entity ON flagged_entities(entity_uid);
CREATE INDEX IF NOT EXISTS idx_pod_team ON pod(team_id);
CREATE INDEX IF NOT EXISTS idx_session_team ON session(team_id);
CREATE INDEX IF NOT EXISTS idx_session_pod ON session(pod_id);
CREATE INDEX IF NOT EXISTS idx_mpb_docs_player ON mpb_docs(player_uuid);
CREATE INDEX IF NOT EXISTS idx_mpb_docs_session ON mpb_docs(session_uuid);
CREATE INDEX IF NOT EXISTS idx_agent_events_player ON agent_events(player_id);
CREATE INDEX IF NOT EXISTS idx_agent_events_team ON agent_events(team_id);
CREATE INDEX IF NOT EXISTS idx_agent_events_agent ON agent_events(agent_id);
CREATE INDEX IF NOT EXISTS idx_pdp_player ON pdp(player_id);
CREATE INDEX IF NOT EXISTS idx_pdp_previous_version ON pdp(previous_version_id);
CREATE INDEX IF NOT EXISTS idx_person_team_person ON person_team(person_uid);
CREATE INDEX IF NOT EXISTS idx_person_team_team ON person_team(team_id);
CREATE INDEX IF NOT EXISTS idx_person_pod_person ON person_pod(person_uid);
CREATE INDEX IF NOT EXISTS idx_person_pod_pod ON person_pod(pod_id);

