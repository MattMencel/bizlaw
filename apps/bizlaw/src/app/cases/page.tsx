import { Suspense } from 'react';
import { Metadata } from 'next';
import { getServerSession } from 'next-auth/next';
import { redirect } from 'next/navigation';
import { eq } from 'drizzle-orm';

import { authOptions } from '@/lib/auth/auth';
import { getDb } from '@/lib/db/db';
import { cases, CaseStatus } from '@/lib/db/schema';
import CaseListing from '@/components/cases/CaseListing';
import CasesList from '@/components/cases/CasesList';
import CasesListSkeleton from '@/components/cases/CasesListSkeleton';

export const metadata: Metadata = {
  title: 'Case Library | Business Law',
  description: 'Browse and access available legal case simulations',
};

export default async function CasesPage() {
  // Check auth server-side
  const session = await getServerSession(authOptions);

  // If not logged in, redirect to login
  if (!session?.user) {
    redirect('/auth/signin?callbackUrl=/cases');
  }

  // Fetch case data based on user role
  const db = getDb();
  const isInstructor = ['professor', 'admin'].includes(session.user.role ?? '');

  let availableCases;
  if (isInstructor) {
    // Instructors can see all cases
    availableCases = await db.select().from(cases).orderBy(cases.createdAt);
  } else {
    // Students can only see published cases
    availableCases = await db
      .select()
      .from(cases)
      .where(eq(cases.status, CaseStatus.PUBLISHED))
      .orderBy(cases.createdAt);
  }

  return (
    <div className="container mx-auto py-8 px-4">
      <h1 className="text-3xl font-bold mb-2">Case Library</h1>
      <p className="text-gray-600 mb-8">Browse through available legal case simulations</p>

      <CaseListing cases={availableCases} userRole={session.user.role || 'student'} />
    </div>
  );
}
