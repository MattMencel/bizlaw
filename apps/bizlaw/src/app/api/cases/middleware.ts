import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';

import { initDb } from '@/lib/db/db';
import { getCases, createCase } from '@/lib/db/queries';
import { validateBody, validateQuery, composeValidators } from '@/lib/middleware/validateMiddleware';
import { listCasesSchema, newCaseSchema } from '@/lib/validation';

// Middleware for GET request
export const GET = async (request: NextRequest) => {
  // Validate query parameters
  const validator = validateQuery(listCasesSchema);
  const validationResponse = await validator(request);
  if (validationResponse) {
    return validationResponse;
  }

  try {
    await initDb();

    // Use validated query params
    const params = (request as any).validatedQuery;
    const result = await getCases(params);

    return NextResponse.json(result);
  }
  catch (error) {
    console.error('Error fetching cases:', error);
    return NextResponse.json({ error: 'Failed to fetch cases' }, { status: 500 });
  }
};

// Middleware for POST request
export const POST = async (request: NextRequest) => {
  // Validate request body
  const validator = validateBody(newCaseSchema);
  const validationResponse = await validator(request);
  if (validationResponse) {
    return validationResponse;
  }

  try {
    await initDb();

    // Use validated body
    const newCaseData = (request as any).validatedBody;
    const result = await createCase(newCaseData);

    return NextResponse.json(result, { status: 201 });
  }
  catch (error) {
    console.error('Error creating case:', error);
    return NextResponse.json({ error: 'Failed to create case' }, { status: 500 });
  }
};
