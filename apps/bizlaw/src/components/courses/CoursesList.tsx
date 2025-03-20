'use client';

import Link from 'next/link';
import { useState, useEffect } from 'react';

type CourseResponse = {
  id: number
  name: string
  description: string | null
  professorName?: string
};

export default function CoursesList() {
  const [courses, setCourses] = useState<CourseResponse[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchCourses() {
      try {
        const response = await fetch('/api/courses');
        if (!response.ok) {
          throw new Error('Failed to fetch courses');
        }

        const data = await response.json();
        setCourses(data);
      }
      catch (error) {
        console.error('Error fetching courses:', error);
        setError('Failed to load courses. Please try again later.');
      }
      finally {
        setIsLoading(false);
      }
    }

    fetchCourses();
  }, []);

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 text-red-800 p-4 rounded-md">
        <p>{error}</p>
      </div>
    );
  }

  if (courses.length === 0 && !isLoading) {
    return (
      <div className="bg-blue-50 border border-blue-200 text-blue-800 p-4 rounded-md">
        <p>No courses available at the moment.</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {courses.map(course => (
        <Link href={`/courses/${course.id}`} key={course.id} className="block">
          <div className="bg-white border rounded-lg overflow-hidden shadow-sm hover:shadow-md transition-shadow">
            <div className="p-4">
              <h2 className="text-xl font-semibold mb-2">{course.name}</h2>
              <p className="text-gray-600 line-clamp-2">{course.description || 'No description available'}</p>
              <div className="mt-4 flex justify-between items-center">
                <span className="text-sm text-gray-500">{course.professorName || 'No professor assigned'}</span>
                <span className="bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded">View details</span>
              </div>
            </div>
          </div>
        </Link>
      ))}
    </div>
  );
}
