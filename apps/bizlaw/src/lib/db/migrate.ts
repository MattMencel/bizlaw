import * as path from 'path';

import { drizzle } from 'drizzle-orm/postgres-js';
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import postgres from 'postgres';

export default async function runMigrations() {
  // Create a separate connection for migrations
  const connectionString
    = process.env.DATABASE_URL
      || `postgres://${process.env.DB_USER || 'postgres'}:${process.env.DB_PASSWORD || 'postgres'}@${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || '5432'}/${process.env.DB_NAME || 'business_law'}`;

  const sql = postgres(connectionString, {
    max: 1,
    ssl:
      process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
  });

  const db = drizzle(sql);

  // Path to migrations folder (relative to project root)
  const migrationsFolder = path.join(process.cwd(), 'drizzle');

  try {
    await migrate(db, { migrationsFolder });
    console.info('Migrations completed successfully');
  }
  catch (error) {
    console.error('Migration failed:', error);
    throw error;
  }
  finally {
    await sql.end();
  }
}
