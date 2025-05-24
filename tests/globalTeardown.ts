import { stopDB } from './db';

export default async () => {
  const client = (global as any).__DB_CLIENT__;
  if (client) {
    await client.query('DROP SCHEMA public CASCADE; CREATE SCHEMA public;');
    await client.end();
  }
  await stopDB();
};
