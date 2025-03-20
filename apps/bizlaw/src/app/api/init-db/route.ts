import { NextResponse } from 'next/server';

import { initDb } from '../../../lib/db/db';

// Initialize DB connection using Drizzle
export async function GET() {
  try {
    // Use your existing Drizzle initialization
    await initDb();

    return NextResponse.json({ status: 'Database initialized successfully' });
  }
  catch (error) {
    console.error('Error initializing database:', error);
    return NextResponse.json(
      { error: 'Failed to initialize database' },
      { status: 500 },
    );
  }
}
