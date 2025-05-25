-- 013_person_team_pod.sql
-- Introduce unified join tables person_team and person_pod

-- create tables if they don't exist
CREATE TABLE IF NOT EXISTS person_team (
  person_uid TEXT NOT NULL REFERENCES person(uid) ON DELETE CASCADE,
  team_id    TEXT NOT NULL REFERENCES team(id),
  PRIMARY KEY (person_uid, team_id)
);

CREATE TABLE IF NOT EXISTS person_pod (
  person_uid TEXT NOT NULL REFERENCES person(uid) ON DELETE CASCADE,
  pod_id     TEXT NOT NULL REFERENCES pod(id),
  PRIMARY KEY (person_uid, pod_id)
);

-- migrate data from legacy tables when present
INSERT INTO person_team(person_uid, team_id)
SELECT player_id, team_id FROM player_team
ON CONFLICT DO NOTHING;

INSERT INTO person_team(person_uid, team_id)
SELECT coach_id, team_id FROM coach_team
ON CONFLICT DO NOTHING;

INSERT INTO person_pod(person_uid, pod_id)
SELECT player_id, pod_id FROM player_pod
ON CONFLICT DO NOTHING;

INSERT INTO person_pod(person_uid, pod_id)
SELECT coach_id, pod_id FROM coach_pod
ON CONFLICT DO NOTHING;

DROP TABLE IF EXISTS player_team;
DROP TABLE IF EXISTS coach_team;
DROP TABLE IF EXISTS player_pod;
DROP TABLE IF EXISTS coach_pod;

-- ensure indexes
CREATE INDEX IF NOT EXISTS idx_person_team_person ON person_team(person_uid);
CREATE INDEX IF NOT EXISTS idx_person_team_team ON person_team(team_id);
CREATE INDEX IF NOT EXISTS idx_person_pod_person ON person_pod(person_uid);
CREATE INDEX IF NOT EXISTS idx_person_pod_pod ON person_pod(pod_id);

-- add org_uid and RLS if not already added
ALTER TABLE person_team ADD COLUMN IF NOT EXISTS org_uid TEXT DEFAULT 'ORG-DEFAULT';
ALTER TABLE person_team ENABLE ROW LEVEL SECURITY;
ALTER TABLE person_team FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS person_team_select_org ON person_team;
CREATE POLICY person_team_select_org ON person_team
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

ALTER TABLE person_pod ADD COLUMN IF NOT EXISTS org_uid TEXT DEFAULT 'ORG-DEFAULT';
ALTER TABLE person_pod ENABLE ROW LEVEL SECURITY;
ALTER TABLE person_pod FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS person_pod_select_org ON person_pod;
CREATE POLICY person_pod_select_org ON person_pod
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');

-- update table metadata
DELETE FROM table_metadata WHERE table_name IN ('player_team','coach_team','player_pod','coach_pod');
INSERT INTO table_metadata (table_name, is_admin) VALUES
  ('person_team', FALSE),
  ('person_pod', FALSE)
ON CONFLICT (table_name) DO NOTHING;

-- update expand_exposure function to use new table
CREATE OR REPLACE FUNCTION expand_exposure() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
      SELECT dt.tag_uid, pr.person_uid
        FROM drill_tag dt
        JOIN session s ON s.id = NEW.intervention_uid
        JOIN person_team pt ON pt.team_id = s.team_id
        JOIN person_role pr ON pr.person_uid = pt.person_uid
       WHERE dt.drill_uid = NEW.drill_uid
         AND pr.role = 'Player'
  LOOP
    INSERT INTO person_exposure(uid, session_drill_uid, person_uid, tag_uid, count)
    VALUES (
      uuid_generate_v4(),
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
