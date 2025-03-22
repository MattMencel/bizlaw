'use client';

import { useState, useEffect } from 'react';
import { useSession } from 'next-auth/react';
import Link from 'next/link';
import { FiPlus, FiEdit, FiTrash2, FiFileText, FiEye, FiArrowRight } from 'react-icons/fi';
import { CaseStatus, CaseType } from '@/lib/db/schema';

interface Case {
  id: string;
  title: string;
  referenceNumber: string;
  caseType: string;
  status: string;
  description?: string;
  createdAt: string;
  updatedAt: string;
}

export default function CaseManagement() {
  const { data: session } = useSession();
  const [cases, setCases] = useState<Case[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');

  const isAdmin = session?.user?.role === 'admin';

  // Fetch cases on component mount
  useEffect(() => {
    fetchCases();
  }, []);

  async function fetchCases() {
    try {
      setLoading(true);
      setError(null);
      const response = await fetch('/api/cases');

      if (!response.ok) {
        throw new Error(`Failed to fetch cases: ${response.statusText}`);
      }

      const data = await response.json();
      setCases(data);
    } catch (err) {
      console.error('Error fetching cases:', err);
      setError('Failed to load cases');
    } finally {
      setLoading(false);
    }
  }

  async function deleteCase(id: string) {
    if (!confirm('Are you sure you want to delete this case? This action cannot be undone.')) {
      return;
    }

    try {
      setError(null);
      const response = await fetch(`/api/cases/${id}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        throw new Error(`Failed to delete case: ${response.statusText}`);
      }

      // Remove case from state
      setCases(cases.filter(c => c.id !== id));
    } catch (err) {
      console.error('Error deleting case:', err);
      setError('Failed to delete case');
    }
  }

  async function updateCaseStatus(id: string, newStatus: string) {
    try {
      setError(null);
      const response = await fetch(`/api/cases/${id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ status: newStatus }),
      });

      if (!response.ok) {
        throw new Error(`Failed to update case: ${response.statusText}`);
      }

      const updatedCase = await response.json();

      // Update local state
      setCases(cases.map(c => (c.id === id ? { ...c, status: updatedCase.status } : c)));
    } catch (err) {
      console.error('Error updating case:', err);
      setError('Failed to update case status');
    }
  }

  // Filter cases based on filters and search query
  const filteredCases = cases.filter(caseItem => {
    const matchesStatus = statusFilter === 'all' || caseItem.status === statusFilter;
    const matchesType = typeFilter === 'all' || caseItem.caseType === typeFilter;
    const matchesSearch =
      searchQuery.trim() === '' ||
      caseItem.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      caseItem.referenceNumber.toLowerCase().includes(searchQuery.toLowerCase());

    return matchesStatus && matchesType && matchesSearch;
  });

  if (loading) {
    return (
      <div className="flex justify-center items-center py-12">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      {error && (
        <div className="bg-red-50 border-l-4 border-red-500 p-4 mb-4 text-red-700">
          <p>{error}</p>
        </div>
      )}

      <div className="flex flex-wrap justify-between items-center mb-6">
        <Link
          href="/admin/cases/new"
          className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 transition-colors flex items-center"
        >
          <FiPlus className="mr-2" /> New Case
        </Link>

        <div className="mt-4 md:mt-0 w-full md:w-auto flex flex-wrap gap-4">
          <div>
            <input
              type="text"
              placeholder="Search cases..."
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
              className="border border-gray-300 rounded-md p-2 text-sm"
            />
          </div>
          <div>
            <select
              value={statusFilter}
              onChange={e => setStatusFilter(e.target.value)}
              className="border border-gray-300 rounded-md p-2 text-sm"
            >
              <option value="all">All Statuses</option>
              <option value={CaseStatus.DRAFT}>Draft</option>
              <option value={CaseStatus.PUBLISHED}>Published</option>
              <option value={CaseStatus.ARCHIVED}>Archived</option>
            </select>
          </div>
          <div>
            <select
              value={typeFilter}
              onChange={e => setTypeFilter(e.target.value)}
              className="border border-gray-300 rounded-md p-2 text-sm"
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
      </div>

      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th
                scope="col"
                className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Case
              </th>
              <th
                scope="col"
                className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Type
              </th>
              <th
                scope="col"
                className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Reference #
              </th>
              <th
                scope="col"
                className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Status
              </th>
              <th
                scope="col"
                className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {filteredCases.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-6 py-4 text-center text-gray-500">
                  {searchQuery || statusFilter !== 'all' || typeFilter !== 'all'
                    ? 'No cases match your search criteria'
                    : "No cases found. Click 'New Case' to create one."}
                </td>
              </tr>
            ) : (
              filteredCases.map(caseItem => (
                <tr key={caseItem.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{caseItem.title}</div>
                    <div className="text-xs text-gray-500">
                      Created: {new Date(caseItem.createdAt).toLocaleDateString()}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-500">{caseItem.caseType.replace(/_/g, ' ')}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-500">{caseItem.referenceNumber}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full
                      ${
                        caseItem.status === CaseStatus.PUBLISHED
                          ? 'bg-green-100 text-green-800'
                          : caseItem.status === CaseStatus.DRAFT
                            ? 'bg-yellow-100 text-yellow-800'
                            : 'bg-gray-100 text-gray-800'
                      }`}
                    >
                      {caseItem.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div className="flex space-x-3">
                      <Link href={`/admin/cases/${caseItem.id}`} className="text-blue-600 hover:text-blue-900">
                        <FiEdit className="h-5 w-5" title="Edit" />
                      </Link>

                      <Link href={`/cases/${caseItem.id}`} className="text-green-600 hover:text-green-900">
                        <FiEye className="h-5 w-5" title="View" />
                      </Link>

                      <Link
                        href={`/admin/cases/${caseItem.id}/documents`}
                        className="text-purple-600 hover:text-purple-900"
                      >
                        <FiFileText className="h-5 w-5" title="Documents" />
                      </Link>

                      {caseItem.status === CaseStatus.DRAFT && (
                        <button
                          onClick={() => updateCaseStatus(caseItem.id, CaseStatus.PUBLISHED)}
                          className="text-green-600 hover:text-green-900"
                          title="Publish"
                        >
                          <FiArrowRight className="h-5 w-5" />
                        </button>
                      )}

                      {isAdmin && (
                        <button
                          onClick={() => deleteCase(caseItem.id)}
                          className="text-red-600 hover:text-red-900"
                          title="Delete"
                        >
                          <FiTrash2 className="h-5 w-5" />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
