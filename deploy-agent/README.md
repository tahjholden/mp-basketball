# Deploy Agent

This directory contains a simple script to push database migrations and import n8n workflows.

## Usage

```bash
python deploy_agent.py \
  --db-url postgres://user:pass@host:5432/dbname \
  --sql schemas/mp-basketball/migrations/001_init.sql \
  --workflow workflows/mpos-basketball.json
```

Set `--supabase-token` if pushing to a hosted Supabase project. Logs are written to `deploy.log` by default.

## Next steps

- Verify that the Supabase CLI and n8n CLI are installed and accessible in your PATH.
- Review the log file for success or failure details after running the script.
- Configure credentials for any imported n8n workflows using the n8n UI.
