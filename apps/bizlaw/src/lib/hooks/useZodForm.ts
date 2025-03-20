import { useState } from 'react';
import { z } from 'zod'; // Remove the 'type' keyword to import the actual implementation

type ValidationErrors<T> = Partial<Record<keyof T, string[]>>;

interface UseZodFormOptions<T extends z.ZodType> {
  schema: T
  defaultValues?: Partial<z.infer<T>>
  onSubmit: (values: z.infer<T>) => Promise<void> | void
}

export function useZodForm<T extends z.ZodObject<any>>({ schema, defaultValues = {}, onSubmit }: UseZodFormOptions<T>) {
  const [values, setValues] = useState<Partial<z.infer<T>>>(defaultValues);
  const [errors, setErrors] = useState<ValidationErrors<z.infer<T>>>({});
  const [touched, setTouched] = useState<Partial<Record<keyof z.infer<T>, boolean>>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange
    = <K extends keyof z.infer<T>>(field: K) =>
      (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
        const value = e.target.type === 'checkbox' ? (e.target as HTMLInputElement).checked : e.target.value;

        setValues(prev => ({ ...prev, [field]: value }));

        if (touched[field]) {
          validateField(field, value);
        }
      };

  const handleBlur
    = <K extends keyof z.infer<T>>(field: K) =>
      () => {
        setTouched(prev => ({ ...prev, [field]: true }));
        validateField(field, values[field]);
      };

  const validateField = <K extends keyof z.infer<T>>(field: K, value: unknown) => {
    try {
      // Create a partial schema for just this field
      const fieldShape = schema.shape[field as string];
      if (!fieldShape) {
        console.warn(`Field "${String(field)}" not found in schema`);
        return true;
      }

      const fieldSchema = z.object({ [field as string]: fieldShape });
      fieldSchema.parse({ [field]: value });

      // Clear errors for this field
      setErrors((prev) => {
        const newErrors = { ...prev };
        delete newErrors[field];
        return newErrors;
      });

      return true;
    }
    catch (error) {
      if (error instanceof z.ZodError) {
        const fieldErrors = error.errors.filter(e => e.path[0] === field).map(e => e.message);

        setErrors(prev => ({ ...prev, [field]: fieldErrors }));
        return false;
      }
      return true;
    }
  };

  const validateForm = (): boolean => {
    try {
      schema.parse(values);
      setErrors({});
      return true;
    }
    catch (error) {
      if (error instanceof z.ZodError) {
        const formattedErrors: ValidationErrors<z.infer<T>> = {};

        error.errors.forEach((err) => {
          const field = err.path[0] as keyof z.infer<T>;
          if (!formattedErrors[field]) {
            formattedErrors[field] = [];
          }
          formattedErrors[field]?.push(err.message);
        });

        setErrors(formattedErrors);
      }
      return false;
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Mark all fields as touched
    const allFields = Object.keys(schema.shape) as Array<keyof z.infer<T>>;
    const allTouched = allFields.reduce(
      (acc, field) => ({ ...acc, [field]: true }),
      {} as Record<keyof z.infer<T>, boolean>,
    );
    setTouched(allTouched);

    // Validate all fields
    if (!validateForm()) {
      return;
    }

    setIsSubmitting(true);
    try {
      await onSubmit(values as z.infer<T>);
    }
    catch (error) {
      console.error('Form submission error:', error);
    }
    finally {
      setIsSubmitting(false);
    }
  };

  const reset = (newValues = defaultValues) => {
    setValues(newValues);
    setErrors({});
    setTouched({});
  };

  return {
    values,
    errors,
    touched,
    isSubmitting,
    handleChange,
    handleBlur,
    handleSubmit,
    reset,
  };
}
