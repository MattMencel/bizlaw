import { Metadata } from 'next';
import { getServerSession } from 'next-auth/next';
import { redirect, notFound } from 'next/navigation';
import { eq } from 'drizzle-orm';

import { authOptions } from '@/lib/auth/auth';
import { getDb, initDb } from '@/lib/db/db';
import { cases, caseDocuments } from '@/lib/db/schema';
import DocumentManager from '@/components/admin/DocumentManagement';
import { dbToUiDocument } from '@/types/utils'; // Import the conversion utility
import { toNumericId } from '@/lib/utils'; // More consistent than parseInt

interface DocumentPageProps {
  params: Promise<{ id: string }>;
}

export async function generateMetadata({ params }: DocumentPageProps): Promise<Metadata> {
  try {
    // Await the params promise
    const { id } = await params;
    const numericId = toNumericId(id);

    await initDb();
    const db = getDb();
    const [caseData] = await db.select().from(cases).where(eq(cases.id, numericId));

    if (!caseData) {
      return {
        title: 'Case Not Found',
        description: 'The requested case could not be found',
      };
    }

    return {
      title: `Case Documents: ${caseData.title} | Admin`,
      description: `Manage documents for ${caseData.title}`,
    };
  } catch (error) {
    return {
      title: 'Case Documents',
      description: 'Manage case documents',
    };
  }
}

export default async function DocumentsPage({ params }: DocumentPageProps) {
  // Await the params promise
  const { id } = await params;

  // Convert string id to number
  const numericId = toNumericId(id);

  // Check auth server-side
  const session = await getServerSession(authOptions);

  // If not logged in, redirect to login
  if (!session?.user) {
    redirect(`/auth/signin?callbackUrl=/admin/cases/${id}/documents`);
  }

  // If not admin or professor, redirect to home
  if (!['admin', 'professor'].includes(session.user.role ?? '')) {
    redirect('/');
  }

  try {
    await initDb();
    const db = getDb();

    // Get the case - use numericId instead of id
    const [caseData] = await db.select().from(cases).where(eq(cases.id, numericId));

    if (!caseData) {
      notFound();
    }

    // Get case documents - also use numericId
    const rawDocuments = await db.select().from(caseDocuments).where(eq(caseDocuments.caseId, numericId));

    // Use the conversion utility to properly format documents for UI
    const documents = rawDocuments.map(dbToUiDocument);

    return (
      <div className="container mx-auto py-8 px-4">
        <h1 className="text-3xl font-bold mb-2">{caseData.title}</h1>
        <p className="text-gray-600 mb-6">Document Management</p>

        <DocumentManager caseId={id} documents={documents} />
      </div>
    );
  } catch (error) {
    console.error('Error loading documents:', error);
    return (
      <div className="container mx-auto py-8 px-4">
        <div className="bg-red-50 border-l-4 border-red-500 p-4 text-red-700">
          <p className="font-medium">Error</p>
          <p>Failed to load case documents. Please try again later.</p>
        </div>
      </div>
    );
  }
}
