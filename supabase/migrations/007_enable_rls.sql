-- 007_enable_rls.sql
-- Enable row level security for core tables and add org-based policies.

-- PROFILE
ALTER TABLE profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS profile_select_org ON profile;
CREATE POLICY profile_select_org ON profile
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM person p
       WHERE p.uid = profile.person_uid
         AND p.org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid'
    )
  );

-- JOURNAL_ENTRY (observations)
ALTER TABLE journal_entry ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entry FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS journal_entry_select_org ON journal_entry;
CREATE POLICY journal_entry_select_org ON journal_entry
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM person p
       WHERE p.uid = journal_entry.person_id
         AND p.org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid'
    )
  );

-- INTERVENTION
ALTER TABLE intervention ENABLE ROW LEVEL SECURITY;
ALTER TABLE intervention FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS intervention_select_org ON intervention;
CREATE POLICY intervention_select_org ON intervention
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- METRIC
ALTER TABLE metric ENABLE ROW LEVEL SECURITY;
ALTER TABLE metric FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS metric_select_org ON metric;
CREATE POLICY metric_select_org ON metric
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM person p
       WHERE p.uid = metric.person_uid
         AND p.org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid'
    )
  );

-- LINK
ALTER TABLE link ENABLE ROW LEVEL SECURITY;
ALTER TABLE link FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS link_select_org ON link;
CREATE POLICY link_select_org ON link
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- TAG
ALTER TABLE tag ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tag_select_org ON tag;
CREATE POLICY tag_select_org ON tag
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- ROUTINE
ALTER TABLE routine ENABLE ROW LEVEL SECURITY;
ALTER TABLE routine FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS routine_select_org ON routine;
CREATE POLICY routine_select_org ON routine
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- ROUTINE_TAG
ALTER TABLE routine_tag ENABLE ROW LEVEL SECURITY;
ALTER TABLE routine_tag FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS routine_tag_select_org ON routine_tag;
CREATE POLICY routine_tag_select_org ON routine_tag
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM routine r
       WHERE r.uid = routine_tag.routine_uid
         AND r.org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid'
    )
  );

-- ROUTINE_INSTANCE
ALTER TABLE routine_instance ENABLE ROW LEVEL SECURITY;
ALTER TABLE routine_instance FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS routine_instance_select_org ON routine_instance;
CREATE POLICY routine_instance_select_org ON routine_instance
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- PERSON_EXPOSURE
ALTER TABLE person_exposure ENABLE ROW LEVEL SECURITY;
ALTER TABLE person_exposure FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS person_exposure_select_org ON person_exposure;
CREATE POLICY person_exposure_select_org ON person_exposure
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM person p
       WHERE p.uid = person_exposure.person_uid
         AND p.org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid'
    )
  );

-- TAG_RELATION
ALTER TABLE tag_relation ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_relation FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tag_relation_select_org ON tag_relation;
CREATE POLICY tag_relation_select_org ON tag_relation
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM tag t
       WHERE t.uid = tag_relation.tag_id_parent
         AND t.org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid'
    )
    AND EXISTS (
      SELECT 1 FROM tag t
       WHERE t.uid = tag_relation.tag_id_child
         AND t.org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid'
    )
  );

-- FLAGGED_ENTITIES
ALTER TABLE flagged_entities ENABLE ROW LEVEL SECURITY;
ALTER TABLE flagged_entities FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS flagged_entities_select_org ON flagged_entities;
CREATE POLICY flagged_entities_select_org ON flagged_entities
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- PERSON_ROLE
ALTER TABLE person_role ENABLE ROW LEVEL SECURITY;
ALTER TABLE person_role FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS person_role_select_org ON person_role;
CREATE POLICY person_role_select_org ON person_role
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM person p
       WHERE p.uid = person_role.person_uid
         AND p.org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid'
    )
  );

-- JOURNAL_ENTRY_LOGS
ALTER TABLE journal_entry_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entry_logs FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS journal_entry_logs_select_org ON journal_entry_logs;
CREATE POLICY journal_entry_logs_select_org ON journal_entry_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM journal_entry j
       JOIN person p ON p.uid = j.person_id
       WHERE j.uid = journal_entry_logs.observation_uid
         AND p.org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid'
    )
  );

-- MOOD_LOG
ALTER TABLE mood_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE mood_log FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mood_log_select_org ON mood_log;
CREATE POLICY mood_log_select_org ON mood_log
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- HABIT
ALTER TABLE habit ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS habit_select_org ON habit;
CREATE POLICY habit_select_org ON habit
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- HABIT_EVENT
ALTER TABLE habit_event ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_event FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS habit_event_select_org ON habit_event;
CREATE POLICY habit_event_select_org ON habit_event
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- GOAL
ALTER TABLE goal ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS goal_select_org ON goal;
CREATE POLICY goal_select_org ON goal
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- PROJECT
ALTER TABLE project ENABLE ROW LEVEL SECURITY;
ALTER TABLE project FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS project_select_org ON project;
CREATE POLICY project_select_org ON project
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- TASK
ALTER TABLE task ENABLE ROW LEVEL SECURITY;
ALTER TABLE task FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS task_select_org ON task;
CREATE POLICY task_select_org ON task
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

