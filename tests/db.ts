import { execSync } from 'child_process';
import { Client } from 'pg';
import { promises as fs } from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';

let containerName: string;
let databaseUrl: string;

async function waitForDb(url: string) {
  for (let i = 0; i < 10; i++) {
    try {
      const c = new Client({ connectionString: url });
      await c.connect();
      await c.end();
      return;
    } catch (err) {
      await new Promise((res) => setTimeout(res, 1000));
    }
  }
  throw new Error('Postgres container did not start');
}

export async function startDB(): Promise<string> {
  containerName = `mpb_test_${uuidv4()}`;
  databaseUrl = 'postgres://postgres:postgres@localhost:54329/postgres';

  execSync(`docker run -d --rm --name ${containerName} -e POSTGRES_PASSWORD=postgres -p 54329:5432 postgres:15-alpine`, { stdio: 'ignore' });

  await waitForDb(databaseUrl);

  const client = new Client({ connectionString: databaseUrl });
  await client.connect();

  const migrationsDir = path.join(__dirname, '..', 'supabase', 'migrations');
  const files = (await fs.readdir(migrationsDir))
    .filter((f) => f.endsWith('.sql'))
    .sort();
  for (const file of files) {
    const sql = await fs.readFile(path.join(migrationsDir, file), 'utf8');
    await client.query(sql);
  }

  await client.end();
  return databaseUrl;
}

export async function stopDB() {
  if (containerName) {
    try {
      execSync(`docker stop ${containerName}`, { stdio: 'ignore' });
    } catch (err) {
      // ignore
    }
  }
}
