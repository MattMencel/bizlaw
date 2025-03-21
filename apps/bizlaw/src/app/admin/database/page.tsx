import { Metadata } from 'next';
import DatabaseDashboard from '@/components/admin/DatabaseDashboard';

export const metadata: Metadata = {
  title: 'Database Management',
  description: 'Manage your database schema and migrations',
};

export default function DatabasePage() {
  return (
    <div className="container mx-auto py-8 px-4">
      <DatabaseDashboard />
    </div>
  );
}
