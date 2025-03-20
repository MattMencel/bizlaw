'use client';

import { useRouter } from 'next/navigation';
import { useRef, useState } from 'react';

import { createCaseAction, updateCaseAction } from '@/app/actions/cases';
import type { Case } from '@/lib/types/api';

interface CaseFormServerActionProps {
  initialValues?: Partial<Case>
  caseId?: number
  onSuccess?: () => void
}

export function CaseFormServerAction({ initialValues = {}, caseId, onSuccess }: CaseFormServerActionProps) {
  const router = useRouter();
  const formRef = useRef<HTMLFormElement>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError(null);

    try {
      const formData = new FormData(e.currentTarget);
      let result;

      if (caseId) {
        result = await updateCaseAction(caseId, formData);
      }
      else {
        result = await createCaseAction(formData);
      }

      if (!result.success) {
        setError(result.error);
        return;
      }

      if (onSuccess) {
        onSuccess();
      }
      else {
        router.push(`/cases/${result.data.id}`);
        router.refresh();
      }

      if (formRef.current) {
        formRef.current.reset();
      }
    }
    catch (err) {
      setError(err instanceof Error ? err.message : 'An unknown error occurred');
    }
    finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form ref={formRef} onSubmit={handleSubmit} className="space-y-6">
      {error && (
        <div className="rounded-md bg-red-50 p-4">
          <div className="flex">
            <div className="ml-3">
              <h3 className="text-sm font-medium text-red-800">Error</h3>
              <div className="mt-2 text-sm text-red-700">{error}</div>
            </div>
          </div>
        </div>
      )}

      <div>
        <label htmlFor="title" className="block text-sm font-medium text-gray-700">
          Title
        </label>
        <input
          id="title"
          name="title"
          type="text"
          defaultValue={initialValues.title || ''}
          className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          required
        />
      </div>

      <div>
        <label htmlFor="description" className="block text-sm font-medium text-gray-700">
          Description
        </label>
        <textarea
          id="description"
          name="description"
          rows={4}
          defaultValue={initialValues.description || ''}
          className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
        />
      </div>

      <div className="flex items-center">
        <input
          id="active"
          name="active"
          type="checkbox"
          defaultChecked={initialValues.active !== false}
          className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
        />
        <label htmlFor="active" className="ml-2 block text-sm text-gray-700">
          Active
        </label>
      </div>

      <div className="flex justify-end">
        <button
          type="button"
          onClick={() => router.back()}
          className="mr-3 rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
          disabled={isSubmitting}
        >
          Cancel
        </button>
        <button
          type="submit"
          disabled={isSubmitting}
          className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50"
        >
          {isSubmitting ? 'Saving...' : caseId ? 'Update Case' : 'Create Case'}
        </button>
      </div>
    </form>
  );
}
