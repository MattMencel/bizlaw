import { eq } from 'drizzle-orm';
import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';

import { initDb, getDb } from '@/lib/db/db';
import { documents } from '@/lib/db/schema';

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
      return NextResponse.json({ error: 'Invalid document ID' }, { status: 400 });
    }

    const [document] = await db.select().from(documents).where(eq(documents.id, numericId));

    if (!document) {
      return NextResponse.json({ error: 'Document not found' }, { status: 404 });
    }

    return NextResponse.json(document);
  }
  catch (error) {
    console.error('Error fetching document:', error);
    return NextResponse.json({ error: 'Failed to fetch document' }, { status: 500 });
  }
}

// Add PUT and DELETE handlers if needed
export async function PUT(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  // Await the params promise
  const { id } = await params;

  try {
    await initDb();
    const db = getDb();

    // Convert string ID to a number
    const numericId = parseInt(id, 10);

    // Validate ID
    if (isNaN(numericId)) {
      return NextResponse.json({ error: 'Invalid document ID' }, { status: 400 });
    }

    // Get request body
    const updates = await req.json().catch(() => ({}));

    // Additional validation for the updates could go here

    // Update document
    const [updatedDocument] = await db.update(documents).set(updates).where(eq(documents.id, numericId)).returning();

    if (!updatedDocument) {
      return NextResponse.json({ error: 'Document not found' }, { status: 404 });
    }

    return NextResponse.json(updatedDocument);
  }
  catch (error) {
    console.error('Error updating document:', error);
    return NextResponse.json({ error: 'Failed to update document' }, { status: 500 });
  }
}

export async function DELETE(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  // Await the params promise
  const { id } = await params;

  try {
    await initDb();
    const db = getDb();

    // Convert string ID to a number
    const numericId = parseInt(id, 10);

    // Validate ID
    if (isNaN(numericId)) {
      return NextResponse.json({ error: 'Invalid document ID' }, { status: 400 });
    }

    // Delete document
    await db.delete(documents).where(eq(documents.id, numericId));

    return NextResponse.json({ success: true });
  }
  catch (error) {
    console.error('Error deleting document:', error);
    return NextResponse.json({ error: 'Failed to delete document' }, { status: 500 });
  }
}
