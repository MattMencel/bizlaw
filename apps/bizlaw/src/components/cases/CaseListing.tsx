'use client';

import { useState } from 'react';
import Link from 'next/link';
import { FiSearch, FiFilter, FiFileText, FiChevronRight } from 'react-icons/fi';
import { CaseType, CaseStatus } from '@/lib/db/schema';
import React from 'react';
import type { Case } from '@/lib/db/schema';

interface CaseListingProps {
  cases: Case[];
  userRole?: string;
}

export default function CaseListing({ cases, userRole = 'student' }: CaseListingProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState<string>('all');

  const isInstructor = ['professor', 'admin'].includes(userRole);

  // Filter cases based on search query and type filter
  const filteredCases = cases.filter(caseItem => {
    const matchesSearch =
      searchQuery === '' ||
      caseItem.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (caseItem.description && caseItem.description.toLowerCase().includes(searchQuery.toLowerCase())) ||
      caseItem.referenceNumber.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesType = typeFilter === 'all' || caseItem.caseType === typeFilter;

    return matchesSearch && matchesType;
  });

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <div className="flex flex-wrap justify-between items-center mb-6">
        <div className="relative w-full md:w-64 mb-4 md:mb-0">
          <div className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
            <FiSearch className="text-gray-400" />
          </div>
          <input
            type="text"
            className="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg block w-full pl-10 p-2.5"
            placeholder="Search cases..."
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
          />
        </div>

        <div className="flex items-center">
          <FiFilter className="mr-2 text-gray-600" />
          <select
            className="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg p-2.5"
            value={typeFilter}
            onChange={e => setTypeFilter(e.target.value)}
          >
            <option value="all">All Types</option>
            <option value={CaseType.SEXUAL_HARASSMENT}>Sexual Harassment</option>
            <option value={CaseType.DISCRIMINATION}>Discrimination</option>
            <option value={CaseType.WRONGFUL_TERMINATION}>Wrongful Termination</option>
            <option value={CaseType.CONTRACT_DISPUTE}>Contract Dispute</option>
            <option value={CaseType.INTELLECTUAL_PROPERTY}>Intellectual Property</option>
          </select>
        </div>
      </div>

      {filteredCases.length === 0 ? (
        <div className="py-12 text-center text-gray-500">
          <FiFileText className="mx-auto h-12 w-12 mb-4" />
          <h3 className="text-lg font-medium">No cases found</h3>
          <p className="mt-2">Try adjusting your search or filter criteria</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredCases.map(caseItem => (
            <Link href={`/cases/${caseItem.id}`} key={caseItem.id}>
              <div className="border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow cursor-pointer">
                <h3 className="text-lg font-semibold mb-2">{caseItem.title}</h3>
                <div className="mb-3">
                  <span className="inline-block bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded-full capitalize">
                    {caseItem.caseType.replace(/_/g, ' ').toLowerCase()}
                  </span>
                  {isInstructor && (
                    <span
                      className={`inline-block ml-2 text-xs px-2 py-1 rounded-full ${
                        caseItem.status === 'published'
                          ? 'bg-green-100 text-green-800'
                          : 'bg-yellow-100 text-yellow-800'
                      }`}
                    >
                      {caseItem.status}
                    </span>
                  )}
                </div>
                {caseItem.summary && <p className="text-gray-600 text-sm mb-4 line-clamp-2">{caseItem.summary}</p>}
                <div className="flex justify-between items-center mt-4 text-sm text-gray-500">
                  <span>Ref: {caseItem.referenceNumber}</span>
                  <FiChevronRight />
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
