import * as dotenv from 'dotenv';
import postgres from 'postgres';
import { sql } from 'drizzle-orm';

// Load environment variables
dotenv.config();

async function resetMigrations() {
  try {
    console.log('Resetting migration state...');

    // Get connection string
    const connectionString = process.env.POSTGRES_URL_NON_POOLING || process.env.POSTGRES_URL;

    if (!connectionString) {
      throw new Error('Database connection string not found');
    }

    // Create client with proper SSL configuration
    const client = postgres(connectionString, {
      ssl:
        process.env.NODE_ENV === 'development' || process.env.POSTGRES_REJECT_UNAUTHORIZED === 'false'
          ? { rejectUnauthorized: false }
          : true,
    });

    // 1. Check if the migrations table exists
    const tableExists = await client`
      SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = '__drizzle_migrations'
      );
    `;

    // 2. Drop the table if it exists
    if (tableExists[0].exists) {
      console.log('Dropping __drizzle_migrations table...');
      await client`DROP TABLE "__drizzle_migrations";`;
    } else {
      console.log('No __drizzle_migrations table found.');
    }

    console.log('Migration state has been reset.');
    await client.end();
    console.log('Done.');
  } catch (error) {
    console.error('Error resetting migrations:', error);
  }
}

resetMigrations();
