'use client';

import { useState } from 'react';
import { z } from 'zod';

type FormValidationProps<T extends z.ZodType> = {
  schema: T
  onSubmit: (data: z.infer<T>) => Promise<void>
  children: (props: {
    register: (field: keyof z.infer<T>) => {
      name: keyof z.infer<T>
      onChange: (e: React.ChangeEvent<HTMLInputElement>) => void
      onBlur: () => void
    }
    errors: Record<string, string[] | undefined>
    isSubmitting: boolean
    handleSubmit: (e: React.FormEvent) => void
    formData: Partial<z.infer<T>>
  }) => React.ReactNode
  defaultValues?: Partial<z.infer<T>>
};

export function FormValidation<T extends z.ZodObject<any>>({
  schema,
  onSubmit,
  children,
  defaultValues = {},
}: FormValidationProps<T>) {
  const [formData, setFormData] = useState<Partial<z.infer<T>>>(defaultValues);
  // Update the type to allow undefined values
  const [errors, setErrors] = useState<Record<string, string[] | undefined>>({});
  const [touchedFields, setTouchedFields] = useState<Record<string, boolean>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const validateField = (name: keyof z.infer<T>, value: any) => {
    try {
      // Create a partial schema just for this field
      const fieldSchema = z.object({
        [name]: schema.shape[name],
      });

      fieldSchema.parse({ [name]: value });
      // Now this is type-safe
      setErrors(prev => ({ ...prev, [name]: undefined }));
      return true;
    }
    catch (error) {
      if (error instanceof z.ZodError) {
        const fieldErrors = error.errors.filter(e => e.path[0] === name).map(e => e.message);
        setErrors(prev => ({ ...prev, [name]: fieldErrors.length > 0 ? fieldErrors : undefined }));
        return false;
      }
      return true;
    }
  };

  const register = (field: keyof z.infer<T>) => ({
    name: field,
    onChange: (e: React.ChangeEvent<HTMLInputElement>) => {
      const value = e.target.type === 'checkbox' ? e.target.checked : e.target.value;
      setFormData(prev => ({ ...prev, [field]: value }));
      if (touchedFields[field as string]) {
        validateField(field, value);
      }
    },
    onBlur: () => {
      setTouchedFields(prev => ({ ...prev, [field as string]: true }));
      validateField(field, formData[field]);
    },
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Mark all fields as touched
    const allFields = Object.keys(schema.shape) as Array<keyof z.infer<T>>;
    const allTouched = allFields.reduce(
      (acc, field) => ({ ...acc, [field as string]: true }),
      {} as Record<string, boolean>,
    );
    setTouchedFields(allTouched);

    // Validate all fields
    const validationResult = schema.safeParse(formData);
    if (!validationResult.success) {
      const formattedErrors: Record<string, string[] | undefined> = {};
      validationResult.error.errors.forEach((error) => {
        const field = error.path[0] as string;
        if (!formattedErrors[field]) {
          formattedErrors[field] = [];
        }
        formattedErrors[field]?.push(error.message);
      });

      setErrors(formattedErrors);
      return;
    }

    // Clear all errors when form is valid
    setErrors({});

    // Submit the form
    setIsSubmitting(true);
    try {
      await onSubmit(validationResult.data);
    }
    catch (error) {
      console.error('Form submission error:', error);
    }
    finally {
      setIsSubmitting(false);
    }
  };

  return children({
    register,
    errors,
    isSubmitting,
    handleSubmit,
    formData,
  });
}
