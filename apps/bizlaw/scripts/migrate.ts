import * as dotenv from 'dotenv';
import path from 'path';

// Load environment variables before imports
dotenv.config();

// Use relative path since we're in a script
// Can't use @/ aliases outside Next.js
import { runMigrations } from '../src/lib/db/migrations';

// We'll manually find the migrations directory
function findMigrationsDirectory() {
  const root = path.join(__dirname, '../../..');
  return path.join(root, 'drizzle');
}

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
