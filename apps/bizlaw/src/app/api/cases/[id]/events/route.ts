import { eq } from 'drizzle-orm';
import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';

import { initDb, getDb } from '@/lib/db/db';
import { caseEvents } from '@/lib/db/schema';

// Changed from caseId to id for consistency
export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  // Await the params promise
  const { id } = await params;

  try {
    await initDb();
    const db = getDb();

    // Convert string id to number since caseId column is a number type
    const numericId = parseInt(id, 10);

    // Now using the numeric ID with the caseId column
    const events = await db.select().from(caseEvents).where(eq(caseEvents.caseId, numericId));

    return NextResponse.json(events);
  }
  catch (error) {
    console.error('Error fetching events:', error);
    return NextResponse.json({ error: 'Failed to fetch events' }, { status: 500 });
  }
}
