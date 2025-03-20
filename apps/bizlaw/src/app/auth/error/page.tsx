'use client';

import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { Suspense } from 'react';

function ErrorContent() {
  const searchParams = useSearchParams();
  const error = searchParams.get('error');

  let errorMessage = 'An error occurred during authentication';

  switch (error) {
    case 'AccessDenied':
      errorMessage = 'You do not have permission to access this resource';
      break;
    case 'Verification':
      errorMessage = 'The verification link is invalid or has expired';
      break;
    case 'OAuthSignin':
      errorMessage = 'Error in OAuth sign-in process';
      break;
    case 'OAuthCallback':
      errorMessage = 'Error in OAuth callback process';
      break;
    case 'Configuration':
      errorMessage = 'There is a server configuration error';
      break;
    default:
      errorMessage = 'An unexpected error occurred during sign in';
  }

  return (
    <div className="flex min-h-screen flex-col items-center justify-center p-4 bg-gray-50">
      <div className="w-full max-w-md p-8 space-y-8 bg-white rounded-lg shadow">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-red-500">
            Authentication Error
          </h1>
          <p className="mt-4 text-gray-600">{errorMessage}</p>
        </div>
        <div className="pt-4">
          <Link
            href="/auth/signin"
            className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
          >
            Return to Sign In
          </Link>
        </div>
      </div>
    </div>
  );
}

export default function AuthError() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <ErrorContent />
    </Suspense>
  );
}
