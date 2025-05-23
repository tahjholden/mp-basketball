# mp-basketball

Supabase + n8n workflows for MPOS-Basketball MVP.

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed globally
- [n8n](https://n8n.io/) running locally or via Docker

## How to Use

### Apply database migrations

The migration scripts live under `./supabase/migrations`. Set `SUPABASE_DB_URL` to your Postgres connection string and link the CLI:

```bash
supabase db remote set "$SUPABASE_DB_URL"
```

Apply the migrations with:

```bash
supabase db push
```

### Load seed data

Example rows are stored in `./supabase/seed`. After the migrations run you can load the data using psql or the Supabase CLI. For example:

```bash
psql "$SUPABASE_DB_URL" -f supabase/seed/seed.sql
```

Each `*_rows.sql` file in that directory can also be executed individually.

### Import n8n workflows

All workflow exports are located in `./workflows`. Import them from the n8n UI or run:

```bash
n8n import:workflow --input workflows/mpos-basketball.json
```

## How to Extend/Clone for New Verticals

1. Fork or copy this repository under a new name.
2. Duplicate the contents of `workflows/` and adjust the flows for your domain.
3. Modify or add migrations in `supabase/migrations` and update any seed scripts under `supabase/seed`.
4. Run the migrations and seed data as shown above and re-import your modified workflows.

## Porting to PersonalOS or ConsultingOS

The same schema and workflows can be reused with other OS flavours such as PersonalOS or ConsultingOS. Point the Supabase CLI at your project for that environment, run the migrations and seed files, then import the workflows into the corresponding n8n instance. Update environment variables and credentials to match the target OS.

## Environment variables and credentials

- `SUPABASE_DB_URL` – connection string used by the Supabase CLI to run migrations.
- `SUPABASE_ACCESS_TOKEN` – required when pushing to a hosted Supabase project.
- n8n stores service credentials in its own database or `.n8n` directory. Configure them via the n8n UI after importing the workflow.
