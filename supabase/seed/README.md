# Seed data

This directory contains SQL and CSV files used to populate a Supabase database with sample rows.

## Prerequisites

- `SUPABASE_DB_URL` environment variable set to the Postgres connection string for your project.
- Supabase CLI installed and linked to the database:

```bash
supabase db remote set "$SUPABASE_DB_URL"
```

## Loading SQL seed files

Each `*.sql` file inserts rows into one of the project tables. Execute them in any order using the Supabase CLI:

```bash
for file in supabase/seed/*.sql; do
  supabase db execute < "$file"
done
```

You can also run a single file:

```bash
supabase db execute < supabase/seed/player_rows.sql
```

## Loading CSV seed files

Two CSV files are included. Import them with `psql` and the `\copy` command after the tables have been created:

```bash
psql "$SUPABASE_DB_URL" -c "\copy agent_events FROM 'supabase/seed/agent_events_rows.csv' CSV HEADER"
psql "$SUPABASE_DB_URL" -c "\copy coach FROM 'supabase/seed/coach_rows.csv' CSV HEADER"
```

This will insert the rows defined in each CSV file into the corresponding table.
