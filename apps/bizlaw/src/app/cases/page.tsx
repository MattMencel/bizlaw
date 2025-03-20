import { Suspense } from 'react';

import CasesList from '@/components/cases/CasesList';
import CasesListSkeleton from '@/components/cases/CasesListSkeleton';

export const metadata = {
  title: 'Cases | Business Law',
};

export default function CasesPage() {
  return (
    <div className="container mx-auto py-8">
      <h1 className="text-3xl font-bold mb-6">Legal Cases</h1>
      <Suspense fallback={<CasesListSkeleton />}>
        <CasesList />
      </Suspense>
    </div>
  );
}
