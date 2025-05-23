-- 001_init.sql  (MPOS‑Basketball)

--------------------------------------------------------------------------------
-- Extensions
--------------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

--------------------------------------------------------------------------------
-- ACTOR : players, coaches, teams, groups
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS actor (
  uid           TEXT PRIMARY KEY,
  first_name    TEXT,
  last_name     TEXT,
  display_name  TEXT NOT NULL,
  actor_type    TEXT NOT NULL CHECK (actor_type IN ('Player','Coach','Team','Group')),
  org_uid       TEXT DEFAULT 'ORG-DEFAULT',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS person (
  uid TEXT PRIMARY KEY REFERENCES actor(uid) ON DELETE CASCADE
);

-- PROFILE : holds PDP / attributes per actor
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS profile (
  id               TEXT PRIMARY KEY,         -- keeps column name “id” as in your UI
  actor_uid        TEXT NOT NULL REFERENCES actor(uid) ON DELETE CASCADE,
  attributes_json  JSONB NOT NULL DEFAULT '{}',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

--------------------------------------------------------------------------------
-- JOURNAL_ENTRY : personal notes and reflections
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS journal_entry (
  uid         TEXT PRIMARY KEY,
  actor_uid   TEXT NOT NULL REFERENCES actor(uid) ON DELETE CASCADE,
  subject_id  TEXT REFERENCES person(uid),
  obs_type    TEXT NOT NULL CHECK (obs_type IN ('Reflection','GoalProgress','Idea')),
  payload     JSONB NOT NULL,
  timestamp   TIMESTAMPTZ NOT NULL,
  session_uid TEXT REFERENCES intervention(uid),
  tagged_skills JSONB DEFAULT '[]'::jsonb,
  predicted_tag_uid TEXT,     -- filled by GPT tagger later
  org_uid     TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- INTERVENTION : practice session, game, etc.
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS intervention (
  uid                TEXT PRIMARY KEY,
  intervention_type  TEXT NOT NULL,
  description        TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  org_uid            TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- METRIC : generic metrics per actor
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS metric (
  uid          TEXT PRIMARY KEY,
  actor_uid    TEXT NOT NULL REFERENCES actor(uid) ON DELETE CASCADE,
  metric_type  TEXT NOT NULL,
  value        JSONB NOT NULL,
  timestamp    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  org_uid      TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- LINK : generic parent‑child relation
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS link (
  uid            TEXT PRIMARY KEY,
  parent_uid     TEXT NOT NULL,
  relation_type  TEXT NOT NULL,
  child_uid      TEXT NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  org_uid        TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- TAG : skills / constraints (optional embeddings)
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tag (
  uid         TEXT PRIMARY KEY,
  category    TEXT NOT NULL,
  name        TEXT NOT NULL,
  embeddings  VECTOR(1536),
  org_uid     TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- ROUTINE : canonical routine definitions
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS routine (
  uid              TEXT PRIMARY KEY,
  source_uid       TEXT,
  name             TEXT NOT NULL,
  description      TEXT,
  participants_off      INT,
  participants_def      INT,
  participants_neutral  INT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  org_uid          TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- ROUTINE_TAG : many‑to‑many routine ↔ tag
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS routine_tag (
  routine_uid    TEXT NOT NULL REFERENCES routine(uid) ON DELETE CASCADE,
  tag_uid      TEXT NOT NULL REFERENCES tag(uid)   ON DELETE CASCADE,
  weight       NUMERIC NOT NULL DEFAULT 1,
  context_json JSONB DEFAULT '{}',
  PRIMARY KEY (routine_uid, tag_uid)
);

--------------------------------------------------------------------------------
-- ROUTINE_INSTANCE : routines scheduled inside an intervention
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS routine_instance (
  uid            TEXT PRIMARY KEY,
  intervention_uid TEXT NOT NULL REFERENCES intervention(uid) ON DELETE CASCADE,
  routine_uid      TEXT NOT NULL REFERENCES routine(uid)        ON DELETE CASCADE,
  seq_order      INT  NOT NULL,
  org_uid        TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- HABIT_EXPOSURE : tag exposures accumulated per player per routine_instance
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS habit_exposure (
  uid               TEXT PRIMARY KEY,
  routine_instance_uid TEXT NOT NULL REFERENCES routine_instance(uid) ON DELETE CASCADE,
  player_uid        TEXT NOT NULL REFERENCES actor(uid)         ON DELETE CASCADE,
  tag_uid           TEXT NOT NULL REFERENCES tag(uid)           ON DELETE CASCADE,
  count             INT  NOT NULL DEFAULT 1
);

--------------------------------------------------------------------------------
-- TAG_RELATION : hierarchical or exclusive tag links
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tag_relation (
  uid             TEXT PRIMARY KEY,
  tag_id_parent   TEXT NOT NULL REFERENCES tag(uid) ON DELETE CASCADE,
  relation_type   TEXT NOT NULL,
  tag_id_child    TEXT NOT NULL REFERENCES tag(uid) ON DELETE CASCADE
);

--------------------------------------------------------------------------------
-- Indexes for common foreign key joins
--------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_profile_actor ON profile(actor_uid);
CREATE INDEX IF NOT EXISTS idx_observation_actor ON observation(actor_uid);
CREATE INDEX IF NOT EXISTS idx_metric_actor ON metric(actor_uid);
CREATE INDEX IF NOT EXISTS idx_link_parent ON link(parent_uid);
CREATE INDEX IF NOT EXISTS idx_link_child ON link(child_uid);
CREATE INDEX IF NOT EXISTS idx_routine_tag_routine ON routine_tag(routine_uid);
CREATE INDEX IF NOT EXISTS idx_routine_tag_tag ON routine_tag(tag_uid);
CREATE INDEX IF NOT EXISTS idx_routine_instance_intervention ON routine_instance(intervention_uid);
CREATE INDEX IF NOT EXISTS idx_routine_instance_routine ON routine_instance(routine_uid);
CREATE INDEX IF NOT EXISTS idx_habit_exposure_instance ON habit_exposure(routine_instance_uid);
CREATE INDEX IF NOT EXISTS idx_habit_exposure_player ON habit_exposure(player_uid);
CREATE INDEX IF NOT EXISTS idx_habit_exposure_tag ON habit_exposure(tag_uid);
CREATE INDEX IF NOT EXISTS idx_tag_relation_parent ON tag_relation(tag_id_parent);
CREATE INDEX IF NOT EXISTS idx_tag_relation_child ON tag_relation(tag_id_child);

--------------------------------------------------------------------------------
-- UDF : update_pdp(obs_uid) – writes last_observation into profile
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_pdp(obs_uid TEXT) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
  v_actor_uid TEXT;
BEGIN
  SELECT actor_uid INTO v_actor_uid FROM journal_entry WHERE uid = obs_uid;
  UPDATE profile
     SET attributes_json = jsonb_set(attributes_json, '{last_observation}', to_jsonb(obs_uid), true)
   WHERE actor_uid = v_actor_uid;
END;
$$;

--------------------------------------------------------------------------------
-- Trigger: call update_pdp after DevNote / CoachReflection insert
--------------------------------------------------------------------------------
CREATE TRIGGER trg_update_pdp
AFTER INSERT ON journal_entry
FOR EACH ROW
WHEN (NEW.obs_type IN ('Reflection','GoalProgress','Idea'))
EXECUTE PROCEDURE update_pdp(NEW.uid);

--------------------------------------------------------------------------------
-- UDF : expand_exposure() – creates habit_exposure rows for each tag
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION expand_exposure() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  rec  RECORD;
BEGIN
  -- loop over tags attached to the routine
  FOR rec IN
      SELECT dt.tag_uid, a.uid AS player_uid
        FROM routine_tag dt
        CROSS JOIN actor a
        WHERE dt.routine_uid = NEW.routine_uid
          AND a.actor_type = 'Player'
  LOOP
    INSERT INTO habit_exposure(uid, routine_instance_uid, player_uid, tag_uid, count)
    VALUES (
      uuid_generate_v4()::text,
      NEW.uid,
      rec.player_uid,
      rec.tag_uid,
      1
    )
    ON CONFLICT (routine_instance_uid, player_uid, tag_uid) DO UPDATE
    SET count = habit_exposure.count + 1;
  END LOOP;
  RETURN NEW;
END;
$$;

--------------------------------------------------------------------------------
-- Trigger: fire expand_exposure after inserting a routine_instance
--------------------------------------------------------------------------------
CREATE TRIGGER trg_expand_exposure
AFTER INSERT ON routine_instance
FOR EACH ROW
EXECUTE PROCEDURE expand_exposure();

--------------------------------------------------------------------------------
-- Basic RLS Templates (disabled by default)
--------------------------------------------------------------------------------
ALTER TABLE actor ENABLE ROW LEVEL SECURITY;
ALTER TABLE actor FORCE ROW LEVEL SECURITY;
-- Example policy: allow org members read
CREATE POLICY actor_select_org ON actor
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- Repeat similar RLS policies for other tables as needed.
