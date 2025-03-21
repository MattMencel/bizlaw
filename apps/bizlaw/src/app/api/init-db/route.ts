import { NextResponse } from 'next/server';

import { initDb } from '../../../lib/db/db';
import { runMigrations, findMigrationsDirectory } from '../../../lib/db/migrations';

export async function GET() {
  try {
    // Initialize database connection
    await initDb();

    // Find migrations directory and run migrations
    const migrationsFolder = findMigrationsDirectory();
    console.info(`Using migrations directory: ${migrationsFolder}`);

    // Run migrations
    await runMigrations({ force: true, migrationsFolder });

    return NextResponse.json({ status: 'Database initialized and migrations completed' });
  } catch (error) {
    console.error('Error initializing database:', error);
    return NextResponse.json({ error: 'Failed to initialize database' }, { status: 500 });
  }
}
