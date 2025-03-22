import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth/next';
import { eq } from 'drizzle-orm';

import { authOptions } from '@/lib/auth/auth';
import { getDb, initDb } from '@/lib/db/db';
import { cases, caseDetails, caseDocuments, CaseStatus } from '@/lib/db/schema';
import { toNumericId } from '@/lib/utils';

// Get a specific case with details
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

    // Get the case
    const [caseData] = await db.select().from(cases).where(eq(cases.id, numericId));

    if (!caseData) {
      return NextResponse.json({ error: 'Case not found' }, { status: 404 });
    }

    // Check access permissions
    const isInstructor = ['professor', 'admin'].includes(session.user.role ?? '');
    if (!isInstructor && caseData.status !== CaseStatus.PUBLISHED) {
      return NextResponse.json({ error: 'Access denied' }, { status: 403 });
    }

    // Get case details
    const [details] = await db.select().from(caseDetails).where(eq(caseDetails.caseId, numericId));

    // Get case documents
    const documents = await db.select().from(caseDocuments).where(eq(caseDocuments.caseId, numericId));

    // Combine all data
    const fullCase = {
      ...caseData,
      details: details || null,
      documents: documents || [],
    };

    return NextResponse.json(fullCase);
  } catch (error) {
    console.error('Error fetching case:', error);
    return NextResponse.json({ error: 'Failed to fetch case' }, { status: 500 });
  }
}

// Update a case
export async function PATCH(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user || !['admin', 'professor'].includes(session.user.role ?? '')) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;
    const numericId = toNumericId(id);
    const body = await request.json();

    await initDb();
    const db = getDb();

    // Verify the case exists
    const [existingCase] = await db.select().from(cases).where(eq(cases.id, numericId));

    if (!existingCase) {
      return NextResponse.json({ error: 'Case not found' }, { status: 404 });
    }

    // Update case
    const [updatedCase] = await db
      .update(cases)
      .set({
        title: body.title ?? existingCase.title,
        description: body.description ?? existingCase.description,
        // Remove summary if it doesn't exist in your schema
        // summary: body.summary ?? existingCase.summary,
        status: body.status ?? existingCase.status,
        caseType: body.caseType ?? existingCase.caseType,
        updatedAt: new Date(),
      })
      .where(eq(cases.id, numericId))
      .returning();

    // Update case details if provided
    if (body.details) {
      const [existingDetails] = await db.select().from(caseDetails).where(eq(caseDetails.caseId, numericId));

      if (existingDetails) {
        await db
          .update(caseDetails)
          .set({
            plaintiffInfo: body.details.plaintiffInfo ?? existingDetails.plaintiffInfo,
            defendantInfo: body.details.defendantInfo ?? existingDetails.defendantInfo,
            legalIssues: body.details.legalIssues ?? existingDetails.legalIssues,
            relevantLaws: body.details.relevantLaws ?? existingDetails.relevantLaws,
            timeline: body.details.timeline ?? existingDetails.timeline,
            teachingNotes: body.details.teachingNotes ?? existingDetails.teachingNotes,
            assignmentDetails: body.details.assignmentDetails ?? existingDetails.assignmentDetails,
          })
          .where(eq(caseDetails.caseId, numericId));
      } else {
        await db.insert(caseDetails).values({
          caseId: numericId, // Use numericId here too
          ...body.details,
        });
      }
    }

    return NextResponse.json(updatedCase);
  } catch (error) {
    console.error('Error updating case:', error);
    return NextResponse.json({ error: 'Failed to update case' }, { status: 500 });
  }
}

// Delete a case
export async function DELETE(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user || session.user.role !== 'admin') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;
    const numericId = toNumericId(id);

    await initDb();
    const db = getDb();

    // Delete case documents first (foreign key constraint)
    await db.delete(caseDocuments).where(eq(caseDocuments.caseId, numericId));

    // Delete case details
    await db.delete(caseDetails).where(eq(caseDetails.caseId, numericId));

    // Delete the case
    const [deletedCase] = await db.delete(cases).where(eq(cases.id, numericId)).returning();

    if (!deletedCase) {
      return NextResponse.json({ error: 'Case not found' }, { status: 404 });
    }

    return NextResponse.json({ message: 'Case deleted successfully' });
  } catch (error) {
    console.error('Error deleting case:', error);
    return NextResponse.json({ error: 'Failed to delete case' }, { status: 500 });
  }
}
