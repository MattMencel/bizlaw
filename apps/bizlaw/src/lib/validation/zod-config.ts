import { z } from 'zod';

/**
 * Global Zod configuration
 * Configure error formatting and custom error maps here
 */
export function configureZod() {
  // Custom error formatting
  z.setErrorMap((issue, ctx) => {
    let message: string;
    switch (issue.code) {
      case z.ZodIssueCode.invalid_type:
        if (issue.received === 'undefined') {
          message = 'Required';
        }
        else {
          message = `Expected ${issue.expected}, received ${issue.received}`;
        }
        break;
      case z.ZodIssueCode.invalid_string:
        if (issue.validation === 'email') {
          message = 'Invalid email address';
        }
        else {
          message = ctx.defaultError;
        }
        break;
      default:
        message = ctx.defaultError;
    }
    return { message };
  });
}

// Run the configuration immediately
configureZod();
