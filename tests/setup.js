const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

module.exports = async () => {
  const dbUrl = process.env.SUPABASE_DB_URL;
  if (!dbUrl) {
    throw new Error('SUPABASE_DB_URL env var not set');
  }
  const client = new Client({ connectionString: dbUrl });
  await client.connect();

  const migrationsDir = path.join(__dirname, '..', 'supabase', 'migrations');
  const files = fs
    .readdirSync(migrationsDir)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  for (const file of files) {
    const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
    await client.query(sql);
  }

  global.__DB_CLIENT__ = client;
};
