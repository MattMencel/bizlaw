import { Suspense } from 'react';

import CourseListSkeleton from '@/components/courses/CourseListSkeleton';
import CoursesList from '@/components/courses/CoursesList';

export const metadata = {
  title: 'Courses | Business Law',
};

export default function CoursesPage() {
  return (
    <div className="container mx-auto py-8">
      <h1 className="text-3xl font-bold mb-6">Courses</h1>
      <Suspense fallback={<CourseListSkeleton />}>
        <CoursesList />
      </Suspense>
    </div>
  );
}
