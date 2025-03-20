import { NextResponse } from 'next/server';
import { z } from 'zod';

// API success response type
export interface ApiSuccess<T> {
  success: true
  data: T
}

// API error response type
export interface ApiError {
  success: false
  error: string
  details?: unknown
}

// Union type for API responses
export type ApiResponse<T> = ApiSuccess<T> | ApiError;

/**
 * Creates a success response
 */
export function successResponse<T>(data: T): NextResponse<ApiSuccess<T>> {
  return NextResponse.json({ success: true, data });
}

/**
 * Creates an error response
 */
export function errorResponse(message: string, status = 400, details?: unknown): NextResponse<ApiError> {
  return NextResponse.json(
    {
      success: false,
      error: message,
      ...(details ? { details } : {}),
    },
    { status },
  );
}
