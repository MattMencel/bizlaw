import { drizzle } from 'drizzle-orm/postgres-js';
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import postgres from 'postgres';

import { initDb } from './db';
import * as schema from './schema';

async function main() {
  console.info('Starting database initialization...');

  try {
    // For migrations, we need to use postgres-js directly
    const connectionString = process.env.POSTGRES_URL_NON_POOLING || process.env.POSTGRES_URL;

    if (!connectionString) {
      throw new Error('Database connection string not found');
    }

    console.info('Setting up migration client...');

    // Create a postgres-js client specifically for migrations
    // Using non-pooled connection as recommended for migrations
    const migrationClient = postgres(connectionString);

    // Create a drizzle instance with postgres-js for migrations
    const migrationDb = drizzle(migrationClient, { schema });

    console.info('Connected to database. Running migrations...');

    // Run migrations from the drizzle folder
    await migrate(migrationDb, { migrationsFolder: './drizzle' });

    console.info('Migrations completed successfully!');

    // Also initialize the regular database connection for any seeding or verification
    await initDb();

    // Close the migration client
    await migrationClient.end();

    process.exit(0);
  }
  catch (error) {
    console.error('Database initialization failed:', error);
    process.exit(1);
  }
}

main().catch(console.error);
