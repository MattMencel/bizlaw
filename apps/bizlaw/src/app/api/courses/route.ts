import { eq } from 'drizzle-orm';
import { NextResponse } from 'next/server';

import { getDb } from '@/lib/db/db';
import { courses, users } from '@/lib/db/schema';

export async function GET() {
  const db = getDb();

  try {
    // Fetch all courses
    const allCourses = await db.select().from(courses);

    // Fetch professor names for courses
    const coursesWithProfessors = await Promise.all(
      allCourses.map(async (course) => {
        if (!course.professorId) {
          return {
            ...course,
            professorName: null,
          };
        }

        const [professor] = await db.select().from(users).where(eq(users.id, course.professorId)).limit(1);

        return {
          ...course,
          professorName: professor ? `${professor.firstName || ''} ${professor.lastName || ''}`.trim() : null,
        };
      }),
    );

    return NextResponse.json(coursesWithProfessors);
  }
  catch (error) {
    console.error('Error fetching courses:', error);
    return NextResponse.json({ error: 'Failed to fetch courses' }, { status: 500 });
  }
}
