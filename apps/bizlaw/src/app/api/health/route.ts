import { NextResponse } from 'next/server';
import { initDb, getDb } from '../../../lib/db/db';

export async function GET() {
  try {
    await initDb();
    const db = getDb();

    // Simple database query to verify connection
    const result = await db.execute(sql`SELECT 1 AS value`);

    return NextResponse.json({
      status: 'ok',
      database: 'connected',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Health check failed:', error);
    return NextResponse.json(
      {
        status: 'error',
        database: 'disconnected',
        error: error instanceof Error ? error.message : String(error),
        timestamp: new Date().toISOString(),
      },
      { status: 503 },
    );
  }
}
