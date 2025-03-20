import { z } from 'zod';

import type { teamSchema, userSchema, documentSchema } from '../validation';
import { caseSchema, listCasesSchema } from '../validation';

// API Response Types
export type ApiResponse<T> = { data: T, error?: never } | { data?: never, error: string };

export type PaginatedApiResponse<T> = ApiResponse<{
  data: T[]
  total: number
  page: number
  limit: number
}>;

// Inferred Types
export type Case = z.infer<typeof caseSchema>;
export type Team = z.infer<typeof teamSchema>;
export type User = z.infer<typeof userSchema>;
export type Document = z.infer<typeof documentSchema>;
export type ListCasesParams = z.infer<typeof listCasesSchema>;

// API Endpoints Type Definitions
export const apiEndpoints = {
  cases: {
    list: {
      url: '/api/cases',
      method: 'GET',
      params: listCasesSchema,
      response: z.object({
        data: z.array(caseSchema),
        total: z.number(),
        page: z.number(),
        limit: z.number(),
      }),
    },
    get: {
      url: '/api/cases/:id',
      method: 'GET',
      params: z.object({ id: z.number() }),
      response: caseSchema,
    },
    create: {
      url: '/api/cases',
      method: 'POST',
      body: caseSchema.omit({ id: true, createdAt: true, updatedAt: true }),
      response: caseSchema,
    },
    update: {
      url: '/api/cases/:id',
      method: 'PUT',
      params: z.object({ id: z.number() }),
      body: caseSchema.omit({ id: true, createdAt: true, updatedAt: true }).partial(),
      response: caseSchema,
    },
    delete: {
      url: '/api/cases/:id',
      method: 'DELETE',
      params: z.object({ id: z.number() }),
      response: z.object({ success: z.boolean() }),
    },
  },
  // Add more endpoint definitions for other resources
};

// Type-safe API client
type ApiEndpoint = {
  url: string
  method: string
  params?: z.ZodType<any>
  body?: z.ZodType<any>
  response: z.ZodType<any>
};

type ApiClientOptions = {
  baseUrl?: string
};

export class ApiClient {
  private baseUrl: string;

  constructor(options: ApiClientOptions = {}) {
    this.baseUrl = options.baseUrl || '';
  }

  async request<T extends ApiEndpoint>(
    endpoint: T,
    {
      params,
      body,
      query,
    }: {
      params?: z.infer<NonNullable<T['params']>>
      body?: z.infer<NonNullable<T['body']>>
      query?: Record<string, string | number | boolean>
    } = {},
  ): Promise<z.infer<T['response']>> {
    // Build URL with path parameters
    let url = endpoint.url;
    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        url = url.replace(`:${key}`, String(value));
      });
    }

    // Add query parameters
    if (query && Object.keys(query).length > 0) {
      const searchParams = new URLSearchParams();
      Object.entries(query).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          searchParams.append(key, String(value));
        }
      });
      url = `${url}?${searchParams.toString()}`;
    }

    // Build request options
    const options: RequestInit = {
      method: endpoint.method,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    };

    // Add request body
    if (body) {
      options.body = JSON.stringify(body);
    }

    // Make the request
    const response = await fetch(`${this.baseUrl}${url}`, options);

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ error: 'Unknown error' }));
      throw new Error(errorData.error || `Request failed with status ${response.status}`);
    }

    // Parse and validate response
    const data = await response.json();
    return data;
  }

  // Convenience methods for specific API endpoints
  async getCases(params?: Partial<ListCasesParams>) {
    return this.request(apiEndpoints.cases.list, { query: params });
  }

  async getCase(id: number) {
    return this.request(apiEndpoints.cases.get, { params: { id } });
  }

  async createCase(data: z.infer<typeof apiEndpoints.cases.create.body>) {
    return this.request(apiEndpoints.cases.create, { body: data });
  }

  async updateCase(id: number, data: z.infer<typeof apiEndpoints.cases.update.body>) {
    return this.request(apiEndpoints.cases.update, { params: { id }, body: data });
  }

  async deleteCase(id: number) {
    return this.request(apiEndpoints.cases.delete, { params: { id } });
  }
}

// Create a singleton instance for client-side use
export const api = new ApiClient();
