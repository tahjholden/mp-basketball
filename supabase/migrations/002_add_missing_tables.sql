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
-- player table (subtype of actor)
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS player (
  uid         TEXT PRIMARY KEY REFERENCES actor(uid) ON DELETE CASCADE,
  jersey_num  TEXT,
  position    TEXT
);

--------------------------------------------------------------------------------
-- coach table (subtype of actor)
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS coach (
  uid         TEXT PRIMARY KEY REFERENCES actor(uid) ON DELETE CASCADE,
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
ALTER TABLE journal_entry
  ADD COLUMN IF NOT EXISTS subject_id   TEXT REFERENCES person(uid),
  ADD COLUMN IF NOT EXISTS session_uid TEXT REFERENCES intervention(uid),
  ADD COLUMN IF NOT EXISTS tagged_skills JSONB DEFAULT '[]'::jsonb;
