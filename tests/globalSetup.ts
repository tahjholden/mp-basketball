import { Client } from 'pg';
import { startDB } from './db';

export default async () => {
  const dbUrl = await startDB();
  process.env.SUPABASE_DB_URL = dbUrl;

  const client = new Client({ connectionString: dbUrl });
  await client.connect();

  (global as any).__DB_CLIENT__ = client;
};
