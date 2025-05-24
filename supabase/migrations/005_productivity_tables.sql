-- 005_productivity_tables.sql
-- Productivity tracking tables for mood, habits, goals, projects and tasks

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
CREATE INDEX IF NOT EXISTS idx_mood_log_person ON mood_log(person_id);
CREATE INDEX IF NOT EXISTS idx_mood_log_timestamp ON mood_log(timestamp);

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
CREATE INDEX IF NOT EXISTS idx_habit_person ON habit(person_id);

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
CREATE INDEX IF NOT EXISTS idx_habit_event_habit ON habit_event(habit_id);
CREATE INDEX IF NOT EXISTS idx_habit_event_timestamp ON habit_event(timestamp);

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
CREATE INDEX IF NOT EXISTS idx_goal_person ON goal(person_id);

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
CREATE INDEX IF NOT EXISTS idx_project_owner ON project(owner_id);

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
CREATE INDEX IF NOT EXISTS idx_task_project ON task(project_id);
CREATE INDEX IF NOT EXISTS idx_task_assignee ON task(assignee_id);
