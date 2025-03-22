import { Metadata } from 'next';
import { getServerSession } from 'next-auth/next';
import { notFound, redirect } from 'next/navigation';
import Link from 'next/link';
import { FiArrowLeft } from 'react-icons/fi';

import { authOptions } from '@/lib/auth/auth';
import { getDb } from '@/lib/db/db';
import { cases, caseDetails } from '@/lib/db/schema';
import { eq } from 'drizzle-orm';
import CaseDetailsForm from '@/components/admin/CaseDetailsForm';

// Update metadata function to handle Promise params
export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const { id } = await params;
  const db = getDb();
  // Convert string id to number
  const numericId = parseInt(id, 10);

  const [caseData] = await db.select().from(cases).where(eq(cases.id, numericId));

  if (!caseData) {
    return {
      title: 'Case Not Found',
    };
  }

  return {
    title: `Case Details: ${caseData.title} | Admin`,
    description: `Manage case details for ${caseData.title}`,
  };
}

// Update page component to handle Promise params
export default async function CaseDetailsPage({ params }: { params: Promise<{ id: string }> }) {
  // Await the params promise
  const { id } = await params;

  // Check auth server-side
  const session = await getServerSession(authOptions);

  // If not logged in, redirect to login
  if (!session?.user) {
    redirect(`/auth/signin?callbackUrl=/admin/cases/${id}/details`);
  }

  // If not admin or professor, redirect to home
  if (!['admin', 'professor'].includes(session.user.role ?? '')) {
    redirect('/');
  }

  // Convert string id to number
  const numericId = parseInt(id, 10);

  // Fetch case data
  const db = getDb();
  const [caseData] = await db.select().from(cases).where(eq(cases.id, numericId));

  if (!caseData) {
    notFound();
  }

  // Fetch case details - also use numeric ID
  const [details] = await db.select().from(caseDetails).where(eq(caseDetails.caseId, numericId));

  // Convert the jsonb fields to strings for the component
  const formattedDetails = details
    ? {
        ...details,
        // Convert caseId to string to match expected type
        caseId: details.caseId.toString(),
        plaintiffInfo:
          typeof details.plaintiffInfo === 'string' ? details.plaintiffInfo : JSON.stringify(details.plaintiffInfo),
        defendantInfo:
          typeof details.defendantInfo === 'string' ? details.defendantInfo : JSON.stringify(details.defendantInfo),
        legalIssues:
          typeof details.legalIssues === 'string' ? details.legalIssues : JSON.stringify(details.legalIssues),
        relevantLaws:
          typeof details.relevantLaws === 'string' ? details.relevantLaws : JSON.stringify(details.relevantLaws),
        timeline: typeof details.timeline === 'string' ? details.timeline : JSON.stringify(details.timeline),
      }
    : undefined;

  return (
    <div className="container mx-auto py-8">
      <Link href={`/admin/cases/${id}`} className="inline-flex items-center text-blue-600 hover:text-blue-800 mb-6">
        <FiArrowLeft className="mr-2" /> Back to Case
      </Link>

      <h1 className="text-3xl font-bold mb-2">{caseData.title}</h1>
      <p className="text-gray-600 mb-8">
        Ref: {caseData.referenceNumber} | Type: {caseData.caseType.replace(/_/g, ' ')}
      </p>

      <CaseDetailsForm caseId={id} initialData={formattedDetails} />
    </div>
  );
}
