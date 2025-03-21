'use client';

import { useSearchParams } from 'next/navigation';

export default function ErrorContent() {
  const searchParams = useSearchParams();
  const error = searchParams.get('error');

  // Map error codes to user-friendly messages
  const errorMessages: Record<string, string> = {
    Configuration: 'There is a problem with the server configuration.',
    AccessDenied: 'You do not have permission to sign in.',
    Verification: 'The verification link was invalid or has expired.',
    Default: 'An unexpected error occurred during authentication.',
    DatabaseDown: 'Unable to connect to our services. Please try again later.',
  };

  // Get the appropriate error message
  const errorMessage = error && errorMessages[error] ? errorMessages[error] : errorMessages.Default;

  return (
    <div className="mt-4 p-4 bg-red-50 border-l-4 border-red-500 text-red-700">
      <p>{errorMessage}</p>
      <p className="text-sm mt-2">{error && `Error code: ${error}`}</p>
    </div>
  );
}
