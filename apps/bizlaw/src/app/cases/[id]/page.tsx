import { Metadata } from 'next';
import { getServerSession } from 'next-auth/next';
import { notFound, redirect } from 'next/navigation';
import { eq } from 'drizzle-orm';

import { authOptions } from '@/lib/auth/auth';
import { initDb, getDb } from '@/lib/db/db';
import {
  cases,
  caseDetails as caseDetailsTable,
  caseDocuments as caseDocumentsTable,
  CaseStatus,
} from '@/lib/db/schema';
import CaseView from '@/components/cases/CaseView';
import { toNumericId } from '@/lib/utils';

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  try {
    const { id } = await params;
    const numericId = toNumericId(id);

    await initDb();
    const db = getDb();
    const [caseData] = await db.select().from(cases).where(eq(cases.id, numericId));

    if (!caseData) {
      return {
        title: 'Case Not Found',
      };
    }

    return {
      title: `${caseData.title} | Business Law`,
      description: caseData.description || `Details for case: ${caseData.title}`,
    };
  } catch (error) {
    console.error('Error generating metadata:', error);
    return {
      title: 'Case Details',
      description: 'View case details',
    };
  }
}

export default async function CaseDetailPage({ params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const numericId = toNumericId(id);

    // Check auth server-side
    const session = await getServerSession(authOptions);

    // If not logged in, redirect to login
    if (!session?.user) {
      redirect(`/auth/signin?callbackUrl=/cases/${id}`);
    }

    await initDb();
    const db = getDb();

    // Get the case
    const [caseData] = await db.select().from(cases).where(eq(cases.id, numericId));

    if (!caseData) {
      notFound();
    }

    // Check access permissions
    const isInstructor = ['professor', 'admin'].includes(session.user.role ?? '');
    if (!isInstructor && caseData.status !== CaseStatus.PUBLISHED) {
      return (
        <div className="container mx-auto py-8">
          <div className="bg-yellow-50 border-l-4 border-yellow-500 p-4">
            <p className="font-medium">Access Restricted</p>
            <p>This case is not yet published and is only available to instructors.</p>
          </div>
        </div>
      );
    }

    // Fetch case details and documents - use different variable names
    const [details] = await db.select().from(caseDetailsTable).where(eq(caseDetailsTable.caseId, numericId));

    const documents = await db.select().from(caseDocumentsTable).where(eq(caseDocumentsTable.caseId, numericId));

    const caseWithDetails = {
      ...caseData,
      details: details || undefined,
      documents: documents || [],
    };

    return <CaseView caseData={caseWithDetails} userRole={session.user.role || 'student'} />;
  } catch (error) {
    console.error('Error loading case:', error);
    return (
      <div className="container mx-auto py-8">
        <div className="bg-red-50 border-l-4 border-red-500 p-4">
          <p className="font-medium">Error</p>
          <p>There was a problem loading this case. Please try again later.</p>
        </div>
      </div>
    );
  }
}
