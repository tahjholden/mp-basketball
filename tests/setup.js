const { Client } = require('pg');
const { startDB } = require('./db');

module.exports = async () => {
  const dbUrl = await startDB();
  process.env.SUPABASE_DB_URL = dbUrl;

  const client = new Client({ connectionString: dbUrl });
  await client.connect();

  global.__DB_CLIENT__ = client;
};
