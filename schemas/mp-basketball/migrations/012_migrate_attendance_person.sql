-- 012_migrate_attendance_person.sql
-- Migrate attendance table to use person_uid reference

DO $$
BEGIN
  -- Add person_uid column if it doesn't exist
  IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_name='attendance' AND column_name='person_uid') THEN
    ALTER TABLE attendance ADD COLUMN person_uid TEXT;
  END IF;

  -- Copy data from old player_id column if present
  IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_name='attendance' AND column_name='player_id') THEN
    UPDATE attendance SET person_uid = COALESCE(person_uid, player_id);
    ALTER TABLE attendance DROP COLUMN player_id;
  END IF;

  -- Add foreign key constraint
  BEGIN
    ALTER TABLE attendance ADD CONSTRAINT attendance_person_uid_fkey
      FOREIGN KEY (person_uid) REFERENCES person(uid);
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  ALTER TABLE attendance ALTER COLUMN person_uid SET NOT NULL;
END $$;

-- Replace old index if needed
DROP INDEX IF EXISTS idx_attendance_player;
CREATE INDEX IF NOT EXISTS idx_attendance_person ON attendance(person_uid);
