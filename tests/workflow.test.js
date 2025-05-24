const { runWorkflow } = require('./helpers/n8n');
const { Client } = require('pg');
const path = require('path');

/**
 * These tests execute a small n8n workflow that inserts a row into the
 * `person` and `profile` tables.  The workflow itself lives under
 * `tests/workflows/insert_person.json` and uses a Function node to run
 * `pg` queries.  Row level security (RLS) policies are created here so
 * inserts only succeed when the `request.jwt.claims` session variable
 * matches the `org_uid` of the row being inserted.
 */

describe('Workflow inserts', () => {
  let client;

  beforeAll(async () => {
    client = global.__DB_CLIENT__;

    // create simple insert policies used for these tests
    await client.query(`
      DROP POLICY IF EXISTS person_insert_org ON person;
      CREATE POLICY person_insert_org ON person
        FOR INSERT WITH CHECK (
          org_uid = current_setting('request.jwt.claims', true)::jsonb->>'org_uid'
        );

      DROP POLICY IF EXISTS profile_insert_org ON profile;
      CREATE POLICY profile_insert_org ON profile
        FOR INSERT WITH CHECK (true);
    `);
  });

  afterEach(async () => {
    // reset table state between tests
    await client.query('TRUNCATE TABLE profile CASCADE');
    await client.query('TRUNCATE TABLE person CASCADE');
    await client.query('RESET "request.jwt.claims"');
  });

  afterAll(async () => {
    // remove policies created in beforeAll
    await client.query('DROP POLICY IF EXISTS person_insert_org ON person');
    await client.query('DROP POLICY IF EXISTS profile_insert_org ON profile');
  });

  test('workflow inserts rows when RLS allows', async () => {
    const workflow = path.join(__dirname, 'workflows', 'insert_person.json');
    runWorkflow(workflow, { SUPABASE_DB_URL: process.env.SUPABASE_DB_URL });

    const { rows } = await client.query(
      "SELECT display_name, role_type FROM person WHERE display_name = 'Workflow User'"
    );
    expect(rows).toHaveLength(1);
    expect(rows[0]).toEqual({ display_name: 'Workflow User', role_type: 'User' });

    const { rows: profileRows } = await client.query(
      'SELECT person_uid FROM profile WHERE person_uid = (SELECT uid FROM person WHERE display_name = $1)',
      ['Workflow User']
    );
    expect(profileRows).toHaveLength(1);
  });

  test('insert fails without matching RLS claim', async () => {
    await client.query(
      "SET session \"request.jwt.claims\" = '{\"org_uid\":\"OTHER\"}'"
    );
    await expect(
      client.query("INSERT INTO person(display_name, role_type) VALUES('Blocked','User')")
    ).rejects.toThrow();
  });
});
