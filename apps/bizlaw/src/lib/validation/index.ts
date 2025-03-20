import { NextResponse } from 'next/server';
import type { z } from 'zod';

// Export a utility for validation error responses
export function validationErrorResponse(error: z.ZodError) {
  const formattedErrors = error.errors.map(err => ({
    path: err.path.join('.'),
    message: err.message,
  }));

  return NextResponse.json(
    {
      success: false,
      error: 'Validation failed',
      details: formattedErrors,
    },
    { status: 400 },
  );
}

// Export utilities
export * from './utils';
export * from './common';

// Export entity schemas
export * from './schemas';

// Export request schemas
export * from './requests';
