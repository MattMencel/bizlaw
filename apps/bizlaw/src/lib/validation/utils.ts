import type { NextResponse } from 'next/server';
import type { z } from 'zod';

import { errorResponse } from '../api/response';

// Success result type
export interface ValidationSuccess<T> {
  success: true
  data: T
}

// The result of validation can be either a success result or a NextResponse
export type ValidationResult<T> = ValidationSuccess<T> | NextResponse;

/**
 * Type guard to check if a result is a success validation result
 */
export function isSuccessResult<T>(result: unknown): result is ValidationSuccess<T> {
  return (
    typeof result === 'object' && result !== null && 'success' in result && result.success === true && 'data' in result
  );
}

/**
 * Validates request data against a schema
 */
export function validateRequest<T extends z.ZodType>(schema: T, data: unknown): ValidationResult<z.infer<T>> {
  try {
    const result = schema.safeParse(data);

    if (!result.success) {
      return errorResponse('Validation failed', 400, result.error.format());
    }

    return { success: true, data: result.data };
  }
  catch (error) {
    console.error('Validation error:', error);
    return errorResponse('Validation error', 400, {
      message: error instanceof Error ? error.message : 'Unknown error',
    });
  }
}

/**
 * Helper to parse JSON safely with zod validation
 */
export async function parseAndValidate<T extends z.ZodType>(
  request: Request,
  schema: T,
): Promise<ValidationResult<z.infer<T>>> {
  try {
    const body = await request.json().catch(() => ({}));
    return validateRequest(schema, body);
  }
  catch (error) {
    return errorResponse('Invalid JSON', 400);
  }
}
