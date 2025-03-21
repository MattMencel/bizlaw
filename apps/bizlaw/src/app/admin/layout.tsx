import { Database, Users, FileText, Settings } from 'lucide-react';
import Link from 'next/link';

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen bg-gray-100">
      {/* Sidebar */}
      <div className="w-64 bg-white shadow-md">
        <div className="py-6 px-4 border-b">
          <h1 className="text-xl font-bold text-gray-800">Admin Panel</h1>
        </div>
        <nav className="py-4 px-2">
          <ul className="space-y-1">
            <li>
              <Link
                href="/admin/database"
                className="flex items-center px-4 py-2 text-gray-700 hover:bg-indigo-50 hover:text-indigo-700 rounded-md"
              >
                <Database className="h-5 w-5 mr-3" />
                Database
              </Link>
            </li>
            <li>
              <Link
                href="/admin/users"
                className="flex items-center px-4 py-2 text-gray-700 hover:bg-indigo-50 hover:text-indigo-700 rounded-md"
              >
                <Users className="h-5 w-5 mr-3" />
                Users
              </Link>
            </li>
            <li>
              <Link
                href="/admin/cases"
                className="flex items-center px-4 py-2 text-gray-700 hover:bg-indigo-50 hover:text-indigo-700 rounded-md"
              >
                <FileText className="h-5 w-5 mr-3" />
                Cases
              </Link>
            </li>
            <li>
              <Link
                href="/admin/settings"
                className="flex items-center px-4 py-2 text-gray-700 hover:bg-indigo-50 hover:text-indigo-700 rounded-md"
              >
                <Settings className="h-5 w-5 mr-3" />
                Settings
              </Link>
            </li>
          </ul>
        </nav>
      </div>

      {/* Main content */}
      <div className="flex-1">{children}</div>
    </div>
  );
}
