import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';
import type { z } from 'zod'; // Remove "type" keyword to import the actual implementation

import { validationErrorResponse } from '../validation'; // This already exists in validation/index.ts

type ValidatorFunction = (req: NextRequest) => Promise<NextResponse | null>;

export function validateBody<T extends z.ZodType>(schema: T): ValidatorFunction {
  return async (req: NextRequest) => {
    try {
      const body = await req.json().catch(() => ({}));
      const result = schema.safeParse(body);

      if (!result.success) {
        return validationErrorResponse(result.error);
      }

      // Attach the validated data to the request
      (req as any).validatedBody = result.data;
      return null;
    }
    catch (error) {
      return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
    }
  };
}

export function validateQuery<T extends z.ZodType>(schema: T): ValidatorFunction {
  return async (req: NextRequest) => {
    try {
      const url = new URL(req.url);
      const queryParams = Object.fromEntries(url.searchParams.entries());
      const result = schema.safeParse(queryParams);

      if (!result.success) {
        return validationErrorResponse(result.error);
      }

      // Attach the validated data to the request
      (req as any).validatedQuery = result.data;
      return null;
    }
    catch (error) {
      return NextResponse.json({ error: 'Invalid query parameters' }, { status: 400 });
    }
  };
}

export function validateParams<T extends z.ZodType>(
  schema: T,
  getParams: (req: NextRequest) => unknown,
): ValidatorFunction {
  return async (req: NextRequest) => {
    try {
      const params = getParams(req);
      const result = schema.safeParse(params);

      if (!result.success) {
        return validationErrorResponse(result.error);
      }

      // Attach the validated data to the request
      (req as any).validatedParams = result.data;
      return null;
    }
    catch (error) {
      return NextResponse.json({ error: 'Invalid route parameters' }, { status: 400 });
    }
  };
}

// Compose multiple validators
export function composeValidators(...validators: ValidatorFunction[]): ValidatorFunction {
  return async (req: NextRequest) => {
    for (const validator of validators) {
      const result = await validator(req);
      if (result) {
        return result;
      }
    }
    return null;
  };
}
