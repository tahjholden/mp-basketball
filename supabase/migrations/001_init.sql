
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
-- PROFILE : holds PDP / attributes per actor
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS profile (
  id               TEXT PRIMARY KEY,         -- keeps column name “id” as in your UI
  actor_uid        TEXT NOT NULL REFERENCES actor(uid) ON DELETE CASCADE,
  attributes_json  JSONB NOT NULL DEFAULT '{}',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

--------------------------------------------------------------------------------
-- OBSERVATION : DevNote, CoachReflection, etc.
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS observation (
  uid         TEXT PRIMARY KEY,
  actor_uid   TEXT NOT NULL REFERENCES actor(uid) ON DELETE CASCADE,
  obs_type    TEXT NOT NULL CHECK (obs_type IN ('DevNote','CoachReflection','PlayerReflection')),
  payload     JSONB NOT NULL,
  timestamp   TIMESTAMPTZ NOT NULL,
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
-- DRILL : canonical drill definitions
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS drill (
  uid              TEXT PRIMARY KEY,
  source_uid       TEXT,
  name             TEXT NOT NULL,
  description      TEXT,
  players_off      INT,
  players_def      INT,
  players_neutral  INT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  org_uid          TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- DRILL_TAG : many‑to‑many drill ↔ tag
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS drill_tag (
  drill_uid    TEXT NOT NULL REFERENCES drill(uid) ON DELETE CASCADE,
  tag_uid      TEXT NOT NULL REFERENCES tag(uid)   ON DELETE CASCADE,
  weight       NUMERIC NOT NULL DEFAULT 1,
  context_json JSONB DEFAULT '{}',
  PRIMARY KEY (drill_uid, tag_uid)
);

--------------------------------------------------------------------------------
-- SESSION_DRILL : drills scheduled inside an intervention
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS session_drill (
  uid            TEXT PRIMARY KEY,
  practice_uid   TEXT NOT NULL REFERENCES intervention(uid) ON DELETE CASCADE,
  drill_uid      TEXT NOT NULL REFERENCES drill(uid)        ON DELETE CASCADE,
  seq_order      INT  NOT NULL,
  org_uid        TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- PERSON_EXPOSURE : tag exposures accumulated per actor per session_drill
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS person_exposure (
  uid               TEXT PRIMARY KEY,
  session_drill_uid TEXT NOT NULL REFERENCES session_drill(uid) ON DELETE CASCADE,
  person_uid        TEXT NOT NULL REFERENCES actor(uid)         ON DELETE CASCADE,
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
-- UDF : update_pdp(obs_uid) – writes last_observation into profile
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_pdp(obs_uid TEXT) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
  v_actor_uid TEXT;
BEGIN
  SELECT actor_uid INTO v_actor_uid FROM observation WHERE uid = obs_uid;
  UPDATE profile
     SET attributes_json = jsonb_set(attributes_json, '{last_observation}', to_jsonb(obs_uid), true)
   WHERE actor_uid = v_actor_uid;
END;
$$;

--------------------------------------------------------------------------------
-- Trigger: call update_pdp after DevNote / CoachReflection insert
--------------------------------------------------------------------------------
CREATE TRIGGER trg_update_pdp
AFTER INSERT ON observation
FOR EACH ROW
WHEN (NEW.obs_type IN ('DevNote','CoachReflection'))
EXECUTE PROCEDURE update_pdp(NEW.uid);

--------------------------------------------------------------------------------
-- UDF : expand_exposure() – creates person_exposure rows for each tag
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION expand_exposure() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  rec  RECORD;
BEGIN
  -- loop over tags attached to the drill
  FOR rec IN
      SELECT dt.tag_uid, a.uid AS person_uid
        FROM drill_tag dt
        CROSS JOIN actor a
        WHERE dt.drill_uid = NEW.drill_uid
          AND a.actor_type = 'Player'
  LOOP
    INSERT INTO person_exposure(uid, session_drill_uid, person_uid, tag_uid, count)
    VALUES (
      uuid_generate_v4()::text,
      NEW.uid,
      rec.person_uid,
      rec.tag_uid,
      1
    )
    ON CONFLICT (session_drill_uid, person_uid, tag_uid) DO UPDATE
    SET count = person_exposure.count + 1;
  END LOOP;
  RETURN NEW;
END;
$$;

--------------------------------------------------------------------------------
-- Trigger: fire expand_exposure after inserting a session_drill
--------------------------------------------------------------------------------
CREATE TRIGGER trg_expand_exposure
AFTER INSERT ON session_drill
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
