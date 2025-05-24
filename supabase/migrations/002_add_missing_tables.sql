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
-- Index for quick lookup by entity
CREATE INDEX IF NOT EXISTS idx_flagged_entities_entity ON flagged_entities(entity_uid);

--------------------------------------------------------------------------------
-- Remove legacy player and coach tables if they exist
DROP TABLE IF EXISTS player CASCADE;
DROP TABLE IF EXISTS coach  CASCADE;

--------------------------------------------------------------------------------
-- rename actor table and update references
-- person_role table (replaces player/coach subtypes)
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS person_role (
  uid         TEXT PRIMARY KEY,
  person_uid  TEXT NOT NULL REFERENCES person(uid) ON DELETE CASCADE,
  role        TEXT NOT NULL,
  attributes  JSONB DEFAULT '{}'
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
CREATE INDEX IF NOT EXISTS idx_observation_logs_observation ON observation_logs(observation_uid);

--------------------------------------------------------------------------------
-- journal_entry table updates
--------------------------------------------------------------------------------
-- rename actor table and update references
ALTER TABLE observation
-- decide and update observation table reference
  ADD COLUMN IF NOT EXISTS session_uid TEXT REFERENCES intervention(uid),
  ADD COLUMN IF NOT EXISTS tagged_skills JSONB DEFAULT '[]'::jsonb;
CREATE INDEX IF NOT EXISTS idx_observation_person ON observation(person_id);
CREATE INDEX IF NOT EXISTS idx_observation_session ON observation(session_uid);
