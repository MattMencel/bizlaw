'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { CaseType, CaseStatus } from '@/lib/db/schema'; // Import from root schema

interface CaseFormProps {
  initialData?: any;
  isEditing?: boolean;
}

export default function CaseForm({ initialData, isEditing = false }: CaseFormProps) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [formData, setFormData] = useState({
    title: initialData?.title || '',
    caseType: initialData?.caseType || CaseType.SEXUAL_HARASSMENT,
    description: initialData?.description || '',
    summary: initialData?.summary || '',
    status: initialData?.status || CaseStatus.DRAFT,
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const url = isEditing ? `/api/cases/${initialData.id}` : '/api/cases';
      const method = isEditing ? 'PATCH' : 'POST';

      const response = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to save case');
      }

      const savedCase = await response.json();

      // Navigate to the edit page if we just created a new case
      if (!isEditing) {
        router.push(`/admin/cases/${savedCase.id}`);
      } else {
        // Refresh the page to show updated data
        router.refresh();
      }
    } catch (err) {
      console.error('Error saving case:', err);
      setError(err instanceof Error ? err.message : 'An unknown error occurred');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="bg-white rounded-lg shadow-md p-6">
      {error && (
        <div className="bg-red-50 border-l-4 border-red-500 p-4 mb-6 text-red-700">
          <p>{error}</p>
        </div>
      )}

      <div className="mb-6">
        <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-1">
          Case Title <span className="text-red-500">*</span>
        </label>
        <input
          type="text"
          id="title"
          name="title"
          value={formData.title}
          onChange={handleChange}
          required
          className="block w-full rounded-md border border-gray-300 py-2 px-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      <div className="mb-6">
        <label htmlFor="caseType" className="block text-sm font-medium text-gray-700 mb-1">
          Case Type <span className="text-red-500">*</span>
        </label>
        <select
          id="caseType"
          name="caseType"
          value={formData.caseType}
          onChange={handleChange}
          required
          className="block w-full rounded-md border border-gray-300 py-2 px-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value={CaseType.SEXUAL_HARASSMENT}>Sexual Harassment</option>
          <option value={CaseType.DISCRIMINATION}>Discrimination</option>
          <option value={CaseType.WRONGFUL_TERMINATION}>Wrongful Termination</option>
          <option value={CaseType.CONTRACT_DISPUTE}>Contract Dispute</option>
          <option value={CaseType.INTELLECTUAL_PROPERTY}>Intellectual Property</option>
        </select>
      </div>

      <div className="mb-6">
        <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-1">
          Description
        </label>
        <textarea
          id="description"
          name="description"
          value={formData.description || ''}
          onChange={handleChange}
          rows={3}
          className="block w-full rounded-md border border-gray-300 py-2 px-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      <div className="mb-6">
        <label htmlFor="summary" className="block text-sm font-medium text-gray-700 mb-1">
          Summary
        </label>
        <textarea
          id="summary"
          name="summary"
          value={formData.summary || ''}
          onChange={handleChange}
          rows={5}
          className="block w-full rounded-md border border-gray-300 py-2 px-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      {isEditing && (
        <div className="mb-6">
          <label htmlFor="status" className="block text-sm font-medium text-gray-700 mb-1">
            Status
          </label>
          <select
            id="status"
            name="status"
            value={formData.status}
            onChange={handleChange}
            className="block w-full rounded-md border border-gray-300 py-2 px-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value={CaseStatus.DRAFT}>Draft</option>
            <option value={CaseStatus.PUBLISHED}>Published</option>
            <option value={CaseStatus.ARCHIVED}>Archived</option>
          </select>
        </div>
      )}

      <div className="flex justify-end mt-8 space-x-4">
        <button
          type="button"
          onClick={() => router.back()}
          className="py-2 px-4 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
        >
          Cancel
        </button>
        <button
          type="submit"
          disabled={loading}
          className={`py-2 px-4 rounded-md text-sm font-medium text-white ${
            loading ? 'bg-blue-400' : 'bg-blue-600 hover:bg-blue-700'
          }`}
        >
          {loading ? 'Saving...' : isEditing ? 'Update Case' : 'Create Case'}
        </button>
      </div>
    </form>
  );
}
