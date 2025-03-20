import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';

import { errorResponse, successResponse } from '@/lib/api/response';
import { initDb } from '@/lib/db/db';
import { getCases, createCase } from '@/lib/db/queries';
import { validateRequest, listCasesSchema, newCaseSchema } from '@/lib/validation';
import { isSuccessResult } from '@/lib/validation/utils';

// Get list of cases with filtering
export async function GET(request: NextRequest) {
  try {
    await initDb();

    // Get query parameters
    const url = new URL(request.url);
    const searchParams = Object.fromEntries(url.searchParams.entries());

    // Validate query parameters
    const validationResult = validateRequest(listCasesSchema, {
      page: searchParams.page ? parseInt(searchParams.page) : undefined,
      limit: searchParams.limit ? parseInt(searchParams.limit) : undefined,
      search: searchParams.search,
      sortBy: searchParams.sortBy,
      sortOrder: searchParams.sortOrder,
      active: searchParams.active === 'true' ? true : searchParams.active === 'false' ? false : undefined,
    });

    // Handle validation errors - updated to use isSuccessResult
    if (!isSuccessResult(validationResult)) {
      return validationResult;
    }

    // Use validated data
    const { data: params } = validationResult;
    const cases = await getCases(params);

    return successResponse(cases);
  }
  catch (error) {
    console.error('Error fetching cases:', error);
    return errorResponse('Failed to fetch cases', 500);
  }
}

// Create new case
export async function POST(request: NextRequest) {
  try {
    await initDb();

    // Parse request body
    const body = await request.json().catch(() => ({}));

    // Validate request body against schema
    const validationResult = validateRequest(newCaseSchema, body);

    // Handle validation errors - updated to use isSuccessResult
    if (!isSuccessResult(validationResult)) {
      return validationResult;
    }

    // Use validated data
    const { data: newCase } = validationResult;

    // Create the case
    const createdCase = await createCase(newCase);

    return successResponse(createdCase);
  }
  catch (error) {
    console.error('Error creating case:', error);
    return errorResponse('Failed to create case', 500);
  }
}
