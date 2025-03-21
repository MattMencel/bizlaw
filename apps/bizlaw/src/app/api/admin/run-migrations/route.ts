import fs from 'fs/promises';
import path from 'path';
import { NextRequest, NextResponse } from 'next/server';
import postgres from 'postgres';
import { drizzle } from 'drizzle-orm/postgres-js';
import { sql } from 'drizzle-orm';

import * as schema from '@/lib/db/schema';
// Import from our consolidated migrations module
import { runMigrations, findMigrationsDirectory } from '@/lib/db/migrations';

// Only run in Node.js runtime
export const runtime = 'nodejs';

// Use the dynamic finder function
const MIGRATIONS_FOLDER = findMigrationsDirectory();

// Define interfaces for better type safety
interface MigrationFile {
  name: string;
  path: string;
}

interface AppliedMigration {
  migration_name: string;
  created_at: string | Date;
}

/**
 * Helper function to safely get error message
 */
function getErrorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}

/**
 * GET handler - Show migration status
 */
export async function GET(req: NextRequest) {
  try {
    // Get connection string
    const connectionString = process.env.POSTGRES_URL_NON_POOLING || process.env.POSTGRES_URL;

    if (!connectionString) {
      throw new Error('Database connection string not found');
    }

    // Create a client for checking migrations with proper SSL settings
    const client = postgres(connectionString, {
      ssl:
        process.env.NODE_ENV === 'development' || process.env.POSTGRES_REJECT_UNAUTHORIZED === 'false'
          ? { rejectUnauthorized: false }
          : true,
    });

    const db = drizzle(client, { schema });

    // Get migration status
    const migrationStatus = await getMigrationStatus(db, client);

    // Close the client after we're done
    await client.end();

    return NextResponse.json({
      success: true,
      autoMigrate: process.env.AUTO_MIGRATE === 'true',
      migrations: migrationStatus,
    });
  } catch (error: unknown) {
    console.error('Failed to check migration status:', error);
    return NextResponse.json(
      {
        success: false,
        message: 'Failed to check migration status',
        error: getErrorMessage(error),
      },
      { status: 500 },
    );
  }
}

/**
 * POST handler - Run migrations
 */
export async function POST(req: NextRequest) {
  try {
    // Optional: Add auth check here to prevent unauthorized access
    console.info(`Using migrations directory: ${MIGRATIONS_FOLDER}`);

    // Run migrations with the consolidated function, force=true ensures it runs
    await runMigrations({ force: true, migrationsFolder: MIGRATIONS_FOLDER });

    // Get updated migration status
    const connectionString = process.env.POSTGRES_URL_NON_POOLING || process.env.POSTGRES_URL;

    if (!connectionString) {
      throw new Error('Database connection string not found');
    }

    const client = postgres(connectionString, {
      ssl:
        process.env.NODE_ENV === 'development' || process.env.POSTGRES_REJECT_UNAUTHORIZED === 'false'
          ? { rejectUnauthorized: false }
          : true,
    });

    const db = drizzle(client, { schema });
    const migrationStatus = await getMigrationStatus(db, client);
    await client.end();

    return NextResponse.json({
      success: true,
      message: 'Migrations completed successfully',
      migrations: migrationStatus,
    });
  } catch (error: unknown) {
    console.error('Failed to run migrations:', error);
    return NextResponse.json(
      {
        success: false,
        message: 'Failed to run migrations',
        error: getErrorMessage(error),
      },
      { status: 500 },
    );
  }
}

/**
 * Get detailed migration status
 */
async function getMigrationStatus(db: any, client: any) {
  try {
    // Check if __drizzle_migrations table exists
    const tableExists = await db.execute(sql`
      SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = '__drizzle_migrations'
      );
    `);

    const migrationTableExists = tableExists[0].exists;

    // Get applied migrations
    let appliedMigrations: AppliedMigration[] = [];

    if (migrationTableExists) {
      appliedMigrations = await db.execute(sql`
        SELECT * FROM __drizzle_migrations ORDER BY created_at ASC;
      `);
    }

    // Get migration files from disk
    let migrationFiles: MigrationFile[] = [];
    try {
      const files = await fs.readdir(MIGRATIONS_FOLDER);
      migrationFiles = files
        .filter(file => file.endsWith('.sql'))
        .map(file => ({
          name: file,
          path: path.join(MIGRATIONS_FOLDER, file),
        }));
    } catch (err: unknown) {
      console.error('Error reading migration files:', err);
    }

    // Determine pending migrations
    const appliedFilenames = new Set(appliedMigrations.map(m => m.migration_name));
    const pendingMigrations = migrationFiles.filter(file => !appliedFilenames.has(file.name)).map(file => file.name);

    // Get database info
    const dbInfo = await db.execute(sql`
      SELECT
        current_database() as database_name,
        version() as postgres_version
    `);

    // Get table counts
    const tableCounts = await db.execute(sql`
      SELECT COUNT(*) as table_count
      FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE';
    `);

    // Return status information
    return {
      database: dbInfo[0],
      tables: {
        count: parseInt(tableCounts[0].table_count, 10),
        migrationTableExists,
      },
      migrations: {
        total: migrationFiles.length,
        applied: appliedMigrations.length,
        pending: pendingMigrations.length,
        pendingList: pendingMigrations,
        appliedList: appliedMigrations.map(m => ({
          name: m.migration_name,
          appliedAt: m.created_at,
        })),
      },
    };
  } finally {
    // We don't close the client here as it's passed in
    // The caller is responsible for closing it
  }
}
