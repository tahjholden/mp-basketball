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


## Parametrizing a workflow

Use `scripts/parametrize_workflow.js` to swap Supabase details in an exported n8n workflow.

```bash
node scripts/parametrize_workflow.js --workflow workflows/mpos-basketball.json --config my-config.json --output import.json
```

`my-config.json` example:

```json
{
  "supabaseUrl": "https://your-project.supabase.co",
  "supabaseCredentialId": "xyz123"
}
```

You can also set the values through environment variables `SUPABASE_URL` and `SUPABASE_CREDENTIAL_ID`.

