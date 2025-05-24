-- 001_init.sql  (MPOS‑Basketball)

--------------------------------------------------------------------------------
-- Extensions
--------------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

--------------------------------------------------------------------------------
-- PERSON : users, family, mentors, groups
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS person (
  uid           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  first_name    TEXT,
  last_name     TEXT,
  display_name  TEXT NOT NULL,
  role_type     TEXT NOT NULL CHECK (role_type IN ('User','FamilyMember','Mentor','Group')),
  org_uid       TEXT DEFAULT 'ORG-DEFAULT',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

--------------------------------------------------------------------------------


CREATE TABLE IF NOT EXISTS person (
  uid UUID PRIMARY KEY REFERENCES actor(uid) ON DELETE CASCADE
);

-- PROFILE : holds PDP / attributes per actor
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS profile (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),         -- keeps column name "id" as in your UI
  person_uid       UUID NOT NULL REFERENCES person(uid) ON DELETE CASCADE,
  attributes_json  JSONB NOT NULL DEFAULT '{}',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

--------------------------------------------------------------------------------
-- JOURNAL_ENTRY : personal notes and reflections
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS journal_entry (
  uid         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
codex/decide-and-update-observation-table-reference
  person_id   UUID NOT NULL REFERENCES actor(uid) ON DELETE CASCADE,
  obs_type    TEXT NOT NULL CHECK (obs_type IN ('DevNote','CoachReflection','PlayerReflection')),
  payload     JSONB NOT NULL,
  timestamp   TIMESTAMPTZ NOT NULL,
  session_uid UUID REFERENCES intervention(uid),
  tagged_skills JSONB DEFAULT '[]'::jsonb,
  predicted_tag_uid UUID,     -- filled by GPT tagger later
  org_uid     TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- INTERVENTION : practice session, game, etc.
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS intervention (
  uid                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  intervention_type  TEXT NOT NULL,
  description        TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  org_uid            TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- METRIC : generic metrics per person
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS metric (
  uid          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_uid   UUID NOT NULL REFERENCES person(uid) ON DELETE CASCADE,
  metric_type  TEXT NOT NULL,
  value        JSONB NOT NULL,
  timestamp    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  org_uid      TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- LINK : generic parent‑child relation
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS link (
  uid            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  parent_uid     UUID NOT NULL,
  relation_type  TEXT NOT NULL,
  child_uid      UUID NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  org_uid        TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- TAG : skills / constraints (optional embeddings)
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tag (
  uid         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category    TEXT NOT NULL,
  name        TEXT NOT NULL,
  embeddings  VECTOR(1536),
  org_uid     TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- ROUTINE : canonical routine definitions
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS routine (
  uid              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_uid       UUID,
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
  routine_uid    UUID NOT NULL REFERENCES routine(uid) ON DELETE CASCADE,
  tag_uid      UUID NOT NULL REFERENCES tag(uid)   ON DELETE CASCADE,
  weight       NUMERIC NOT NULL DEFAULT 1,
  context_json JSONB DEFAULT '{}',
  PRIMARY KEY (routine_uid, tag_uid)
);

--------------------------------------------------------------------------------
-- ROUTINE_INSTANCE : routines scheduled inside an intervention
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS routine_instance (
  uid            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  intervention_uid UUID NOT NULL REFERENCES intervention(uid) ON DELETE CASCADE,
  routine_uid      UUID NOT NULL REFERENCES routine(uid)        ON DELETE CASCADE,
  seq_order      INT  NOT NULL,
  org_uid        TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
codex/rename-player_exposure-and-adjust-foreign-keys
-- PERSON_EXPOSURE : tag exposures accumulated per actor per session_drill
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS person_exposure (
  uid               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
codex/rename-actor-table-and-update-references
  session_drill_uid UUID NOT NULL REFERENCES session_drill(uid) ON DELETE CASCADE,
codex/rename-player_exposure-and-adjust-foreign-keys
  person_uid        UUID NOT NULL REFERENCES actor(uid)         ON DELETE CASCADE,
  tag_uid           UUID NOT NULL REFERENCES tag(uid)           ON DELETE CASCADE,
  count             INT  NOT NULL DEFAULT 1
);

--------------------------------------------------------------------------------
-- TAG_RELATION : hierarchical or exclusive tag links
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tag_relation (
  uid             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tag_id_parent   UUID NOT NULL REFERENCES tag(uid) ON DELETE CASCADE,
  relation_type   TEXT NOT NULL,
  tag_id_child    UUID NOT NULL REFERENCES tag(uid) ON DELETE CASCADE
);

--------------------------------------------------------------------------------
-- Indexes for common foreign key joins
--------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_profile_actor ON profile(person_uid);
CREATE INDEX IF NOT EXISTS idx_observation_actor ON observation(person_id);
CREATE INDEX IF NOT EXISTS idx_metric_actor ON metric(person_uid);
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
CREATE OR REPLACE FUNCTION update_pdp(obs_uid UUID) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
codex/decide-and-update-observation-table-reference
  v_person_id UUID;
BEGIN
  SELECT person_id INTO v_person_id FROM observation WHERE uid = obs_uid;
  UPDATE profile
     SET attributes_json = jsonb_set(attributes_json, '{last_observation}', to_jsonb(obs_uid), true)
   WHERE person_uid = v_person_id;
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
codex/rename-player_exposure-and-adjust-foreign-keys
-- UDF : expand_exposure() – creates person_exposure rows for each tag
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION expand_exposure() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  rec  RECORD;
BEGIN
  -- loop over tags attached to the routine
  FOR rec IN
codex/rename-player_exposure-and-adjust-foreign-keys
      SELECT dt.tag_uid, a.uid AS person_uid
        FROM drill_tag dt
        CROSS JOIN person_role pr
        WHERE dt.drill_uid = NEW.drill_uid
          AND pr.role = 'Player'
  LOOP
codex/rename-player_exposure-and-adjust-foreign-keys
    INSERT INTO person_exposure(uid, session_drill_uid, person_uid, tag_uid, count)
    VALUES (
      uuid_generate_v4(),
      NEW.uid,
      rec.person_uid,
      rec.tag_uid,
      1
    )
codex/rename-player_exposure-and-adjust-foreign-keys
    ON CONFLICT (session_drill_uid, person_uid, tag_uid) DO UPDATE
    SET count = person_exposure.count + 1;

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
ALTER TABLE person ENABLE ROW LEVEL SECURITY;
ALTER TABLE person FORCE ROW LEVEL SECURITY;
-- Example policy: allow org members read
CREATE POLICY person_select_org ON person
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- Repeat similar RLS policies for other tables as needed.
