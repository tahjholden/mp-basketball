# Seed data

This directory contains SQL and CSV files used to populate a Supabase database with sample rows.

The schema groups every participant in an `actor` table. Extra attributes for players and coaches are stored in `person` rows that reference the actor id. Many of the seed scripts insert data into these two tables along with related team and session tables.

## Prerequisites

- `SUPABASE_DB_URL` environment variable set to the Postgres connection string for your project.
- Supabase CLI installed and linked to the database:

```bash
supabase db remote set "$SUPABASE_DB_URL"
```

## Loading SQL seed files

Each `*.sql` file inserts rows into one of the project tables. After migrations finish you can load them with `psql`:

```bash
for file in supabase/seed/*.sql; do
  psql "$SUPABASE_DB_URL" -f "$file"
done
```
<!-- update readme files for actor/person structure -->

## Loading CSV seed files

Two CSV files are included. Import them with `psql` and the `\copy` command after the tables have been created:

```bash
psql "$SUPABASE_DB_URL" -c "\copy agent_events FROM 'supabase/seed/agent_events_rows.csv' CSV HEADER"
psql "$SUPABASE_DB_URL" -c "\copy person FROM 'supabase/seed/coach_rows.csv' CSV HEADER"
```

This will insert the rows defined in each CSV file into the corresponding table.
