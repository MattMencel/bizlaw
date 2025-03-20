import type { z } from 'zod';

import type { ApiResponse } from '@/lib/api/response';

export type ApiEndpointDefinition<
  TParams extends z.ZodType = z.ZodType,
  TBody extends z.ZodType = z.ZodType,
  TResponse extends z.ZodType = z.ZodType,
  TQuery extends z.ZodType = z.ZodType,
> = {
  url: string
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH'
  params?: TParams
  body?: TBody
  query?: TQuery
  response: TResponse
};

export type TypedApiClient = {
  request: <T extends ApiEndpointDefinition>(
    endpoint: T,
    options?: {
      params?: z.infer<NonNullable<T['params']>>
      body?: z.infer<NonNullable<T['body']>>
      query?: z.infer<NonNullable<T['query']>>
    },
  ) => Promise<ApiResponse<z.infer<T['response']>>>
};
