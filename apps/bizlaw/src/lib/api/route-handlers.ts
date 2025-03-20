import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';
import type { z } from 'zod';

import { errorResponse, successResponse } from './response';
import { initDb } from '../db/db';
import { parseAndValidate, validateRequest, isSuccessResult } from '../validation/utils';

type RouteContext<T = Record<string, string>> = {
  params: T
};

type ValidatedResult<T> = {
  success: true
  data: T
};

/**
 * Creates a GET handler with built-in validation and error handling
 */
export function createGetHandler<TParams extends z.ZodType, TQuery extends z.ZodType, TResponse>(options: {
  paramsSchema: TParams
  querySchema?: TQuery
  handler: (params: z.infer<TParams>, query?: z.infer<TQuery>, request?: NextRequest) => Promise<TResponse>
}) {
  return async (request: NextRequest, context: RouteContext<Record<string, string>>): Promise<NextResponse> => {
    try {
      await initDb();

      // Validate params
      const paramsResult = validateRequest(options.paramsSchema, context.params);

      // Fix: Check if result is not a successful validation result
      if (!isSuccessResult(paramsResult)) {
        // If it's a NextResponse, return it directly
        if (paramsResult instanceof NextResponse) {
          return paramsResult;
        }
        // Otherwise, create an error response
        return errorResponse('Invalid parameters', 400);
      }

      // Validate query params if schema provided
      let queryParams: z.infer<TQuery> | undefined = undefined;
      if (options.querySchema) {
        const url = new URL(request.url);
        const searchParams = Object.fromEntries(url.searchParams.entries());
        const queryResult = validateRequest(options.querySchema, searchParams);

        // Fix: Same check for query params
        if (!isSuccessResult(queryResult)) {
          if (queryResult instanceof NextResponse) {
            return queryResult;
          }
          return errorResponse('Invalid query parameters', 400);
        }
        queryParams = queryResult.data;
      }

      // Execute handler with validated data
      const result = await options.handler(paramsResult.data, queryParams, request);
      return successResponse(result);
    }
    catch (error) {
      console.error('Error in route handler:', error);
      return errorResponse(error instanceof Error ? error.message : 'An unexpected error occurred', 500);
    }
  };
}

/**
 * Creates a POST handler with built-in validation and error handling
 */
export function createPostHandler<TBody extends z.ZodType, TResponse>(options: {
  bodySchema: TBody
  handler: (body: z.infer<TBody>, request?: NextRequest) => Promise<TResponse>
}) {
  return async (request: NextRequest): Promise<NextResponse> => {
    try {
      await initDb();

      // Parse and validate the request body
      const bodyResult = await parseAndValidate(request, options.bodySchema);

      // Fix: Check if result is a NextResponse or validation result
      if (!isSuccessResult(bodyResult)) {
        if (bodyResult instanceof NextResponse) {
          return bodyResult;
        }
        return errorResponse('Invalid request body', 400);
      }

      // Execute handler with validated data
      const result = await options.handler(bodyResult.data, request);
      return successResponse(result);
    }
    catch (error) {
      console.error('Error in route handler:', error);
      return errorResponse(error instanceof Error ? error.message : 'An unexpected error occurred', 500);
    }
  };
}

/**
 * Creates a PUT handler with built-in validation and error handling
 */
export function createPutHandler<TParams extends z.ZodType, TBody extends z.ZodType, TResponse>(options: {
  paramsSchema: TParams
  bodySchema: TBody
  handler: (params: z.infer<TParams>, body: z.infer<TBody>, request?: NextRequest) => Promise<TResponse>
}) {
  return async (request: NextRequest, context: RouteContext<Record<string, string>>): Promise<NextResponse> => {
    try {
      await initDb();

      // Validate params
      const paramsResult = validateRequest(options.paramsSchema, context.params);
      if (!isSuccessResult(paramsResult)) {
        if (paramsResult instanceof NextResponse) {
          return paramsResult;
        }
        return errorResponse('Invalid parameters', 400);
      }

      // Parse and validate the request body
      const bodyResult = await parseAndValidate(request, options.bodySchema);
      if (!isSuccessResult(bodyResult)) {
        if (bodyResult instanceof NextResponse) {
          return bodyResult;
        }
        return errorResponse('Invalid request body', 400);
      }

      // Execute handler with validated data
      const result = await options.handler(paramsResult.data, bodyResult.data, request);
      return successResponse(result);
    }
    catch (error) {
      console.error('Error in route handler:', error);
      return errorResponse(error instanceof Error ? error.message : 'An unexpected error occurred', 500);
    }
  };
}

/**
 * Creates a DELETE handler with built-in validation and error handling
 */
export function createDeleteHandler<TParams extends z.ZodType, TResponse>(options: {
  paramsSchema: TParams
  handler: (params: z.infer<TParams>, request?: NextRequest) => Promise<TResponse>
}) {
  return async (request: NextRequest, context: RouteContext<Record<string, string>>): Promise<NextResponse> => {
    try {
      await initDb();

      // Validate params
      const paramsResult = validateRequest(options.paramsSchema, context.params);
      if (!isSuccessResult(paramsResult)) {
        if (paramsResult instanceof NextResponse) {
          return paramsResult;
        }
        return errorResponse('Invalid parameters', 400);
      }

      // Execute handler with validated data
      const result = await options.handler(paramsResult.data, request);
      return successResponse(result);
    }
    catch (error) {
      console.error('Error in route handler:', error);
      return errorResponse(error instanceof Error ? error.message : 'An unexpected error occurred', 500);
    }
  };
}
