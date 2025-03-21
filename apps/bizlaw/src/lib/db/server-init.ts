import { drizzle } from 'drizzle-orm/postgres-js';
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import postgres from 'postgres';

import * as schema from './schema';

let migrationRan = false;

/**
 * Run database migrations if they haven't been run already
 * This function is designed to be called on app initialization
 */
export async function runMigrations() {
  // Only run migrations once per server instance
  if (migrationRan) {
    return;
  }

  console.info('Checking if migrations need to be run...');

  // Only run migrations if AUTO_MIGRATE is enabled
  if (process.env.AUTO_MIGRATE !== 'true') {
    console.info('Auto-migrations disabled. Set AUTO_MIGRATE=true to enable.');
    return;
  }

  try {
    const connectionString = process.env.POSTGRES_URL_NON_POOLING || process.env.POSTGRES_URL;

    if (!connectionString) {
      throw new Error('Database connection string not found');
    }

    console.info('Running database migrations...');

    // Use non-pooled connection for migrations
    const migrationClient = postgres(connectionString, {
      ssl: process.env.NODE_ENV === 'development' ? { rejectUnauthorized: false } : true,
    });

    const migrationDb = drizzle(migrationClient, { schema });

    // Run migrations (adjust the migrations folder path if needed)
    await migrate(migrationDb, { migrationsFolder: './drizzle' });

    console.info('Database migrations completed successfully!');
    migrationRan = true;

    // Close the migration client when done
    await migrationClient.end();
  }
  catch (error) {
    console.error('Failed to run migrations:', error);
    // Don't throw here - we want the app to continue even if migrations fail
  }
}
