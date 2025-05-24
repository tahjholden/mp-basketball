-- 008_enforce_rls_remaining.sql
-- Add org_uid columns and RLS policies for tables missing them.

-- TEAM
ALTER TABLE team ADD COLUMN IF NOT EXISTS org_uid TEXT DEFAULT 'ORG-DEFAULT';
ALTER TABLE team ENABLE ROW LEVEL SECURITY;
ALTER TABLE team FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS team_select_org ON team;
CREATE POLICY team_select_org ON team
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- POD
ALTER TABLE pod ADD COLUMN IF NOT EXISTS org_uid TEXT DEFAULT 'ORG-DEFAULT';
ALTER TABLE pod ENABLE ROW LEVEL SECURITY;
ALTER TABLE pod FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS pod_select_org ON pod;
CREATE POLICY pod_select_org ON pod
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- SESSION
ALTER TABLE session ADD COLUMN IF NOT EXISTS org_uid TEXT DEFAULT 'ORG-DEFAULT';
ALTER TABLE session ENABLE ROW LEVEL SECURITY;
ALTER TABLE session FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS session_select_org ON session;
CREATE POLICY session_select_org ON session
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- MPB_DOCS
ALTER TABLE mpb_docs ADD COLUMN IF NOT EXISTS org_uid TEXT DEFAULT 'ORG-DEFAULT';
ALTER TABLE mpb_docs ENABLE ROW LEVEL SECURITY;
ALTER TABLE mpb_docs FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mpb_docs_select_org ON mpb_docs;
CREATE POLICY mpb_docs_select_org ON mpb_docs
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- AGENT_EVENTS
ALTER TABLE agent_events ADD COLUMN IF NOT EXISTS org_uid TEXT DEFAULT 'ORG-DEFAULT';
ALTER TABLE agent_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_events FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS agent_events_select_org ON agent_events;
CREATE POLICY agent_events_select_org ON agent_events
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- PDP
ALTER TABLE pdp ADD COLUMN IF NOT EXISTS org_uid TEXT DEFAULT 'ORG-DEFAULT';
ALTER TABLE pdp ENABLE ROW LEVEL SECURITY;
ALTER TABLE pdp FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS pdp_select_org ON pdp;
CREATE POLICY pdp_select_org ON pdp
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- PLAYER_TEAM
ALTER TABLE player_team ADD COLUMN IF NOT EXISTS org_uid TEXT DEFAULT 'ORG-DEFAULT';
ALTER TABLE player_team ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_team FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS player_team_select_org ON player_team;
CREATE POLICY player_team_select_org ON player_team
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- PLAYER_POD
ALTER TABLE player_pod ADD COLUMN IF NOT EXISTS org_uid TEXT DEFAULT 'ORG-DEFAULT';
ALTER TABLE player_pod ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_pod FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS player_pod_select_org ON player_pod;
CREATE POLICY player_pod_select_org ON player_pod
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- COACH_TEAM
ALTER TABLE coach_team ADD COLUMN IF NOT EXISTS org_uid TEXT DEFAULT 'ORG-DEFAULT';
ALTER TABLE coach_team ENABLE ROW LEVEL SECURITY;
ALTER TABLE coach_team FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS coach_team_select_org ON coach_team;
CREATE POLICY coach_team_select_org ON coach_team
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- COACH_POD
ALTER TABLE coach_pod ADD COLUMN IF NOT EXISTS org_uid TEXT DEFAULT 'ORG-DEFAULT';
ALTER TABLE coach_pod ENABLE ROW LEVEL SECURITY;
ALTER TABLE coach_pod FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS coach_pod_select_org ON coach_pod;
CREATE POLICY coach_pod_select_org ON coach_pod
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

