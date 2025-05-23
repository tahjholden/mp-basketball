-- 004_person_refactor.sql
-- Rename actor table to person and update related structures

ALTER TABLE actor RENAME TO person;
ALTER TABLE person RENAME COLUMN actor_type TO role_type;

ALTER TABLE profile RENAME COLUMN actor_uid TO person_uid;
ALTER TABLE observation RENAME COLUMN actor_uid TO person_uid;
ALTER TABLE metric RENAME COLUMN actor_uid TO person_uid;
ALTER TABLE player_exposure RENAME COLUMN player_uid TO person_uid;

ALTER TABLE person DROP CONSTRAINT IF EXISTS actor_actor_type_check;
ALTER TABLE person ADD CONSTRAINT person_role_type_check CHECK (role_type IN ('User','FamilyMember','Mentor','Group'));

-- migrate subtype data into person_role and drop old tables
CREATE TABLE IF NOT EXISTS person_role (
  uid         TEXT PRIMARY KEY,
  person_uid  TEXT NOT NULL REFERENCES person(uid) ON DELETE CASCADE,
  role        TEXT NOT NULL,
  attributes  JSONB DEFAULT '{}'
);

INSERT INTO person_role(uid, person_uid, role, attributes)
SELECT uuid_generate_v4()::text, uid, 'Player', jsonb_build_object('jersey_num', jersey_num, 'position', position)
FROM player;

INSERT INTO person_role(uid, person_uid, role, attributes)
SELECT uuid_generate_v4()::text, uid, 'Coach', jsonb_build_object('role', role)
FROM coach;

DROP TABLE IF EXISTS player;
DROP TABLE IF EXISTS coach;

CREATE OR REPLACE FUNCTION update_pdp(obs_uid TEXT) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
  v_person_uid TEXT;
BEGIN
  SELECT person_uid INTO v_person_uid FROM observation WHERE uid = obs_uid;
  UPDATE profile
     SET attributes_json = jsonb_set(attributes_json, '{last_observation}', to_jsonb(obs_uid), true)
   WHERE person_uid = v_person_uid;
END;
$$;

CREATE OR REPLACE FUNCTION expand_exposure() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
      SELECT dt.tag_uid, pr.person_uid
        FROM drill_tag dt
        CROSS JOIN person_role pr
        WHERE dt.drill_uid = NEW.drill_uid
          AND pr.role = 'Player'
  LOOP
    INSERT INTO player_exposure(uid, session_drill_uid, person_uid, tag_uid, count)
    VALUES (
      uuid_generate_v4()::text,
      NEW.uid,
      rec.person_uid,
      rec.tag_uid,
      1
    )
    ON CONFLICT (session_drill_uid, person_uid, tag_uid) DO UPDATE
    SET count = player_exposure.count + 1;
  END LOOP;
  RETURN NEW;
END;
$$;

ALTER TABLE person ENABLE ROW LEVEL SECURITY;
ALTER TABLE person FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS actor_select_org ON person;
CREATE POLICY person_select_org ON person
  FOR SELECT USING (org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid');
