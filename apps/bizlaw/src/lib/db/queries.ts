import { eq } from 'drizzle-orm';

import { getDb } from './db';
import { courses, users, cases } from './schema';

/**
 * Get a course by ID
 */
export async function getCourseById(id: number) {
  const db = getDb();
  const result = await db.select().from(courses).where(eq(courses.id, id)).limit(1);

  return result[0] || null;
}

/**
 * Get a course by ID with related professor
 */
export async function getCourseWithProfessor(id: number) {
  const db = getDb();
  const result = await db
    .select({
      id: courses.id,
      name: courses.name,
      description: courses.description,
      professor: {
        id: users.id,
        firstName: users.firstName,
        lastName: users.lastName,
        email: users.email,
      },
      createdAt: courses.createdAt,
      updatedAt: courses.updatedAt,
    })
    .from(courses)
    .leftJoin(users, eq(courses.professorId, users.id))
    .where(eq(courses.id, id))
    .limit(1);

  return result[0] || null;
}

// Add more query functions as needed
