import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';

import { getCourseById } from '../../../../lib/db/queries';

export async function GET(request: NextRequest, context: any) {
  const { params } = context;
  try {
    // If params.id might be an array, handle it appropriately
    const idStr = Array.isArray(params.id) ? params.id[0] : params.id;
    const courseId = parseInt(idStr, 10);
    const course = await getCourseById(courseId);

    if (!course) {
      return NextResponse.json({ error: 'Course not found' }, { status: 404 });
    }
    return NextResponse.json(course);
  }
  catch (error) {
    console.error('Error fetching course:', error);
    return NextResponse.json({ error: 'Failed to fetch course' }, { status: 500 });
  }
}
