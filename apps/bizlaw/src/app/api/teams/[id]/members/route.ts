import { eq } from 'drizzle-orm';
import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';

import { initDb, getDb } from '@/lib/db/db';
import { teamMembers } from '@/lib/db/schema';

// Fixed: Changed parameter name from teamId to id to match route path [id]
export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  // Await the params promise
  const { id } = await params;

  try {
    await initDb();
    const db = getDb();

    // Convert string ID to a number for database query
    const numericId = parseInt(id, 10);

    // Validate that the ID is a valid number
    if (isNaN(numericId)) {
      return NextResponse.json({ error: 'Invalid team ID' }, { status: 400 });
    }

    // Use numericId in the query
    const members = await db.select().from(teamMembers).where(eq(teamMembers.teamId, numericId));

    return NextResponse.json(members);
  }
  catch (error) {
    console.error('Error fetching team members:', error);
    return NextResponse.json({ error: 'Failed to fetch team members' }, { status: 500 });
  }
}

// Add POST handler for adding members
export async function POST(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  try {
    await initDb();
    const db = getDb();

    const numericId = parseInt(id, 10);
    if (isNaN(numericId)) {
      return NextResponse.json({ error: 'Invalid team ID' }, { status: 400 });
    }

    // Get the user ID from request body
    const body = await req.json().catch(() => ({}));
    const { userId } = body;

    if (!userId) {
      return NextResponse.json({ error: 'User ID is required' }, { status: 400 });
    }

    // Insert new team member
    const [newMember] = await db
      .insert(teamMembers)
      .values({
        teamId: numericId,
        userId,
      })
      .returning();

    return NextResponse.json(newMember, { status: 201 });
  }
  catch (error) {
    console.error('Error adding team member:', error);
    return NextResponse.json({ error: 'Failed to add team member' }, { status: 500 });
  }
}
