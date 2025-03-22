import { Metadata } from 'next';
import { getServerSession } from 'next-auth/next';
import { redirect } from 'next/navigation';
import { authOptions } from '@/lib/auth/auth';
import CaseForm from '@/components/admin/CaseForm';

export const metadata: Metadata = {
  title: 'Create Case | Admin',
  description: 'Create a new legal case simulation',
};

export default async function CreateCasePage() {
  // Check auth server-side
  const session = await getServerSession(authOptions);

  // If not logged in, redirect to login
  if (!session?.user) {
    redirect('/auth/signin?callbackUrl=/admin/cases/new');
  }

  // If not admin or professor, redirect to home
  if (!['admin', 'professor'].includes(session.user.role ?? '')) {
    redirect('/');
  }

  return (
    <div className="container mx-auto py-8">
      <h1 className="text-3xl font-bold mb-6">Create New Case</h1>
      <CaseForm />
    </div>
  );
}
