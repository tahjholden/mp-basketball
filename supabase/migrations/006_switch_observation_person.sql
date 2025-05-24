-- 006_switch_observation_person.sql
-- Migrate observation table from actor_uid to person_id

DO $$
BEGIN
  -- If the old column exists, migrate data
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_name = 'observation'
       AND column_name = 'actor_uid'
  ) THEN
    -- Ensure person_id column exists
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
       WHERE table_name = 'observation'
         AND column_name = 'person_id'
    ) THEN
      ALTER TABLE observation ADD COLUMN person_id TEXT;
    END IF;

    -- Copy data from actor_uid if needed
    UPDATE observation
       SET person_id = COALESCE(person_id, actor_uid);

    ALTER TABLE observation DROP COLUMN actor_uid;

    -- Update function to use person_id
    CREATE OR REPLACE FUNCTION update_pdp(obs_uid TEXT) RETURNS VOID LANGUAGE plpgsql AS $$
    DECLARE
      v_person_id TEXT;
    BEGIN
      SELECT person_id INTO v_person_id FROM observation WHERE uid = obs_uid;
      UPDATE profile
         SET attributes_json = jsonb_set(attributes_json, '{last_observation}', to_jsonb(obs_uid), true)
       WHERE actor_uid = v_person_id;
    END;
    $$;
  END IF;
END $$;
