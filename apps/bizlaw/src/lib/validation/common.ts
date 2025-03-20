import { z } from 'zod';

// ID schema for numeric IDs
export const idSchema = z.number().int().positive();

// UUID schema for string IDs
export const uuidSchema = z.string().uuid();
export const emailSchema = z.string().email().min(5).max(255);
export const nameSchema = z.string().min(1).max(100);
export const descriptionSchema = z.string().max(1000).nullable().optional();
export const dateSchema = z.date().or(z.string().datetime());
export const urlSchema = z.string().url().nullable().optional();
export const booleanSchema = z.boolean();

// Pagination schema for list endpoints
export const paginationSchema = z.object({
  page: z.number().int().min(1).optional().default(1),
  limit: z.number().int().min(1).max(100).optional().default(10),
});

// Common query parameters
export const queryParamsSchema = z
  .object({
    search: z.string().optional(),
    sortBy: z.string().optional(),
    sortOrder: z.enum(['asc', 'desc']).optional(),
  })
  .merge(paginationSchema);
