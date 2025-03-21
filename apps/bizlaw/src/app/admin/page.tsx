import { Metadata } from 'next';
import Link from 'next/link';
import { Database, Users, FileText, Settings } from 'lucide-react';

export const metadata: Metadata = {
  title: 'Admin Dashboard',
  description: 'Administrative dashboard for Business Law application',
};

export default function AdminPage() {
  return (
    <div className="container mx-auto py-8 px-4">
      <h1 className="text-3xl font-bold mb-8">Admin Dashboard</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Link href="/admin/database" className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
          <Database className="h-8 w-8 text-indigo-600 mb-4" />
          <h2 className="text-lg font-semibold mb-2">Database Management</h2>
          <p className="text-gray-600 text-sm">Manage database schema and run migrations</p>
        </Link>

        <Link href="/admin/users" className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
          <Users className="h-8 w-8 text-green-600 mb-4" />
          <h2 className="text-lg font-semibold mb-2">User Management</h2>
          <p className="text-gray-600 text-sm">Manage users, permissions and roles</p>
        </Link>

        <Link href="/admin/cases" className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
          <FileText className="h-8 w-8 text-amber-600 mb-4" />
          <h2 className="text-lg font-semibold mb-2">Case Management</h2>
          <p className="text-gray-600 text-sm">Manage legal cases and documents</p>
        </Link>

        <Link href="/admin/settings" className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
          <Settings className="h-8 w-8 text-gray-600 mb-4" />
          <h2 className="text-lg font-semibold mb-2">Settings</h2>
          <p className="text-gray-600 text-sm">Configure application settings</p>
        </Link>
      </div>
    </div>
  );
}
