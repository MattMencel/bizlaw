'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

interface CaseDetails {
  caseId: string; // Changed from number to string
  plaintiffInfo?: string | null;
  defendantInfo?: string | null;
  legalIssues?: string | null;
  relevantLaws?: string | null;
  timeline?: string | null;
  teachingNotes?: string | null;
  assignmentDetails?: string | null;
}

interface CaseDetailsFormProps {
  caseId: string; // Changed from number to string
  initialData?: CaseDetails;
}

export default function CaseDetailsForm({ caseId, initialData }: CaseDetailsFormProps) {
  const router = useRouter();
  const [formData, setFormData] = useState<Partial<CaseDetails>>({
    plaintiffInfo: initialData?.plaintiffInfo || '',
    defendantInfo: initialData?.defendantInfo || '',
    legalIssues: initialData?.legalIssues || '',
    relevantLaws: initialData?.relevantLaws || '',
    timeline: initialData?.timeline || '',
    teachingNotes: initialData?.teachingNotes || '',
    assignmentDetails: initialData?.assignmentDetails || '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    setSaved(false);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const response = await fetch(`/api/cases/${caseId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ details: formData }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to update case details');
      }

      setSaved(true);
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unknown error occurred');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <h2 className="text-xl font-semibold mb-6">Case Details</h2>

      {error && (
        <div className="bg-red-50 border-l-4 border-red-500 p-4 mb-6 text-red-700">
          <p>{error}</p>
        </div>
      )}

      {saved && (
        <div className="bg-green-50 border-l-4 border-green-500 p-4 mb-6 text-green-700">
          <p>Case details saved successfully!</p>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label htmlFor="plaintiffInfo" className="block text-sm font-medium text-gray-700 mb-1">
            Plaintiff Information
          </label>
          <textarea
            id="plaintiffInfo"
            name="plaintiffInfo"
            rows={4}
            value={formData.plaintiffInfo || ''}
            onChange={handleChange}
            className="w-full border border-gray-300 rounded-md shadow-sm px-4 py-2"
          />
        </div>

        <div>
          <label htmlFor="defendantInfo" className="block text-sm font-medium text-gray-700 mb-1">
            Defendant Information
          </label>
          <textarea
            id="defendantInfo"
            name="defendantInfo"
            rows={4}
            value={formData.defendantInfo || ''}
            onChange={handleChange}
            className="w-full border border-gray-300 rounded-md shadow-sm px-4 py-2"
          />
        </div>

        <div>
          <label htmlFor="legalIssues" className="block text-sm font-medium text-gray-700 mb-1">
            Legal Issues
          </label>
          <textarea
            id="legalIssues"
            name="legalIssues"
            rows={4}
            value={formData.legalIssues || ''}
            onChange={handleChange}
            className="w-full border border-gray-300 rounded-md shadow-sm px-4 py-2"
          />
        </div>

        <div>
          <label htmlFor="relevantLaws" className="block text-sm font-medium text-gray-700 mb-1">
            Relevant Laws
          </label>
          <textarea
            id="relevantLaws"
            name="relevantLaws"
            rows={4}
            value={formData.relevantLaws || ''}
            onChange={handleChange}
            className="w-full border border-gray-300 rounded-md shadow-sm px-4 py-2"
          />
        </div>

        <div>
          <label htmlFor="timeline" className="block text-sm font-medium text-gray-700 mb-1">
            Timeline
          </label>
          <textarea
            id="timeline"
            name="timeline"
            rows={4}
            value={formData.timeline || ''}
            onChange={handleChange}
            className="w-full border border-gray-300 rounded-md shadow-sm px-4 py-2"
          />
        </div>

        <div>
          <label htmlFor="teachingNotes" className="block text-sm font-medium text-gray-700 mb-1">
            Teaching Notes
          </label>
          <textarea
            id="teachingNotes"
            name="teachingNotes"
            rows={4}
            value={formData.teachingNotes || ''}
            onChange={handleChange}
            className="w-full border border-gray-300 rounded-md shadow-sm px-4 py-2"
          />
        </div>

        <div>
          <label htmlFor="assignmentDetails" className="block text-sm font-medium text-gray-700 mb-1">
            Assignment Details
          </label>
          <textarea
            id="assignmentDetails"
            name="assignmentDetails"
            rows={4}
            value={formData.assignmentDetails || ''}
            onChange={handleChange}
            className="w-full border border-gray-300 rounded-md shadow-sm px-4 py-2"
          />
        </div>

        <div className="flex justify-end">
          <button
            type="submit"
            disabled={loading}
            className={`px-4 py-2 rounded-md text-white ${loading ? 'bg-blue-400' : 'bg-blue-600 hover:bg-blue-700'}`}
          >
            {loading ? 'Saving...' : 'Save Details'}
          </button>
        </div>
      </form>
    </div>
  );
}
