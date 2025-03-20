import { migrate } from 'drizzle-orm/postgres-js/migrator';

import { getDb } from './db';

async function main() {
  console.info('Starting database initialization...');

  try {
    const db = getDb();
    console.info('Connected to database. Running migrations...');

    // Run migrations from the drizzle folder
    await migrate(db, { migrationsFolder: './drizzle' });

    console.info('Migrations completed successfully!');

    process.exit(0);
  }
  catch (error) {
    console.error('Database initialization failed:', error);
    process.exit(1);
  }
}

main().catch(console.error);
