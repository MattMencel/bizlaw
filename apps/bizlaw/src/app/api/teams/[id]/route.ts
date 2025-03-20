import { eq } from 'drizzle-orm';
import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';

import { initDb, getDb } from '@/lib/db/db';
import { teams } from '@/lib/db/schema';

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

    const [team] = await db.select().from(teams).where(eq(teams.id, numericId));

    if (!team) {
      return NextResponse.json({ error: 'Team not found' }, { status: 404 });
    }

    return NextResponse.json(team);
  }
  catch (error) {
    console.error('Error fetching team:', error);
    return NextResponse.json({ error: 'Failed to fetch team' }, { status: 500 });
  }
}

// Add PUT handler for updating teams
export async function PUT(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  try {
    await initDb();
    const db = getDb();

    const numericId = parseInt(id, 10);
    if (isNaN(numericId)) {
      return NextResponse.json({ error: 'Invalid team ID' }, { status: 400 });
    }

    // Get updates from request body
    const updates = await req.json().catch(() => ({}));

    // Update team
    const [updatedTeam] = await db.update(teams).set(updates).where(eq(teams.id, numericId)).returning();

    if (!updatedTeam) {
      return NextResponse.json({ error: 'Team not found' }, { status: 404 });
    }

    return NextResponse.json(updatedTeam);
  }
  catch (error) {
    console.error('Error updating team:', error);
    return NextResponse.json({ error: 'Failed to update team' }, { status: 500 });
  }
}

// Add DELETE handler
export async function DELETE(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  try {
    await initDb();
    const db = getDb();

    const numericId = parseInt(id, 10);
    if (isNaN(numericId)) {
      return NextResponse.json({ error: 'Invalid team ID' }, { status: 400 });
    }

    // Delete team
    await db.delete(teams).where(eq(teams.id, numericId));

    return NextResponse.json({ success: true });
  }
  catch (error) {
    console.error('Error deleting team:', error);
    return NextResponse.json({ error: 'Failed to delete team' }, { status: 500 });
  }
}
