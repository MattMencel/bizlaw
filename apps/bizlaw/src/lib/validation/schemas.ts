import { z } from 'zod';

import {
  idSchema,
  uuidSchema,
  emailSchema,
  nameSchema,
  descriptionSchema,
  dateSchema,
  urlSchema,
  booleanSchema,
} from './common';
import { UserRole, TeamRole } from '../db/schema';

// User schemas
export const userSchema = z.object({
  id: uuidSchema,
  email: emailSchema,
  firstName: nameSchema.nullable().optional(),
  lastName: nameSchema.nullable().optional(),
  // Fix: Cast the string literal to UserRole type
  role: z.nativeEnum(UserRole).default(UserRole.STUDENT),
  profileImage: urlSchema,
  createdAt: dateSchema,
  updatedAt: dateSchema,
});

export const newUserSchema = userSchema.omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});

// Case schemas
export const caseSchema = z.object({
  id: idSchema,
  title: nameSchema,
  description: descriptionSchema,
  active: booleanSchema.default(true),
  createdAt: dateSchema,
  updatedAt: dateSchema,
});

export const newCaseSchema = caseSchema.omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});

// Team schemas
export const teamSchema = z.object({
  id: idSchema,
  caseId: idSchema,
  name: nameSchema,
  role: z.nativeEnum(TeamRole),
  createdAt: dateSchema,
  updatedAt: dateSchema,
});

export const newTeamSchema = teamSchema.omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});

// Team Member schemas
export const teamMemberSchema = z.object({
  id: idSchema,
  teamId: idSchema,
  userId: uuidSchema,
  createdAt: dateSchema,
  updatedAt: dateSchema,
});

export const newTeamMemberSchema = teamMemberSchema.omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});

// Document schemas
export const documentSchema = z.object({
  id: idSchema,
  teamId: idSchema,
  title: nameSchema,
  content: z.string().optional(),
  createdAt: dateSchema,
  updatedAt: dateSchema,
});

export const newDocumentSchema = documentSchema.omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});

// Case Event schemas
export const caseEventSchema = z.object({
  id: idSchema,
  caseId: idSchema,
  title: nameSchema,
  description: descriptionSchema,
  dueDate: dateSchema.nullable().optional(),
  createdAt: dateSchema,
  updatedAt: dateSchema,
});

export const newCaseEventSchema = caseEventSchema.omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});
