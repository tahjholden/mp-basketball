const { runWorkflow } = require('./helpers/n8n');
const { Client } = require('pg');
const path = require('path');

describe('Workflow inserts', () => {
  let client;

  beforeAll(async () => {
    client = global.__DB_CLIENT__;
  });

  afterEach(async () => {
    // truncate tables between tests
    await client.query('TRUNCATE TABLE actor CASCADE');
  });

  test('workflow inserts player rows when RLS allows', async () => {
    const workflow = path.join(__dirname, '..', 'workflows', 'mpos-basketball.json');
    runWorkflow(workflow);
    const { rows } = await client.query("SELECT * FROM actor WHERE actor_type = 'Player'");
    expect(rows.length).toBeGreaterThan(0);
  });

  test('insert fails without RLS', async () => {
    await expect(
      client.query("INSERT INTO actor(uid, display_name, actor_type) VALUES('X','No RLS','Player')")
    ).rejects.toThrow();
  });
});
