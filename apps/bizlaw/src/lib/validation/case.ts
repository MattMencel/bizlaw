import { z } from 'zod';

export const listCasesSchema = z.object({
  page: z.coerce.number().optional().default(1),
  limit: z.coerce.number().optional().default(10),
  search: z.string().optional(),
  sortBy: z.enum(['id', 'title', 'createdAt', 'updatedAt', 'active']).optional().default('createdAt'),
  sortOrder: z.enum(['asc', 'desc']).optional().default('desc'),
  active: z.boolean().optional(),
});

// Other validation schemas for cases
