import { neon, neonConfig } from '@neondatabase/serverless';
import type { NeonHttpDatabase } from 'drizzle-orm/neon-http';
import { drizzle } from 'drizzle-orm/neon-http';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { drizzle as nodeDrizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';

// Import schema (make sure this path is correct)
import * as schema from './schema';

// Configure neon for edge runtime if needed
neonConfig.fetchConnectionCache = true;

// Define a union type to handle both database types
type DrizzleDatabase = NeonHttpDatabase<typeof schema> | NodePgDatabase<typeof schema>;

// Database connection state with updated type
let db: DrizzleDatabase | null = null;
let sql: ReturnType<typeof neon> | null = null;
let pool: Pool | null = null;

/**
 * Initialize the database connection
 */
export async function initDb() {
  if (db) return db;

  try {
    // Use Vercel Postgres URL from environment variables
    const connectionString = process.env.POSTGRES_URL || process.env.POSTGRES_URL_NON_POOLING;

    if (!connectionString) {
      throw new Error('Database connection string not found');
    }

    // For edge runtime (serverless functions)
    if (process.env.NEXT_RUNTIME === 'edge') {
      sql = neon(connectionString);
      db = drizzle(sql, { schema }) as DrizzleDatabase;
    }
    // For Node.js runtime
    else {
      pool = new Pool({
        connectionString,
      });
      db = nodeDrizzle(pool, { schema }) as DrizzleDatabase;
    }

    console.info('Database connection initialized successfully');
    return db;
  }
  catch (error) {
    console.error('Failed to initialize database:', error);
    throw error;
  }
}

/**
 * Get the database instance
 * @returns DrizzleDB instance
 */
export function getDb(): DrizzleDatabase {
  if (!db) {
    throw new Error('Database not initialized. Call initDb() first.');
  }
  return db;
}

/**
 * Close the database connection
 */
export async function closeDb() {
  if (pool) {
    await pool.end();
  }
  db = null;
  sql = null;
  pool = null;
}
