-- 010_create_table_metadata.sql
-- Track admin-only status for each table

CREATE TABLE IF NOT EXISTS table_metadata (
  table_name TEXT PRIMARY KEY,
  is_admin BOOLEAN NOT NULL DEFAULT FALSE
);

-- Insert existing metadata
INSERT INTO table_metadata (table_name, is_admin) VALUES
  ('actor', FALSE),
  ('profile', FALSE),
  ('observation', FALSE),
  ('intervention', FALSE),
  ('metric', FALSE),
  ('link', FALSE),
  ('tag', FALSE),
  ('routine', FALSE),
  ('routine_tag', FALSE),
  ('routine_instance', FALSE),
  ('habit_exposure', FALSE),
  ('tag_relation', FALSE),
  ('flagged_entities', TRUE),
  ('person', FALSE),
  ('observation_logs', TRUE),
  ('team', FALSE),
  ('pod', FALSE),
  ('session', FALSE),
  ('mpb_docs', FALSE),
  ('agent_events', TRUE),
  ('pdp', FALSE),
  ('player_team', FALSE),
  ('player_pod', FALSE),
  ('coach_team', FALSE),
  ('coach_pod', FALSE),
  ('mood_log', FALSE),
  ('habit', FALSE),
  ('habit_event', FALSE),
  ('goal', FALSE),
  ('project', FALSE),
  ('task', FALSE)
ON CONFLICT (table_name) DO NOTHING;

