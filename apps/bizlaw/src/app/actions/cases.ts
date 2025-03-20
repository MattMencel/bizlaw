'use server';

import { revalidatePath } from 'next/cache';
import { getServerSession } from 'next-auth';
import type { z } from 'zod'; // REMOVE the "type" keyword here

import { authOptions } from '@/lib/auth/auth';
import { initDb } from '@/lib/db/db';
import { createCase, updateCase, deleteCase, getCaseById } from '@/lib/db/queries';
import { newCaseSchema } from '@/lib/validation';

// Define error type
type ActionResult<T> = { success: true, data: T } | { success: false, error: string };

/**
 * Helper function that only returns error results, never success results
 */
function getValidationError(result: z.SafeParseReturnType<any, any>): { success: false, error: string } | null {
  if (!result.success) {
    const errorMessage = result.error.errors.map(err => `${err.path.join('.')}: ${err.message}`).join(', ');

    return { success: false, error: `Validation failed: ${errorMessage}` };
  }
  return null; // No error
}

// Create case server action
export async function createCaseAction(formData: FormData): Promise<ActionResult<{ id: number }>> {
  try {
    // Check authentication
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return {
        success: false,
        error: 'You must be logged in to create a case',
      };
    }

    // Parse and validate form data
    const rawData = {
      title: formData.get('title')?.toString() || '',
      description: formData.get('description')?.toString() || undefined,
      active: formData.get('active') === 'on' || formData.get('active') === 'true',
    };

    // Validate with Zod schema
    const validationResult = newCaseSchema.safeParse(rawData);

    // Handle validation errors - now returns only error results
    const validationError = getValidationError(validationResult);
    if (validationError) return validationError;

    // TypeScript type guard - ensures .data is available
    if (!validationResult.success) {
      // This should never happen because we checked with getValidationError,
      // but it helps TypeScript understand the type
      return {
        success: false,
        error: 'Validation failed',
      };
    }

    // Initialize database
    await initDb();

    // Create case in database - now TypeScript knows data is available
    const newCase = await createCase({
      title: validationResult.data.title,
      description: validationResult.data.description,
      active: validationResult.data.active,
    });

    // Revalidate pages that display cases
    revalidatePath('/cases');

    return {
      success: true,
      data: { id: newCase.id },
    };
  }
  catch (error) {
    console.error('Error creating case:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'An unknown error occurred',
    };
  }
}

// Update case server action - apply the same pattern here
export async function updateCaseAction(id: number, formData: FormData): Promise<ActionResult<{ id: number }>> {
  try {
    // Check authentication
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return {
        success: false,
        error: 'You must be logged in to update a case',
      };
    }

    // Initialize database
    await initDb();

    // Check if case exists
    const existingCase = await getCaseById(id);
    if (!existingCase) {
      return { success: false, error: 'Case not found' };
    }

    // Parse and validate form data
    const rawData = {
      title: formData.get('title')?.toString() || undefined,
      description: formData.get('description')?.toString() || undefined,
      active: formData.has('active') ? formData.get('active') === 'on' || formData.get('active') === 'true' : undefined,
    };

    // Validate with Zod schema - use partial schema for updates
    const updateSchema = newCaseSchema.partial();
    const validationResult = updateSchema.safeParse(rawData);

    // Handle validation errors - now returns only error results
    const validationError = getValidationError(validationResult);
    if (validationError) return validationError;

    // TypeScript type guard - ensures .data is available
    if (!validationResult.success) {
      // This should never happen because we checked with getValidationError,
      // but it helps TypeScript understand the type
      return {
        success: false,
        error: 'Validation failed',
      };
    }

    // Update case in database - now TypeScript knows data is available
    const updatedCase = await updateCase(id, {
      title: validationResult.data.title,
      description: validationResult.data.description,
      active: validationResult.data.active,
    });

    // Revalidate pages that display cases
    revalidatePath(`/cases/${id}`);
    revalidatePath('/cases');

    return {
      success: true,
      data: { id: updatedCase.id },
    };
  }
  catch (error) {
    console.error('Error updating case:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'An unknown error occurred',
    };
  }
}
