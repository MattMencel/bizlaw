import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth/next';
import { desc, eq, and } from 'drizzle-orm';

import { authOptions } from '@/lib/auth/auth';
import { getDb, initDb } from '@/lib/db/db';
import { cases, CaseStatus, CaseType } from '@/lib/db/schema';
import { isValidEnumValue } from '@/lib/utils/type-guards';

export async function GET(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const isAdmin = session.user.role === 'admin';
    const isInstructor = ['professor', 'admin'].includes(session.user.role ?? '');

    const searchParams = request.nextUrl.searchParams;
    const type = searchParams.get('type');
    const status = searchParams.get('status');

    await initDb();
    const db = getDb();

    // Build conditions array
    const conditions = [];

    // Use the type guard for CaseType validation
    if (isValidEnumValue(CaseType, type)) {
      conditions.push(eq(cases.caseType, type));
    }

    // Use the type guard for CaseStatus validation
    if (isValidEnumValue(CaseStatus, status)) {
      conditions.push(eq(cases.status, status));
    }

    // Non-instructors can only see published cases
    if (!isInstructor) {
      conditions.push(eq(cases.status, CaseStatus.PUBLISHED));
    }

    // Execute query with all conditions at once
    const allCases = await db
      .select()
      .from(cases)
      .where(conditions.length > 0 ? and(...conditions) : undefined)
      .orderBy(desc(cases.createdAt));

    return NextResponse.json(allCases);
  } catch (error) {
    console.error('Error fetching cases:', error);
    return NextResponse.json({ error: 'Failed to fetch cases' }, { status: 500 });
  }
}

// Create a new case
export async function POST(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user || !['admin', 'professor'].includes(session.user.role ?? '')) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();

    // Validate required fields
    if (!body.title || !isValidEnumValue(CaseType, body.caseType)) {
      return NextResponse.json({ error: 'Missing or invalid required fields' }, { status: 400 });
    }

    await initDb();
    const db = getDb();

    // Generate a reference number
    const referenceNumber = `CASE-${Date.now().toString().slice(-6)}-${Math.floor(Math.random() * 1000)}`;

    const [newCase] = await db
      .insert(cases)
      .values({
        title: body.title,
        referenceNumber,
        caseType: body.caseType,
        description: body.description || null,
        summary: body.summary || null,
        createdBy: session.user.id,
      })
      .returning();

    return NextResponse.json(newCase, { status: 201 });
  } catch (error) {
    console.error('Error creating case:', error);
    return NextResponse.json({ error: 'Failed to create case' }, { status: 500 });
  }
}
