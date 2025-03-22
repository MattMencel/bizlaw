import { Metadata } from 'next';
import { getServerSession } from 'next-auth/next';
import { notFound, redirect } from 'next/navigation';

import { authOptions } from '@/lib/auth/auth';
import { getDb } from '@/lib/db/db';
import { cases } from '@/lib/db/schema';
import { eq } from 'drizzle-orm';
import CaseForm from '@/components/admin/CaseForm';

// Updated Metadata with Promise-based params
export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  // Await the params promise
  const { id } = await params;

  // Convert string id to number
  const numericId = parseInt(id, 10);

  const db = getDb();
  const [caseData] = await db.select().from(cases).where(eq(cases.id, numericId));

  if (!caseData) {
    return {
      title: 'Case Not Found',
    };
  }

  return {
    title: `Edit: ${caseData.title} | Admin`,
    description: `Edit case: ${caseData.title}`,
  };
}

// Updated page component with Promise-based params
export default async function EditCasePage({ params }: { params: Promise<{ id: string }> }) {
  // Await the params promise
  const { id } = await params;

  // Convert string id to number
  const numericId = parseInt(id, 10);

  // Check auth server-side
  const session = await getServerSession(authOptions);

  // If not logged in, redirect to login
  if (!session?.user) {
    redirect(`/auth/signin?callbackUrl=/admin/cases/${id}`);
  }

  // If not admin or professor, redirect to home
  if (!['admin', 'professor'].includes(session.user.role ?? '')) {
    redirect('/');
  }

  // Fetch case data
  const db = getDb();
  const [caseData] = await db.select().from(cases).where(eq(cases.id, numericId));

  if (!caseData) {
    notFound();
  }

  return (
    <div className="container mx-auto py-8">
      <h1 className="text-3xl font-bold mb-6">Edit Case</h1>
      <p className="text-gray-600 mb-6">
        Reference: <span className="font-semibold">{caseData.referenceNumber}</span>
      </p>
      <CaseForm initialData={caseData} isEditing={true} />
    </div>
  );
}
