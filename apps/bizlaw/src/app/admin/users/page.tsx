import { Metadata } from 'next';
import { getServerSession } from 'next-auth/next';

import { authOptions } from '@/lib/auth/auth';
import { redirect } from 'next/navigation';
import UserManagement from '@/components/admin/UserManagement';

export const metadata: Metadata = {
  title: 'User Management | Admin',
  description: 'Manage system users, roles and permissions',
};

export default async function AdminUsersPage() {
  // Check auth server-side
  const session = await getServerSession(authOptions);

  // If not logged in, redirect to login
  if (!session?.user) {
    redirect('/auth/signin?callbackUrl=/admin/users');
  }

  // If not admin, redirect to home
  if (session.user.role !== 'admin') {
    redirect('/');
  }

  return (
    <div className="container mx-auto py-8">
      <h1 className="text-3xl font-bold mb-6">User Management</h1>
      <UserManagement />
    </div>
  );
}
