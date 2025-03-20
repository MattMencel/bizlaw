'use client';

import Link from 'next/link';
import { useState, useEffect } from 'react';

import type { Case } from '@/lib/db/schema';

export default function CasesList() {
  const [cases, setCases] = useState<Case[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchCases() {
      try {
        const response = await fetch('/api/cases');
        if (!response.ok) {
          throw new Error('Failed to fetch cases');
        }

        const data = await response.json();
        setCases(data);
      }
      catch (error) {
        console.error('Error fetching cases:', error);
        setError('Failed to load cases. Please try again later.');
      }
      finally {
        setIsLoading(false);
      }
    }

    fetchCases();
  }, []);

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 text-red-800 p-4 rounded-md">
        <p>{error}</p>
      </div>
    );
  }

  if (cases.length === 0 && !isLoading) {
    return (
      <div className="bg-blue-50 border border-blue-200 text-blue-800 p-4 rounded-md">
        <p>No cases available at the moment.</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {cases.map(caseItem => (
        <Link href={`/cases/${caseItem.id}`} key={caseItem.id} className="block">
          <div className="bg-white border rounded-lg overflow-hidden shadow-sm hover:shadow-md transition-shadow">
            <div className="p-4">
              <h2 className="text-xl font-semibold mb-2">{caseItem.title}</h2>
              <p className="text-gray-600 line-clamp-2">{caseItem.description || 'No description available'}</p>
              <div className="mt-4 flex justify-between items-center">
                <span className="text-sm text-gray-500">{caseItem.active ? 'Active' : 'Inactive'}</span>
                <span className="bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded">View details</span>
              </div>
            </div>
          </div>
        </Link>
      ))}
    </div>
  );
}
