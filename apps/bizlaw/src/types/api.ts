import type { Course } from '@/lib/db/schema';

export interface CourseResponse extends Course {
  professorName?: string | null
  // Any other API-specific fields
}
