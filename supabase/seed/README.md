# Seed data

This directory contains SQL and CSV files used to populate a Supabase database with sample rows.

The schema organizes everyone under a unified `person` table. Specific details for a coach or player are stored in `person_role` records that point back to the person. The seed scripts insert sample people along with teams, pods and sessions so the n8n workflows have data to operate on.

## Prerequisites

- `SUPABASE_DB_URL` environment variable set to the Postgres connection string for your project.
- Supabase CLI installed and linked to the database:

```bash
supabase db remote set "$SUPABASE_DB_URL"
```

## Loading SQL seed files

Each `*.sql` file inserts rows into one of the project tables. After migrations finish you can load them with `psql`. `person_rows.sql` adds sample players and coaches using the new `person`/`person_role` layout:

```bash
for file in supabase/seed/*.sql; do
  psql "$SUPABASE_DB_URL" -f "$file"
done
```

## Loading CSV seed files

Two CSV files are included. Import them with `psql` and the `\copy` command after the tables have been created:

```bash
psql "$SUPABASE_DB_URL" -c "\copy agent_events FROM 'supabase/seed/agent_events_rows.csv' CSV HEADER"
psql "$SUPABASE_DB_URL" -c "\copy person FROM 'supabase/seed/coach_rows.csv' CSV HEADER"
```

`agent_events_rows.csv` provides initial tasks for the workflow engine and `coach_rows.csv` adds a couple of sample coaches.
