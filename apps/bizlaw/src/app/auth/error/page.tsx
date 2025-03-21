'use client';

import { Suspense } from 'react';
import Link from 'next/link';

// Separate the part that uses useSearchParams into its own component
import ErrorContent from './ErrorContent';

export default function AuthError() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center p-4 bg-gray-50">
      <div className="w-full max-w-md p-8 space-y-8 bg-white rounded-lg shadow">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-red-600">Authentication Error</h1>
          <Suspense fallback={<div className="mt-4 p-4">Loading error details...</div>}>
            <ErrorContent />
          </Suspense>
          <div className="mt-6">
            <Link
              href="/auth/signin"
              className="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Back to Sign In
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
