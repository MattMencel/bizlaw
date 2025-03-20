import { drizzle } from 'drizzle-orm/postgres-js';
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import postgres from 'postgres';

import * as schema from './schema';

// Define a more specific type for options
type PostgresOptions = {
  max?: number;
  ssl?:
    | {
        rejectUnauthorized: boolean;
      }
    | undefined;
};

let db: ReturnType<typeof createDbWithOptions> | null = null;
let sqlClient: postgres.Sql | null = null;
let initPromise: Promise<ReturnType<typeof createDbWithOptions>> | null = null;

// Function to create the database with prepared statements
function createDbWithOptions(connectionString: string, options: PostgresOptions = {}) {
  try {
    // Cast options to any to bypass the type checking
    const client = postgres(connectionString, options as any);
    sqlClient = client;
    return drizzle(client, {
      schema,
      logger: process.env.NODE_ENV !== 'production',
    });
  } catch (error) {
    console.error('Error creating database client:', error);
    throw error;
  }
}

export async function initDb() {
  if (!db) {
    // Vercel typically uses DATABASE_URL environment variable
    const connectionString =
      process.env.DATABASE_URL ||
      `postgres://${process.env.DB_USER || 'postgres'}:${
        process.env.DB_PASSWORD || 'postgres'
      }@${process.env.DB_HOST || 'localhost'}:${
        process.env.DB_PORT || '5432'
      }/${process.env.DB_NAME || 'business_law'}`;

    const options = {
      max: 10,
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : undefined,
    };

    db = createDbWithOptions(connectionString, options);
  }
  return db;
}

export function getDb() {
  if (!db) {
    console.warn('Database not initialized, attempting to initialize...');
    // Instead of throwing, try to initialize the DB
    throw new Error('Database not initialized. Call initDb() first.');
  }
  return db;
}

export function closeDb() {
  if (sqlClient) {
    sqlClient.end();
    sqlClient = null;
    db = null;
    initPromise = null;
    console.info('Database connection closed');
  }
}

// Auto-initialize in non-test environments
// This ensures the database is initialized when the module is first imported
if (process.env.NODE_ENV !== 'test') {
  console.info('Auto-initializing database connection...');
  initDb().catch(err => {
    console.error('Failed to auto-initialize database:', err);
  });
}
