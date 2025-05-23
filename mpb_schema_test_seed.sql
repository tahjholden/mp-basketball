-- Players
INSERT INTO player (id, display_name) VALUES
('efac77a8-2608-42eb-a5eb-f32916a38b76', 'Jordan Reyes'),
('92b5e129-e87f-402d-a70d-8c1183f40df1', 'Taylor Kim'),
('f546886e-e48a-4695-ae8e-6b59d29eb042', 'Morgan Blake');

-- Coaches
INSERT INTO coach (id, display_name, email) VALUES
('c773c915-fecb-40a2-9ae8-44d7f4a0b0de', 'Coach G', 'coachg@example.com'),
('972f4d9d-050b-486b-8251-b5309ee8dfca', 'Coach L', 'coachl@example.com');

-- Tags
INSERT INTO tag (id, tag_name, tag_type) VALUES
('0825f9c0-c3be-4b71-92df-270bddc82b39', 'Spacing', 'skill'),
('ea187f66-e872-4e20-b986-96584696c370', 'Closeout Discipline', 'constraint'),
('eb3615c0-b5b1-4e35-9aaf-21b3238e7266', 'Fight For Your Feet', 'constraint');

-- Raw Observations
INSERT INTO observation_intake (id, raw_note, coach_id, processed, created_at) VALUES
('ccdadee3-2ffe-474d-94f4-3204984e7e4c', 'Great spacing by Jordan but Taylor kept drifting too early.', 'c773c915-fecb-40a2-9ae8-44d7f4a0b0de', false, '2025-05-20T15:04:10.481273'),
('9e12bf6f-0780-47ef-9170-283ae9b55d44', 'Morgan was late. We worked on closeout footwork and landing positions.', '972f4d9d-050b-486b-8251-b5309ee8dfca', false, '2025-05-20T15:04:10.481273'),
('e16f61ad-72b2-4972-b0af-e0c39c467dc5', 'Didn’t see much player-to-player talk. Possibly low engagement. Tag this.', 'c773c915-fecb-40a2-9ae8-44d7f4a0b0de', false, '2025-05-20T15:04:10.481273');

-- Tag Suggestions
INSERT INTO tag_suggestions (id, suggested_tag, source_entry_id, source_table, proposed_type, created_at) VALUES
('83576941-9eef-4abe-999c-32a8d86cd326', 'Low Engagement', 'e16f61ad-72b2-4972-b0af-e0c39c467dc5', 'observation_intake', 'theme', '2025-05-20T15:04:10.481273');