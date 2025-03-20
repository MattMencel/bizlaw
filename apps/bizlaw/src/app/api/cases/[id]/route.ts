import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';
import { z } from 'zod';

import { errorResponse, successResponse } from '@/lib/api/response';
import { initDb } from '@/lib/db/db';
import { getCaseById, updateCase, deleteCase } from '@/lib/db/queries';
import { validateRequest, getCaseByIdSchema, caseSchema } from '@/lib/validation';
import { isSuccessResult } from '@/lib/validation/utils';

// Remove RouteContext entirely

export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  // Await the params promise
  const { id } = await params;

  try {
    await initDb();

    const validationResult = validateRequest(getCaseByIdSchema, { id: parseInt(id, 10) });

    if (validationResult instanceof NextResponse) {
      return validationResult;
    }

    if (!isSuccessResult(validationResult)) {
      return errorResponse('Validation failed', 400);
    }

    const { data } = validationResult;
    const caseData = await getCaseById(data.id);

    if (!caseData) {
      return errorResponse('Case not found', 404);
    }

    return successResponse(caseData);
  }
  catch (error) {
    console.error('Error fetching case:', error);
    return errorResponse('Failed to fetch case', 500);
  }
}

export async function PUT(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  // Await the params promise
  const { id } = await params;

  try {
    await initDb();

    const body = await req.json().catch(() => ({}));

    const updateCaseSchema = z.object({
      id: z.number().int().positive(),
      updates: caseSchema.partial().omit({ id: true, createdAt: true, updatedAt: true }),
    });

    const validationResult = validateRequest(updateCaseSchema, {
      id: parseInt(id, 10),
      updates: body,
    });

    if (validationResult instanceof NextResponse) {
      return validationResult;
    }

    if (!isSuccessResult(validationResult)) {
      return errorResponse('Validation failed', 400);
    }

    const { data } = validationResult;
    const { id: validatedId, updates } = data;

    const existingCase = await getCaseById(validatedId);
    if (!existingCase) {
      return errorResponse('Case not found', 404);
    }

    const updatedCase = await updateCase(validatedId, updates);

    return successResponse(updatedCase);
  }
  catch (error) {
    console.error('Error updating case:', error);
    return errorResponse('Failed to update case', 500);
  }
}

export async function DELETE(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  // Await the params promise
  const { id } = await params;

  try {
    await initDb();

    const validationResult = validateRequest(getCaseByIdSchema, { id: parseInt(id, 10) });

    if (validationResult instanceof NextResponse) {
      return validationResult;
    }

    if (!isSuccessResult(validationResult)) {
      return errorResponse('Validation failed', 400);
    }

    const { data } = validationResult;
    const existingCase = await getCaseById(data.id);

    if (!existingCase) {
      return errorResponse('Case not found', 404);
    }

    await deleteCase(data.id);

    return successResponse({ success: true });
  }
  catch (error) {
    console.error('Error deleting case:', error);
    return errorResponse('Failed to delete case', 500);
  }
}
