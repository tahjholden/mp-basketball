# mp-basketball

Supabase + n8n workflows for MPOS-Basketball MVP.
For an overview of the Human OS architecture guiding all verticals, see [Human_OS_Architecture.md](Human_OS_Architecture.md).

### Actor to person refactor

Older revisions of the schema used an `actor` table to store players and coaches. The current design consolidates everyone in a `person` table with related roles stored in `person_role` rows.

### Person table

All participants live in a single `person` table. Player and coach details, such
as jersey numbers or positions, are stored in the related `person_role` table.

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed globally
- [n8n](https://n8n.io/) running locally or via Docker
- [PyYAML](https://pyyaml.org/) for running the mapping utility

## How to Use

### Apply database migrations


Link the Supabase CLI to your database then apply the migrations. This pulls in
`010_create_attendance.sql`, which creates the `attendance` table used by the
practice planner:

```bash
supabase db remote set "$SUPABASE_DB_URL"
supabase db push
```

### Load seed data

Example rows are stored in `./supabase/seed`. After running `supabase db push` you can load all SQL files in that folder. `person_rows.sql` seeds players and coaches and other files populate related tables:

```bash
for f in supabase/seed/*.sql; do
  psql "$SUPABASE_DB_URL" -f "$f"
done
```

To import the CSV files as well:

```bash
psql "$SUPABASE_DB_URL" -c "\copy agent_events FROM 'supabase/seed/agent_events_rows.csv' CSV HEADER"
psql "$SUPABASE_DB_URL" -c "\copy person FROM 'supabase/seed/coach_rows.csv' CSV HEADER"
```

This loads the sample rows for the new `person`/`person_role` structure and related tables.

### Import n8n workflows

All workflow exports are located in `./workflows`. Import them from the n8n UI or run:

```bash
n8n import:workflow --input workflows/mpos-basketball.json
```

The practice-planner workflows now read from the `attendance` table. Only players
marked `present` are included when generating a session plan. Any names that do
not match existing players are logged in the `flagged_entities` table for later
review.

Example code nodes used in the workflow:

```javascript
// FetchAttendance (Supabase node)
const { data } = await supabase
  .from('attendance')
  .select('*')
  .eq('session_uid', $json.session_id)

// FilterPresentPlayers (Code node)
const present = data.filter(row => row.status === 'present')
return present.map(r => ({ json: { person_uid: r.person_uid } }))
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


<!-- add script to parametrize workflow -->
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



## Checking for schema drift

Use `tools/schema_diff.py` to compare the SQL migrations with a live database.
Provide the Postgres connection string via `--db-url` and optionally generate an
HTML report:

```bash
python tools/schema_diff.py \
  --db-url postgres://user:pass@host:5432/dbname \
  --html diff.html
```

<!-- set up jest with package.json -->
## Install dependencies

Run `npm install` to install the dev dependencies for running tests. This fetches Jest and `ts-jest` along with the other required packages.
Packages that include custom n8n nodes (under `packages/`) also require `npm install` from inside each package directory before executing tests.

Run tests with `npm test` and generate coverage reports using `npm run coverage`.
The workflow integration test at `tests/workflowLoad.test.ts` can be executed on
its own with:

```bash
npm test tests/workflowLoad.test.ts
```

## Testing

The main Jest tests live in the top-level `tests` directory. Some packages under
`packages/` contain their own `__tests__` folders for vertical-specific logic.

Run the test suite locally with:

```bash
npm install
npm test
npm run coverage
```

GitHub Actions runs these commands on every pull request and reports the CI
status directly on the PR page.

## License


## Testing

This repository includes Jest tests that run the Supabase migrations and execute n8n workflows.
The helper in `tests/db.ts` launches a temporary Postgres container via Docker and applies all
migrations automatically. Ensure Docker, the Supabase CLI and the `n8n` CLI are installed locally
before running:

```bash
npm test
```

Tables are truncated between runs.
