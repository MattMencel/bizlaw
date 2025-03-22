import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth/next';
import { eq } from 'drizzle-orm';

import { authOptions } from '@/lib/auth/auth';
import { getDb, initDb } from '@/lib/db/db';
import { cases, caseDocuments, CaseStatus } from '@/lib/db/schema';
import { toNumericId } from '@/lib/utils';

// Get all documents for a case
export async function GET(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;
    const numericId = toNumericId(id);

    await initDb();
    const db = getDb();

    // Check if case exists and user has access
    const [caseData] = await db.select().from(cases).where(eq(cases.id, numericId));

    if (!caseData) {
      return NextResponse.json({ error: 'Case not found' }, { status: 404 });
    }

    const isInstructor = ['professor', 'admin'].includes(session.user.role ?? '');
    if (!isInstructor && caseData.status !== CaseStatus.PUBLISHED) {
      return NextResponse.json({ error: 'Access denied' }, { status: 403 });
    }

    // Use numericId here too
    const documents = await db.select().from(caseDocuments).where(eq(caseDocuments.caseId, numericId));

    return NextResponse.json(documents);
  } catch (error) {
    console.error('Error fetching case documents:', error);
    return NextResponse.json({ error: 'Failed to fetch documents' }, { status: 500 });
  }
}

// Add a new document to a case
export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user || !['admin', 'professor'].includes(session.user.role ?? '')) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;
    const numericId = toNumericId(id);
    const body = await request.json();

    // Validate required fields
    if (!body.title || !body.documentType) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    await initDb();
    const db = getDb();

    // Check if case exists
    const [caseData] = await db.select().from(cases).where(eq(cases.id, numericId));

    if (!caseData) {
      return NextResponse.json({ error: 'Case not found' }, { status: 404 });
    }

    // Add document - use numericId here
    const [newDocument] = await db
      .insert(caseDocuments)
      .values({
        caseId: numericId,
        title: body.title,
        documentType: body.documentType,
        content: body.content || null,
        fileUrl: body.fileUrl || null,
      })
      .returning();

    return NextResponse.json(newDocument, { status: 201 });
  } catch (error) {
    console.error('Error adding document:', error);
    return NextResponse.json({ error: 'Failed to add document' }, { status: 500 });
  }
}
