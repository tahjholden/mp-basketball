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



-- PROFILE : holds PDP / attributes per actor
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS profile (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),         -- keeps column name "id" as in your UI
  person_uid       UUID NOT NULL REFERENCES person(uid) ON DELETE CASCADE,
  attributes_json  JSONB NOT NULL DEFAULT '{}',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- Indexes for fast joins on foreign keys
CREATE INDEX IF NOT EXISTS idx_profile_actor ON profile(actor_uid);

--------------------------------------------------------------------------------
-- JOURNAL_ENTRY : personal notes and reflections
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS journal_entry (
  uid         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
-- decide and update observation table reference
  person_id   UUID NOT NULL REFERENCES person(uid) ON DELETE CASCADE,
  obs_type    TEXT NOT NULL CHECK (obs_type IN ('DevNote','CoachReflection','PlayerReflection')),
  payload     JSONB NOT NULL,
  timestamp   TIMESTAMPTZ NOT NULL,
  session_uid UUID REFERENCES intervention(uid),
  tagged_skills JSONB DEFAULT '[]'::jsonb,
  predicted_tag_uid UUID,     -- filled by GPT tagger later
  org_uid     TEXT DEFAULT 'ORG-DEFAULT'
);
CREATE INDEX IF NOT EXISTS idx_observation_actor ON observation(actor_uid);

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
CREATE INDEX IF NOT EXISTS idx_metric_actor ON metric(actor_uid);

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
CREATE INDEX IF NOT EXISTS idx_link_parent ON link(parent_uid);
CREATE INDEX IF NOT EXISTS idx_link_child ON link(child_uid);

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
CREATE INDEX IF NOT EXISTS idx_routine_tag_routine ON routine_tag(routine_uid);
CREATE INDEX IF NOT EXISTS idx_routine_tag_tag ON routine_tag(tag_uid);

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
CREATE INDEX IF NOT EXISTS idx_routine_instance_intervention ON routine_instance(intervention_uid);
CREATE INDEX IF NOT EXISTS idx_routine_instance_routine ON routine_instance(routine_uid);

--------------------------------------------------------------------------------
-- rename player_exposure table and adjust foreign keys
-- PERSON_EXPOSURE : tag exposures accumulated per actor per session_drill
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS person_exposure (
  uid               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
-- rename actor table and update references
  session_drill_uid UUID NOT NULL REFERENCES session_drill(uid) ON DELETE CASCADE,
-- rename player_exposure table and adjust foreign keys
  person_uid        UUID NOT NULL REFERENCES person(uid)         ON DELETE CASCADE,
  tag_uid           UUID NOT NULL REFERENCES tag(uid)           ON DELETE CASCADE,
  count             INT  NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_habit_exposure_instance ON habit_exposure(routine_instance_uid);
CREATE INDEX IF NOT EXISTS idx_habit_exposure_player ON habit_exposure(player_uid);
CREATE INDEX IF NOT EXISTS idx_habit_exposure_tag ON habit_exposure(tag_uid);

--------------------------------------------------------------------------------
-- TAG_RELATION : hierarchical or exclusive tag links
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tag_relation (
  uid             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tag_id_parent   UUID NOT NULL REFERENCES tag(uid) ON DELETE CASCADE,
  relation_type   TEXT NOT NULL,
  tag_id_child    UUID NOT NULL REFERENCES tag(uid) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_tag_relation_parent ON tag_relation(tag_id_parent);
CREATE INDEX IF NOT EXISTS idx_tag_relation_child ON tag_relation(tag_id_child);

--------------------------------------------------------------------------------
-- FLAGGED_NAME : store unmatched player names
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS flagged_name (
  uid UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  raw_observation_id UUID REFERENCES observation(uid) ON DELETE CASCADE,
  flagged_name       TEXT NOT NULL,
  category           TEXT,
  observation_text   TEXT,
  flagged_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  attempted_match_at TIMESTAMPTZ,
  matched_person_uid UUID REFERENCES person(uid),
  resolved_at        TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  org_uid            TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- UNMATCHED_PLAYER_NAME : alternate log for unresolved names
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS unmatched_player_name (
  uid UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  raw_observation_id TEXT REFERENCES observation(id) ON DELETE CASCADE,
  flagged_name       TEXT NOT NULL,
  category           TEXT,
  observation_text   TEXT,
  flagged_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  attempted_match    BOOLEAN DEFAULT FALSE,
  attempted_match_at TIMESTAMPTZ,
  matched_person_uid TEXT REFERENCES person(uid),
  resolved_at        TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  org_uid            TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- FLAGGED_ENTITIES : generic table for problematic records
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
-- PERSON_ROLE : normalized roles per person
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS person_role (
  uid         TEXT PRIMARY KEY,
  person_uid  TEXT NOT NULL REFERENCES person(uid) ON DELETE CASCADE,
  role        TEXT NOT NULL,
  attributes  JSONB DEFAULT '{}'
);

--------------------------------------------------------------------------------
-- JOURNAL_ENTRY_LOGS : change history for observations
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS journal_entry_logs (
  uid             TEXT PRIMARY KEY,
  observation_uid TEXT NOT NULL REFERENCES journal_entry(uid) ON DELETE CASCADE,
  log_entry       JSONB NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
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

--------------------------------------------------------------------------------
-- JOIN TABLES
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS player_team (
  player_id TEXT,
  team_id   TEXT,
  PRIMARY KEY (player_id, team_id)
);

CREATE TABLE IF NOT EXISTS player_pod (
  player_id TEXT,
  pod_id    TEXT,
  PRIMARY KEY (player_id, pod_id)
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

--------------------------------------------------------------------------------
-- MOOD_LOG table
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mood_log (
  uid         TEXT PRIMARY KEY,
  person_id   TEXT NOT NULL REFERENCES person(uid) ON DELETE CASCADE,
  mood        TEXT NOT NULL,
  note        TEXT,
  timestamp   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  org_uid     TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- HABIT table
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS habit (
  uid         TEXT PRIMARY KEY,
  person_id   TEXT NOT NULL REFERENCES person(uid) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  org_uid     TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- HABIT_EVENT table
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS habit_event (
  uid         TEXT PRIMARY KEY,
  habit_id    TEXT NOT NULL REFERENCES habit(uid) ON DELETE CASCADE,
  timestamp   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status      TEXT,
  org_uid     TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- GOAL table
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS goal (
  uid          TEXT PRIMARY KEY,
  person_id    TEXT NOT NULL REFERENCES person(uid) ON DELETE CASCADE,
  title        TEXT NOT NULL,
  details      TEXT,
  status       TEXT,
  due_date     DATE,
  completed_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ,
  org_uid      TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- PROJECT table
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS project (
  uid          TEXT PRIMARY KEY,
  owner_id     TEXT REFERENCES person(uid) ON DELETE SET NULL,
  title        TEXT NOT NULL,
  description  TEXT,
  status       TEXT,
  start_date   DATE,
  due_date     DATE,
  completed_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ,
  org_uid      TEXT DEFAULT 'ORG-DEFAULT'
);

--------------------------------------------------------------------------------
-- TASK table
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS task (
  uid          TEXT PRIMARY KEY,
  project_id   TEXT REFERENCES project(uid) ON DELETE CASCADE,
  assignee_id  TEXT REFERENCES person(uid) ON DELETE SET NULL,
  title        TEXT NOT NULL,
  details      TEXT,
  status       TEXT,
  due_date     DATE,
  completed_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ,
  org_uid      TEXT DEFAULT 'ORG-DEFAULT'
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
CREATE INDEX IF NOT EXISTS idx_flagged_name_observation ON flagged_name(raw_observation_id);
-- extend supabase 001_init.sql with schema
CREATE INDEX IF NOT EXISTS idx_flagged_entities_entity ON flagged_entities(entity_uid);
-- index for fast lookup of log entries by associated observation
CREATE INDEX IF NOT EXISTS idx_journal_entry_logs_observation_uid ON journal_entry_logs(observation_uid);
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
CREATE INDEX IF NOT EXISTS idx_player_team_player ON player_team(player_id);
CREATE INDEX IF NOT EXISTS idx_player_team_team ON player_team(team_id);
CREATE INDEX IF NOT EXISTS idx_player_pod_player ON player_pod(player_id);
CREATE INDEX IF NOT EXISTS idx_player_pod_pod ON player_pod(pod_id);
CREATE INDEX IF NOT EXISTS idx_coach_team_coach ON coach_team(coach_id);
CREATE INDEX IF NOT EXISTS idx_coach_team_team ON coach_team(team_id);
CREATE INDEX IF NOT EXISTS idx_coach_pod_coach ON coach_pod(coach_id);
CREATE INDEX IF NOT EXISTS idx_coach_pod_pod ON coach_pod(pod_id);
CREATE INDEX IF NOT EXISTS idx_mood_log_person ON mood_log(person_id);
CREATE INDEX IF NOT EXISTS idx_mood_log_timestamp ON mood_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_habit_person ON habit(person_id);
CREATE INDEX IF NOT EXISTS idx_habit_event_habit ON habit_event(habit_id);
CREATE INDEX IF NOT EXISTS idx_habit_event_timestamp ON habit_event(timestamp);
CREATE INDEX IF NOT EXISTS idx_goal_person ON goal(person_id);
CREATE INDEX IF NOT EXISTS idx_project_owner ON project(owner_id);
CREATE INDEX IF NOT EXISTS idx_task_project ON task(project_id);
CREATE INDEX IF NOT EXISTS idx_task_assignee ON task(assignee_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_player_exposure_triplet ON player_exposure(session_drill_uid, person_uid, tag_uid);


--------------------------------------------------------------------------------
-- UDF : update_pdp(obs_uid) – writes last_observation into profile
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_pdp(obs_uid UUID) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
-- decide and update observation table reference
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
-- rename player_exposure table and adjust foreign keys
-- UDF : expand_exposure() – creates person_exposure rows for each tag
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION expand_exposure() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  rec  RECORD;
BEGIN
  -- loop over tags attached to the routine
  FOR rec IN
-- rename player_exposure table and adjust foreign keys
      SELECT dt.tag_uid, a.uid AS person_uid
        FROM drill_tag dt
        CROSS JOIN person_role pr
        WHERE dt.drill_uid = NEW.drill_uid
          AND pr.role = 'Player'
  LOOP
-- rename player_exposure table and adjust foreign keys
    INSERT INTO person_exposure(uid, session_drill_uid, person_uid, tag_uid, count)
    VALUES (
      uuid_generate_v4(),
      NEW.uid,
      rec.person_uid,
      rec.tag_uid,
      1
    )
-- rename player_exposure table and adjust foreign keys
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

ALTER TABLE flagged_name ENABLE ROW LEVEL SECURITY;
ALTER TABLE flagged_name FORCE ROW LEVEL SECURITY;
CREATE POLICY flagged_name_select_org ON flagged_name
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

ALTER TABLE unmatched_player_name ENABLE ROW LEVEL SECURITY;
ALTER TABLE unmatched_player_name FORCE ROW LEVEL SECURITY;
CREATE POLICY unmatched_player_name_select_org ON unmatched_player_name
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- Repeat similar RLS policies for other tables as needed.

