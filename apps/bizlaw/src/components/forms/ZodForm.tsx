'use client';

import type { ReactNode, FormEvent } from 'react';
import { useState } from 'react';
import type { z } from 'zod';

interface ZodFormProps<T extends z.ZodType> {
  schema: T
  initialValues?: Partial<z.infer<T>>
  onSubmit: (values: z.infer<T>) => Promise<void> | void
  children: (props: {
    values: Partial<z.infer<T>>
    errors: Record<string, string[] | undefined>
    isSubmitting: boolean
    handleChange: (
      field: keyof z.infer<T>,
    ) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => void
    handleSubmit: (e: FormEvent) => void
  }) => ReactNode
  resetOnSubmit?: boolean
}

export function ZodForm<T extends z.ZodType>({
  schema,
  initialValues = {},
  onSubmit,
  children,
  resetOnSubmit = false,
}: ZodFormProps<T>) {
  const [values, setValues] = useState<Partial<z.infer<T>>>(initialValues);
  const [errors, setErrors] = useState<Record<string, string[]>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange
    = (field: keyof z.infer<T>) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
      const value = e.target.type === 'checkbox' ? (e.target as HTMLInputElement).checked : e.target.value;

      setValues(prev => ({
        ...prev,
        [field]: value,
      }));

      // Clear error for this field when it changes
      if (errors[field as string]) {
        setErrors((prev) => {
          const newErrors = { ...prev };
          delete newErrors[field as string];
          return newErrors;
        });
      }
    };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      // Validate all fields
      const result = schema.safeParse(values);

      if (!result.success) {
        const formattedErrors: Record<string, string[]> = {};
        result.error.errors.forEach((error) => {
          const field = error.path[0] as string;
          if (!formattedErrors[field]) {
            formattedErrors[field] = [];
          }
          formattedErrors[field].push(error.message);
        });

        setErrors(formattedErrors);
        return;
      }

      // Clear all errors
      setErrors({});

      // Submit form
      await onSubmit(result.data);

      // Reset form if needed
      if (resetOnSubmit) {
        setValues(initialValues);
      }
    }
    catch (error) {
      console.error('Form submission error:', error);
    }
    finally {
      setIsSubmitting(false);
    }
  };

  return children({
    values,
    errors,
    isSubmitting,
    handleChange,
    handleSubmit,
  });
}
