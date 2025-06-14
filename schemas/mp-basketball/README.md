# MP-Basketball Schema

This directory stores the MP-Basketball SQL migrations and seed files used with the Supabase CLI.

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


<!-- create table metadata configuration -->
## Admin table metadata

The file `admin_tables.yml` lists every table created by the migrations and whether it should be restricted to administrators. The keys are table names and the values are booleans. Whenever you add a migration that creates a new table, update `admin_tables.yml` with an entry for that table.

```yaml
actor: false
# ...
```

Keeping this file in sync with the migrations allows external tools or policies to automatically determine which tables require admin-level access.

## `table_metadata` table

Migration `011_create_table_metadata.sql` adds a table named `table_metadata` with columns `table_name` and `is_admin`. The initial migration populates it using the entries from `admin_tables.yml` so both sources stay aligned.

Whenever you create a new table, update both places:

1. Add the table to `admin_tables.yml`.
2. Insert a row into `table_metadata` in a new migration.

Keeping the file and table synchronized ensures tools can query this metadata reliably.
