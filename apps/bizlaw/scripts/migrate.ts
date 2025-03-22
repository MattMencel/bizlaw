import path from 'path';
import * as dotenv from 'dotenv';

// Use relative path since we're in a script
// Can't use @/ aliases outside Next.js
import { runMigrations, findMigrationsDirectory } from '../src/lib/db/migrations';

// Load environment variables before imports
dotenv.config();

async function main() {
  try {
    const migrationsFolder = findMigrationsDirectory();
    console.info(`Using migrations directory: ${migrationsFolder}`);

    await runMigrations({ force: true, migrationsFolder });
    console.info('Migration script completed successfully');
    process.exit(0);
  } catch (error) {
    console.error('Migration script failed:', error);
    process.exit(1);
  }
}

main();
