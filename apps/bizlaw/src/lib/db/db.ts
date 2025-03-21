import fs from 'fs';
import path from 'path';
import { neon, neonConfig } from '@neondatabase/serverless';
import type { NeonHttpDatabase } from 'drizzle-orm/neon-http';
import { drizzle } from 'drizzle-orm/neon-http';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { drizzle as nodeDrizzle } from 'drizzle-orm/node-postgres';
// Add this import specifically for postgres-js migrations
import { drizzle as pgDrizzle } from 'drizzle-orm/postgres-js';
import { sql as drizzleSql } from 'drizzle-orm';
import { Pool } from 'pg';
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import postgres from 'postgres';

import * as schema from './schema';

// Import the migration utilities
import { runMigrations, shouldRunAutoMigrations } from './migrations';

// Configure neon for edge runtime if needed
neonConfig.fetchConnectionCache = true;

// Define a union type to handle both database types
type DrizzleDatabase = NeonHttpDatabase<typeof schema> | NodePgDatabase<typeof schema>;

// Database connection state with updated type
let db: DrizzleDatabase | null = null;
let sql: ReturnType<typeof neon> | null = null;
let pool: Pool | null = null;

// Track whether DB migrations have run in this process
let dbMigrationsRan = false;

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
      db = drizzle(sql, { schema });
    }
    // For Node.js runtime
    else {
      // Determine SSL settings based on environment
      const sslMode = process.env.POSTGRES_SSL_MODE || 'prefer';
      let sslConfig: any;

      // Special handling for Supabase connections
      if (connectionString.includes('supabase.com') || connectionString.includes('pooler.supabase.com')) {
        console.info('Detected Supabase connection - applying specific configuration');

        // Parse connection string to extract the host for logging
        try {
          const url = new URL(connectionString.replace('postgres://', 'http://'));
          console.info(`Connecting to Supabase database at ${url.hostname}`);
        } catch (e) {
          console.info('Could not parse connection string for logging');
        }

        // For Supabase, we need to explicitly disable certificate validation
        // This is safe because Supabase provides its own security layer
        sslConfig = {
          rejectUnauthorized: false,
        };
      }
      // For development environments
      else if (process.env.NODE_ENV === 'development' && process.env.POSTGRES_REJECT_UNAUTHORIZED === 'false') {
        console.info('Development mode: SSL certificate verification disabled');
        sslConfig = {
          rejectUnauthorized: false,
        };
      }
      // For production with Vercel, try standard SSL first
      else if (process.env.VERCEL) {
        console.info('Vercel environment detected, using built-in CA');
        sslConfig = true; // Let Node.js use system CA store
      }
      // Other environments - continue with your existing code
      else {
        try {
          // First check for certificate in project directory (production build)
          const prodCertPath = path.join(process.cwd(), './prod-ca-2021.crt');

          // Then check for certificate path from environment variable
          const envCertPath = process.env.SSL_CERT_FILE;

          let certPath = null;
          let certContent = null;

          // Try to find certificate file
          if (fs.existsSync(prodCertPath)) {
            certPath = prodCertPath;
            certContent = fs.readFileSync(certPath).toString();
            console.info(`Using SSL certificate from file: ${certPath}`);
          } else if (envCertPath && fs.existsSync(envCertPath)) {
            certPath = envCertPath;
            certContent = fs.readFileSync(certPath).toString();
            console.info(`Using SSL certificate from env path: ${envCertPath}`);
          }
          // Check environment variable for certificate content
          else if (process.env.SSL_CERT_CONTENT) {
            certContent = process.env.SSL_CERT_CONTENT;
            console.info('Using SSL certificate from environment variable');
          }

          if (certContent) {
            sslConfig = {
              ca: certContent,
              rejectUnauthorized: true,
            };
          } else {
            // Fallback to just using the system CA store
            console.warn('No specific SSL certificate found, using system CA store');
            sslConfig = true;
          }
        } catch (err) {
          console.error(`Error setting up SSL:`, err);
          // Fallback to disable strict verification in non-production
          if (process.env.NODE_ENV !== 'production') {
            console.warn('Falling back to non-strict SSL in non-production environment');
            sslConfig = {
              rejectUnauthorized: false,
            };
          } else {
            throw new Error(`SSL setup failed: ${err instanceof Error ? err.message : String(err)}`);
          }
        }
      }

      console.info('Connecting to database with SSL enabled');

      // Remove any sslmode parameter from the connection string
      // and let Node.js handle the SSL configuration
      let cleanConnectionString = connectionString;
      if (connectionString.includes('sslmode=')) {
        try {
          const url = new URL(connectionString.replace('postgres://', 'http://'));
          url.searchParams.delete('sslmode');
          cleanConnectionString = `postgres://${connectionString.split('postgres://')[1].split('?')[0]}${url.search}`;
        } catch (e) {
          console.warn('Could not clean connection string, using original', e);
        }
      }

      pool = new Pool({
        connectionString: cleanConnectionString,
        ssl: sslConfig,
      });

      db = nodeDrizzle(pool, { schema });
    }

    console.info('Database connection initialized successfully');

    // Verify connection works by running a simple query
    try {
      if (process.env.NEXT_RUNTIME === 'edge') {
        // For edge runtime
        const result = await (db as NeonHttpDatabase<typeof schema>).execute(drizzleSql`SELECT 1 AS connected`);
        console.info('Edge database connection verified');
      } else {
        // For Node.js runtime
        const result = await (db as NodePgDatabase<typeof schema>).execute(drizzleSql`SELECT 1 AS connected`);
        console.info('Node.js database connection verified');
      }
    } catch (verifyError) {
      console.error('Database connection verification failed:', verifyError);
      throw verifyError;
    }

    // Auto-run migrations if enabled
    if (shouldRunAutoMigrations() && !dbMigrationsRan) {
      dbMigrationsRan = true; // Mark as run immediately
      try {
        await runMigrations();
      } catch (migrateError) {
        console.error('Auto-migration failed:', migrateError);
        // Continue even if migrations fail
      }
    }

    return db;
  } catch (error) {
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
