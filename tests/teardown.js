module.exports = async () => {
  const client = global.__DB_CLIENT__;
  if (client) {
    await client.query('DROP SCHEMA public CASCADE; CREATE SCHEMA public;');
    await client.end();
  }
};
