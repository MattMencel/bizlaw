import { eq, and, desc, sql, like, asc } from 'drizzle-orm';
import type { SQL } from 'drizzle-orm';
import type { z } from 'zod';

import { getDb } from './db';
import { cases, teams, teamMembers, users, documents, caseEvents } from './schema';
import type { NewCase, Case } from './schema';
// Import CaseWithRelations directly from combined-types
import type { CaseWithRelations } from './schema/combined-types';
import { listCasesSchema } from '@/lib/validation/case';

// Get cases with filters
export async function getCases(
  params: z.infer<typeof listCasesSchema>,
): Promise<{ data: Case[]; total: number; page: number; limit: number }> {
  const { page = 1, limit = 10, search, sortBy = 'createdAt', sortOrder = 'desc', active } = params;

  const db = getDb();
  const offset = (page - 1) * limit;

  // Build where conditions
  const whereConditions: SQL[] = [];

  if (typeof active === 'boolean') {
    whereConditions.push(eq(cases.active, active));
  }

  if (search && search.trim() !== '') {
    // Create title search condition with proper typing
    const titleSearch = like(cases.title, `%${search}%`);

    // For description search, use a single SQL template literal for the entire expression
    const descSearch = sql`(${cases.description} IS NOT NULL AND ${cases.description} LIKE ${`%${search}%`})`;

    // Combine with OR using SQL template instead of or() function
    whereConditions.push(sql`(${titleSearch} OR ${descSearch})`);
  }

  // Build final where clause
  const whereClause =
    whereConditions.length > 0
      ? whereConditions.length === 1
        ? whereConditions[0] // If only one condition, use it directly
        : and(...whereConditions)
      : undefined;

  // Get total count - provide a fallback condition that's always true
  const [{ count }] = await db
    .select({ count: sql`count(*)`.mapWith(Number) })
    .from(cases)
    .where(whereClause ?? sql`1=1`);

  // Prepare the order by expression based on the sortBy field
  let orderByColumn;

  // Determine which column to sort by
  switch (sortBy) {
    case 'createdAt':
      orderByColumn = cases.createdAt;
      break;
    case 'updatedAt':
      orderByColumn = cases.updatedAt;
      break;
    case 'title':
      orderByColumn = cases.title;
      break;
    case 'id':
      orderByColumn = cases.id;
      break;
    case 'active':
      orderByColumn = cases.active;
      break;
    default:
      orderByColumn = cases.createdAt; // Default
  }

  // Apply the direction to the order
  const orderExpression = sortOrder === 'desc' ? desc(orderByColumn) : asc(orderByColumn);

  // Get data - build the entire query in one go
  const data = await db
    .select()
    .from(cases)
    .where(whereClause ?? sql`1=1`)
    .orderBy(orderExpression)
    .limit(limit)
    .offset(offset);

  return {
    data,
    total: count,
    page,
    limit,
  };
}

// Get case by ID
export async function getCaseById(id: number): Promise<CaseWithRelations | null> {
  const db = getDb();

  const result = await db.select().from(cases).where(eq(cases.id, id)).limit(1);

  if (result.length === 0) {
    return null;
  }

  const caseData = result[0];

  // Get related teams
  const teamsData = await db.select().from(teams).where(eq(teams.caseId, id));

  // Get related events
  const eventsData = await db.select().from(caseEvents).where(eq(caseEvents.caseId, id));

  return {
    ...caseData,
    teams: teamsData,
    events: eventsData,
  };
}

// Create case
export async function createCase(data: NewCase): Promise<Case> {
  const db = getDb();

  const [newCase] = await db.insert(cases).values(data).returning();

  return newCase;
}

// Update case
export async function updateCase(id: number, data: Partial<NewCase>): Promise<Case> {
  const db = getDb();

  const [updatedCase] = await db
    .update(cases)
    .set({
      ...data,
      updatedAt: new Date(),
    })
    .where(eq(cases.id, id))
    .returning();

  return updatedCase;
}

// Delete case
export async function deleteCase(id: number): Promise<boolean> {
  const db = getDb();

  // Fix: Call returning() without arguments
  const result = await db.delete(cases).where(eq(cases.id, id)).returning();

  return result.length > 0;
}

/**
 * Get all cases
 */
export async function getAllCases() {
  const db = getDb();
  return await db.select().from(cases);
}

/**
 * Get all teams for a case
 */
export async function getTeamsForCase(caseId: number) {
  const db = getDb();
  return await db.select().from(teams).where(eq(teams.caseId, caseId));
}

/**
 * Get team members
 */
export async function getTeamMembers(teamId: number) {
  const db = getDb();
  return await db
    .select({
      id: teamMembers.id,
      teamId: teamMembers.teamId,
      userId: teamMembers.userId,
      user: {
        id: users.id,
        firstName: users.firstName,
        lastName: users.lastName,
        email: users.email,
      },
    })
    .from(teamMembers)
    .leftJoin(users, eq(teamMembers.userId, users.id))
    .where(eq(teamMembers.teamId, teamId));
}

/**
 * Get case events
 */
export async function getCaseEvents(caseId: number) {
  const db = getDb();
  return await db.select().from(caseEvents).where(eq(caseEvents.caseId, caseId));
}

/**
 * Get documents for a team
 */
export async function getTeamDocuments(teamId: number) {
  const db = getDb();
  return await db.select().from(documents).where(eq(documents.teamId, teamId));
}

// Add more query functions as needed
