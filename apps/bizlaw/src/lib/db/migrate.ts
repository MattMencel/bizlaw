import * as path from 'path';

import { drizzle } from 'drizzle-orm/postgres-js';
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import postgres from 'postgres';

async function runMigrations() {
  console.log('Running database migrations...');

  try {
    // Use the Vercel PostgreSQL URL
    const connectionString = process.env.POSTGRES_URL_NON_POOLING;

    if (!connectionString) {
      throw new Error('PostgreSQL connection string not found');
    }

    // Connect to the database - use non-pooling for migrations
    const client = postgres(connectionString);
    const db = drizzle(client);

    // Run migrations from the specified directory
    await migrate(db, { migrationsFolder: 'drizzle/migrations' });

    console.log('Migrations completed successfully!');
    process.exit(0);
  }
  catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

runMigrations();
