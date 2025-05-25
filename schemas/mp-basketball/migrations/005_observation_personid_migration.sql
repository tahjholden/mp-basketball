-- 005_observation_personid_migration.sql
-- Convert existing observation.actor_uid column to person_id

DO $$
BEGIN
  -- add person_id column if needed
  IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_name='observation' AND column_name='person_id') THEN
    ALTER TABLE observation ADD COLUMN person_id TEXT;
  END IF;

  -- copy data from actor_uid if that column exists
  IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_name='observation' AND column_name='actor_uid') THEN
    UPDATE observation SET person_id = actor_uid WHERE person_id IS NULL;
    ALTER TABLE observation DROP COLUMN actor_uid;
  END IF;

  -- ensure foreign key and not-null constraint
  BEGIN
    ALTER TABLE observation
      ADD CONSTRAINT observation_person_id_fkey FOREIGN KEY (person_id) REFERENCES actor(uid);
  EXCEPTION WHEN duplicate_object THEN
    -- constraint already exists
    NULL;
  END;
  ALTER TABLE observation ALTER COLUMN person_id SET NOT NULL;
END$$;
