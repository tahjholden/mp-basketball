# mp-basketball

Supabase + n8n workflows for MPOS-Basketball MVP.

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed globally
- [n8n](https://n8n.io/) running locally or via Docker

## Applying the database schema

1. Set the `SUPABASE_DB_URL` environment variable with the Postgres connection string for your project.
2. Link the CLI to the database:

   ```bash
   supabase db remote set "$SUPABASE_DB_URL"
   ```
3. Push the migrations contained in `supabase/001_init.sql`:

   ```bash
   supabase db push
   ```

## Importing the n8n workflow

1. Start your n8n instance.
2. In the editor UI choose **Import from File** and select `workflows/mpos-basketball.json` from this repository.
   You can also run:

   ```bash
   n8n import:workflow --input workflows/mpos-basketball.json
   ```

## Environment variables and credentials

- `SUPABASE_DB_URL` – connection string used by the Supabase CLI to run migrations.
- `SUPABASE_ACCESS_TOKEN` – required when pushing to a hosted Supabase project.
- n8n stores service credentials in its own database or `.n8n` directory. Configure them via the n8n UI after importing the workflow.

## Vertical mapper

The `tools/vertical_mapper` utility can rewrite the canonical SQL migrations
and workflow JSON files for a different domain. Provide a YAML mapping with
table, field and value replacements and specify an output directory:

```bash
python tools/vertical_mapper/vertical_mapper.py \
  --mapping tools/vertical_mapper/mapping_consulting.yml \
  --sql-dir supabase/migrations \
  --workflow-dir workflows \
  --dist-dir dist/consulting
```

