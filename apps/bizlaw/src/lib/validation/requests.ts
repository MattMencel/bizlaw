import { z } from 'zod';

import { idSchema, paginationSchema, uuidSchema } from './common';
import { caseSchema } from './schemas';

// Case request schemas
export const getCaseByIdSchema = z.object({
  id: idSchema,
});

export const updateCaseSchema = z.object({
  id: idSchema,
  updates: caseSchema.partial().omit({ id: true, createdAt: true, updatedAt: true }),
});

export const listCasesSchema = z
  .object({
    search: z.string().optional(),
    sortBy: z.string().optional(),
    sortOrder: z.enum(['asc', 'desc']).optional(),
    active: z.boolean().optional(),
  })
  .merge(paginationSchema);

// Team requests
export const getTeamByIdSchema = z.object({
  id: idSchema,
});

export const getTeamsByCaseSchema = z.object({
  caseId: idSchema,
});

// Team member requests
export const getTeamMemberSchema = z.object({
  teamId: idSchema,
  userId: uuidSchema,
});

export const addTeamMemberSchema = z.object({
  teamId: idSchema,
  userId: uuidSchema,
});
