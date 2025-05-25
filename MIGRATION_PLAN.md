# Migration Plan

This document summarizes the repository restructuring and outlines the steps required to upgrade existing MP-Basketball installations. It lists which files were moved, which legacy assets are now deprecated, and manual actions needed when applying the updated schema and workflows to a Supabase project.

## File Moves

- **Workflow JSON files** were relocated to the new `workflows/` directory. The files `MPB__File_Chat_Agent.json`, `MPB__PDP_Agent*.json`, `MPB__PracticePlanner_Agent.json` and similar variants are now represented by:
  - `workflows/file-chat-agent.json`
  - `workflows/pdp-agent.json`
  - `workflows/practice-planner-agent.json`
  - `workflows/session-plan-generator.json`
  These old `MPB__*.json` files remain in the root folder but should be considered **deprecated**.
- **Supabase seed scripts** moved under `supabase/seed/`. The previous top‑level files such as `coach_rows.sql` and `player_rows.sql` now live in this folder along with a new `README.md` describing how to load them.
- **SQL migrations** are organised under `supabase/migrations/` and have been renumbered sequentially (`001_init.sql`, `002_add_missing_tables.sql`, …). Any earlier copies outside this folder are obsolete.
- Custom n8n node packages reside in `packages/` and the deployment helper script is in `deploy-agent/`.
- The standalone `mpb_schema_test_seed.sql` file is no longer used and can be removed after migrating to the seed directory.

## Deprecated Files

- Legacy workflow files prefixed with `MPB__` or `POS__` in the repository root.
- The original seed file `mpb_schema_test_seed.sql`.
- Any migration scripts outside of `supabase/migrations/`.

These files remain for historical reference but should not be modified going forward.

## Manual Steps

1. Install the Supabase CLI and n8n CLI if not already present.
2. Link the Supabase CLI to your project:
   ```bash
   supabase db remote set "$SUPABASE_DB_URL"
   ```
3. Apply the new migrations:
   ```bash
   supabase db push
   ```
4. Load seed data from `supabase/seed/` using `psql` once the schema is in place.
5. Import the workflows from the `workflows/` folder into n8n:
   ```bash
   n8n import:workflow --input workflows/<file>.json
   ```
6. Update any credentials or environment variables referenced in the workflows.
7. Review `admin_tables.yml` and ensure new tables are listed with the correct `is_admin` value. Migration `011_create_table_metadata.sql` syncs this data into the database.
8. If cloning the project for a new vertical, run `tools/vertical_mapper/vertical_mapper.py` with the appropriate mapping file to generate domain‑specific migrations and workflows.

## Database Upgrade Notes

The schema transitioned from the older `actor` design to a unified `person` table with related `person_role` records. Migrations also rename `player_exposure` to `person_exposure` and add new tables such as `attendance` and `table_metadata`.

When upgrading an existing Supabase project:

1. Run all migrations in order with the Supabase CLI. The renumbered files handle table renames and data migration automatically.
2. After `011_create_table_metadata.sql`, verify that the `table_metadata` table contains entries for every table listed in `supabase/admin_tables.yml`.
3. Reload seed data from `supabase/seed/` to match the new structure. Older seed files targeting `player` or `coach` tables will no longer apply.
4. Import the updated workflows so they reference the `person` and `attendance` tables.

Following these steps ensures the database schema and automation flows stay consistent with the latest repository layout.
