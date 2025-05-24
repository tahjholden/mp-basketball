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

--------------------------------------------------------------------------------
-- journal_entry table updates
--------------------------------------------------------------------------------
-- rename actor table and update references
ALTER TABLE observation
-- decide and update observation table reference
  ADD COLUMN IF NOT EXISTS session_uid TEXT REFERENCES intervention(uid),
  ADD COLUMN IF NOT EXISTS tagged_skills JSONB DEFAULT '[]'::jsonb;

--------------------------------------------------------------------------------
-- Indexes for new foreign keys
--------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_flagged_entities_entity ON flagged_entities(entity_uid);
-- index for fast lookup of log entries by associated observation
CREATE INDEX IF NOT EXISTS idx_journal_entry_logs_observation_uid ON journal_entry_logs(observation_uid);
CREATE INDEX IF NOT EXISTS idx_observation_person ON observation(person_id);
CREATE INDEX IF NOT EXISTS idx_observation_session ON observation(session_uid);
