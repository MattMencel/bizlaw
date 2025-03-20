import * as dotenv from 'dotenv';
import { drizzle } from 'drizzle-orm/postgres-js';
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import postgres from 'postgres';

import * as schema from '../src/lib/db/schema';

// Load environment variables
dotenv.config();

async function main() {
  const connectionString
    = process.env.DATABASE_URL
      || `postgres://${process.env.DB_USER || 'postgres'}:${process.env.DB_PASSWORD || 'postgres'}@${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || '5432'}/${process.env.DB_NAME || 'business_law'}`;

  console.info(
    `Connecting to database for migrations: postgres://${process.env.DB_USER || 'postgres'}:***@${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || '5432'}/${process.env.DB_NAME || 'business_law'}`,
  );

  // Create Postgres client
  const client = postgres(connectionString);

  // Create Drizzle instance
  const db = drizzle(client, { schema });

  // Run migrations
  console.info('Running migrations...');
  await migrate(db, { migrationsFolder: './drizzle' });
  console.info('Migrations complete!');

  // Close the connection
  await client.end();
  console.info('Database connection closed');
  process.exit(0);
}

main().catch((error) => {
  console.error('Migration failed:', error);
  process.exit(1);
});
