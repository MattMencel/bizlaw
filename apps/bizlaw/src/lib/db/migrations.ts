import fs from 'fs';
import path from 'path';

import { drizzle } from 'drizzle-orm/postgres-js';
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import postgres from 'postgres';

import * as schema from './schema';

// Track if migrations have run in this process
let migrationsRan = false;

/**
 * Find the correct migrations directory by checking multiple potential locations
 */
export function findMigrationsDirectory(): string {
  // First look in project root (most likely location)
  const projectRoot = path.resolve(process.cwd(), '../..');
  const rootDrizzlePath = path.join(projectRoot, 'drizzle');

  console.info(`Project root directory: ${projectRoot}`);
  console.info(`Looking for migrations in: ${rootDrizzlePath}`);

  // Check if the migrations are in drizzle/migrations (standard structure)
  const migrationsPath = path.join(rootDrizzlePath, 'migrations');
  if (fs.existsSync(migrationsPath)) {
    try {
      const files = fs.readdirSync(migrationsPath);
      const sqlFiles = files.filter(file => file.endsWith('.sql'));

      if (sqlFiles.length > 0) {
        console.info(`Found ${sqlFiles.length} SQL files in ${migrationsPath}`);
        return rootDrizzlePath; // Return the base drizzle directory, not the migrations subdirectory
      }
      else {
        console.warn(`Directory exists but no SQL files in ${migrationsPath}`);
      }
    }
    catch (err) {
      console.warn(`Error reading migrations directory ${migrationsPath}:`, err);
    }
  }
  else {
    console.warn(`Migrations directory not found at ${migrationsPath}`);
  }

  // Alternative locations as fallback
  const possiblePaths = [
    path.join(process.cwd(), 'drizzle'),
    path.join(projectRoot, 'apps/bizlaw/drizzle'),
    path.join(process.cwd(), '../../drizzle'),
  ];

  // Check each possible base path
  for (const basePath of possiblePaths) {
    const migrationSubdir = path.join(basePath, 'migrations');
    if (fs.existsSync(migrationSubdir)) {
      try {
        const files = fs.readdirSync(migrationSubdir);
        const sqlFiles = files.filter(file => file.endsWith('.sql'));

        if (sqlFiles.length > 0) {
          console.info(`Found ${sqlFiles.length} SQL files in ${migrationSubdir}`);
          return basePath; // Return the base drizzle directory, not the migrations subdirectory
        }
      }
      catch (err) {
        console.warn(`Error checking ${migrationSubdir}:`, err);
      }
    }
  }

  // If no migrations found, return the default location
  console.warn(`No migration files found. Using ${rootDrizzlePath}`);
  return rootDrizzlePath;
}

/**
 * Ensure the migration directory structure exists
 */
function ensureMigrationStructure(baseDir: string): void {
  // Ensure migrations directory exists
  const migrationsDir = path.join(baseDir, 'migrations');
  if (!fs.existsSync(migrationsDir)) {
    console.info(`Creating migrations directory: ${migrationsDir}`);
    fs.mkdirSync(migrationsDir, { recursive: true });
  }

  // Ensure meta directory exists
  const metaDir = path.join(baseDir, 'meta');
  if (!fs.existsSync(metaDir)) {
    console.info(`Creating meta directory: ${metaDir}`);
    fs.mkdirSync(metaDir, { recursive: true });
  }

  // Ensure journal file exists
  const journalFile = path.join(metaDir, '_journal.json');
  if (!fs.existsSync(journalFile)) {
    console.info(`Creating empty journal file: ${journalFile}`);
    fs.writeFileSync(journalFile, JSON.stringify({ entries: [] }), 'utf8');
  }
}

/**
 * Shared function to run database migrations with consistent settings
 */
export async function runMigrations({
  connectionString = process.env.POSTGRES_URL_NON_POOLING || process.env.POSTGRES_URL,
  migrationsFolder = findMigrationsDirectory(),
  force = false,
}: {
  connectionString?: string
  migrationsFolder?: string
  force?: boolean
} = {}) {
  // Skip if migrations already ran (unless forced)
  if (migrationsRan && !force) {
    console.info('Migrations already ran in this process, skipping');
    return;
  }

  console.info(`Running database migrations from ${migrationsFolder}...`);

  // Make sure structure exists
  ensureMigrationStructure(migrationsFolder);

  try {
    if (!connectionString) {
      throw new Error('Database connection string not found');
    }

    // Handle SSL settings consistently
    const sslConfig
      = process.env.NODE_ENV === 'development' || process.env.POSTGRES_REJECT_UNAUTHORIZED === 'false'
        ? { rejectUnauthorized: false }
        : true;

    // Create a postgres-js client for migrations (always use non-pooled)
    const migrationClient = postgres(connectionString, { ssl: sslConfig });

    // Create a drizzle instance with postgres-js
    const db = drizzle(migrationClient);

    // List available migration files
    const migrationsSubdir = path.join(migrationsFolder, 'migrations');
    console.info(`Looking for SQL files in: ${migrationsSubdir}`);

    if (fs.existsSync(migrationsSubdir)) {
      try {
        const files = fs.readdirSync(migrationsSubdir);
        const sqlFiles = files.filter(file => file.endsWith('.sql'));
        console.info(`Found ${sqlFiles.length} SQL files for migration:`);
        sqlFiles.forEach(file => console.info(`- ${file}`));
      }
      catch (err) {
        console.warn('Error listing migration files:', err);
      }
    }
    else {
      console.warn(`No migrations subdirectory found at ${migrationsSubdir}`);
    }

    // Run migrations
    await migrate(db, { migrationsFolder });

    console.info('Migrations completed successfully!');
    migrationsRan = true;

    // Close the connection
    await migrationClient.end();
    return true;
  }
  catch (error) {
    console.error('Migration failed:', error);
    throw error;
  }
}

/**
 * Check if automatic migrations should be run based on environment
 */
export function shouldRunAutoMigrations(): boolean {
  return process.env.AUTO_MIGRATE === 'true';
}
