'use client';

import { useRouter } from 'next/navigation';
import { z } from 'zod';

import { ZodForm } from '@/components/forms/ZodForm';
import { useCreateCase, useUpdateCase } from '@/lib/hooks/api';

// Define schema
const caseFormSchema = z.object({
  title: z.string().min(3, 'Title must be at least 3 characters').max(100),
  description: z.string().max(1000).optional(),
  active: z.boolean().default(true),
});

// Inferred type
type CaseFormData = z.infer<typeof caseFormSchema>;

interface CaseFormProps {
  initialValues?: Partial<CaseFormData>
  caseId?: number
  onSuccess?: () => void
}

export function CaseForm({ initialValues = {}, caseId, onSuccess }: CaseFormProps) {
  const router = useRouter();
  const { createCase, isLoading: isCreating } = useCreateCase();
  const { updateCase, isLoading: isUpdating } = useUpdateCase();

  const isSubmitting = isCreating || isUpdating;

  const handleSubmit = async (values: CaseFormData) => {
    try {
      if (caseId) {
        await updateCase(caseId, values);
      }
      else {
        await createCase(values);
      }

      // Handle success
      if (onSuccess) {
        onSuccess();
      }
      else {
        router.push('/cases');
        router.refresh();
      }
    }
    catch (error) {
      console.error('Failed to save case:', error);
    }
  };

  return (
    <ZodForm schema={caseFormSchema} initialValues={initialValues} onSubmit={handleSubmit}>
      {({ values, errors, isSubmitting, handleChange, handleSubmit }) => (
        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label htmlFor="title" className="block text-sm font-medium text-gray-700">
              Title
            </label>
            <input
              id="title"
              type="text"
              value={values.title || ''}
              onChange={handleChange('title')}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.title && <p className="mt-1 text-sm text-red-600">{errors.title.join(', ')}</p>}
          </div>

          <div>
            <label htmlFor="description" className="block text-sm font-medium text-gray-700">
              Description
            </label>
            <textarea
              id="description"
              value={values.description || ''}
              onChange={handleChange('description')}
              rows={4}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.description && <p className="mt-1 text-sm text-red-600">{errors.description.join(', ')}</p>}
          </div>

          <div className="flex items-center">
            <input
              id="active"
              type="checkbox"
              checked={values.active ?? true}
              onChange={handleChange('active')}
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
      )}
    </ZodForm>
  );
}
