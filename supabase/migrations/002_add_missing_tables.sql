-- 002_add_missing_tables.sql

--------------------------------------------------------------------------------
-- flagged_entities table
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS flagged_entities (
  uid            TEXT PRIMARY KEY,
  entity_uid     TEXT NOT NULL,
  entity_type    TEXT NOT NULL,
  reason         TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  org_uid        TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- Remove legacy player and coach tables if they exist
DROP TABLE IF EXISTS player CASCADE;
DROP TABLE IF EXISTS coach  CASCADE;

--------------------------------------------------------------------------------
-- person table (replaces player and coach)
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS person (
  uid         TEXT PRIMARY KEY REFERENCES actor(uid) ON DELETE CASCADE,
  jersey_num  TEXT,
  position    TEXT,
  role        TEXT
);

--------------------------------------------------------------------------------
-- journal_entry_logs table
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS journal_entry_logs (
  uid             TEXT PRIMARY KEY,
  observation_uid TEXT NOT NULL REFERENCES journal_entry(uid) ON DELETE CASCADE,
  log_entry       JSONB NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

--------------------------------------------------------------------------------
-- journal_entry table updates
--------------------------------------------------------------------------------
codex/refactor-observation-schema-and-workflows
ALTER TABLE journal_entry
  ADD COLUMN IF NOT EXISTS subject_id   TEXT REFERENCES person(uid),

  ADD COLUMN IF NOT EXISTS session_uid TEXT REFERENCES intervention(uid),
  ADD COLUMN IF NOT EXISTS tagged_skills JSONB DEFAULT '[]'::jsonb;

--------------------------------------------------------------------------------
-- Indexes for new foreign keys
--------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_flagged_entities_entity ON flagged_entities(entity_uid);
CREATE INDEX IF NOT EXISTS idx_observation_logs_observation ON observation_logs(observation_uid);
CREATE INDEX IF NOT EXISTS idx_observation_person ON observation(person_id);
CREATE INDEX IF NOT EXISTS idx_observation_session ON observation(session_uid);
