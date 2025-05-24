-- 008_create_attendance.sql
-- Create attendance table to track player presence per session

CREATE TABLE IF NOT EXISTS attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id TEXT REFERENCES session(id),
  player_id TEXT REFERENCES person(uid),
  status TEXT CHECK (status IN ('present','absent','late')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_attendance_session ON attendance(session_id);
CREATE INDEX IF NOT EXISTS idx_attendance_player ON attendance(player_id);

ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS attendance_select_all ON attendance;
CREATE POLICY attendance_select_all ON attendance
  FOR SELECT USING (true);
