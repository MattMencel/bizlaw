import { Metadata } from 'next';
import Link from 'next/link';

export const metadata: Metadata = {
  title: 'Terms of Service | Business Law',
  description: 'Terms and conditions for using the Business Law platform.',
};

export default function TermsPage() {
  return (
    <div className="container mx-auto py-8 px-4">
      <h1 className="text-3xl font-bold mb-6">Terms of Service</h1>

      <div className="bg-white rounded-lg shadow-md p-6">
        <p className="text-gray-500 mb-6">Last updated: March 21, 2025</p>

        <h2 className="text-xl font-semibold mb-4">1. Acceptance of Terms</h2>
        <p className="mb-4">
          By accessing or using the Business Law platform, you agree to be bound by these Terms of Service. If you
          disagree with any part of the terms, you may not access the service.
        </p>

        <h2 className="text-xl font-semibold mb-4 mt-8">2. Use License</h2>
        <p className="mb-4">
          Permission is granted to temporarily use the materials on Business Law's platform for personal, non-commercial
          educational purposes only. This is the grant of a license, not a transfer of title.
        </p>

        <h2 className="text-xl font-semibold mb-4 mt-8">3. User Accounts</h2>
        <p className="mb-4">
          When you create an account with us, you must provide accurate, complete, and updated information. You are
          responsible for safeguarding the password and for all activities that occur under your account.
        </p>

        <h2 className="text-xl font-semibold mb-4 mt-8">4. Privacy Policy</h2>
        <p className="mb-4">
          Please review our Privacy Policy, which also governs your visit to our platform, to understand our practices.
          You can view our privacy policy{' '}
          <Link href="/privacy" className="text-blue-600 hover:underline">
            here
          </Link>
          .
        </p>

        <h2 className="text-xl font-semibold mb-4 mt-8">5. Contact Us</h2>
        <p>
          If you have any questions about these Terms, please contact us at{' '}
          <a href="mailto:legal@bizlaw.edu" className="text-blue-600 hover:underline">
            legal@bizlaw.edu
          </a>
        </p>
      </div>
    </div>
  );
}
