import { Metadata } from 'next';
import { getServerSession } from 'next-auth/next';
import { redirect } from 'next/navigation';

import { authOptions } from '@/lib/auth/auth';
import CaseManagement from '@/components/admin/CaseManagement';

export const metadata: Metadata = {
  title: 'Case Management | Admin',
  description: 'Manage legal case simulations',
};

export default async function AdminCasesPage() {
  // Check auth server-side
  const session = await getServerSession(authOptions);

  // If not logged in, redirect to login
  if (!session?.user) {
    redirect('/auth/signin?callbackUrl=/admin/cases');
  }

  // If not admin or professor, redirect to home
  if (!['admin', 'professor'].includes(session.user.role ?? '')) {
    redirect('/');
  }

  return (
    <div className="container mx-auto py-8">
      <h1 className="text-3xl font-bold mb-6">Case Management</h1>
      <CaseManagement />
    </div>
  );
}
