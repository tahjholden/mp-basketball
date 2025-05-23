# Supabase

This directory stores SQL files used with the Supabase CLI.

- **migrations/** – schema migrations applied in sequence to build the database.
- **seed/** – SQL scripts that populate tables with example data.

## Running migrations

1. Set `SUPABASE_DB_URL` to your Postgres connection string.
2. Link the CLI:

```bash
supabase db remote set "$SUPABASE_DB_URL"
```

3. Apply migrations:

```bash
supabase db push
```

## Seeding the database

After the schema is in place, execute the SQL files from the `seed` folder:

```bash
psql "$SUPABASE_DB_URL" -f seed/<file>.sql
```

