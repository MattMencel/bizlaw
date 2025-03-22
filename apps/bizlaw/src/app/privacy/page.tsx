import { Metadata } from 'next';
import Link from 'next/link';

export const metadata: Metadata = {
  title: 'Privacy Policy | Business Law',
  description: 'Privacy policy for the Business Law platform.',
};

export default function PrivacyPage() {
  return (
    <div className="container mx-auto py-8 px-4">
      <h1 className="text-3xl font-bold mb-6">Privacy Policy</h1>

      <div className="bg-white rounded-lg shadow-md p-6">
        <p className="text-gray-500 mb-6">Last updated: March 21, 2025</p>

        <h2 className="text-xl font-semibold mb-4">1. Information We Collect</h2>
        <p className="mb-4">
          We collect information you provide directly to us when you register for an account, create or modify your
          profile, or interact with features on the platform.
        </p>

        <h2 className="text-xl font-semibold mb-4 mt-8">2. How We Use Your Information</h2>
        <p className="mb-4">
          We use the information we collect to provide, maintain, and improve our services, develop new features, and
          protect our platform and users.
        </p>

        <h2 className="text-xl font-semibold mb-4 mt-8">3. Information Sharing</h2>
        <p className="mb-4">
          We do not share your personal information with companies, organizations, or individuals outside of Business
          Law except in the following cases: with your consent, with domain administrators, for legal reasons, or in
          connection with a merger or acquisition.
        </p>

        <h2 className="text-xl font-semibold mb-4 mt-8">4. Data Security</h2>
        <p className="mb-4">
          We take reasonable measures to protect your personal information from unauthorized access, use, or disclosure.
        </p>

        <h2 className="text-xl font-semibold mb-4 mt-8">5. Terms of Service</h2>
        <p className="mb-4">
          Please also read our Terms of Service which establish the use, disclaimers, and limitations of liability
          governing the use of our platform. You can view our terms{' '}
          <Link href="/terms" className="text-blue-600 hover:underline">
            here
          </Link>
          .
        </p>

        <h2 className="text-xl font-semibold mb-4 mt-8">6. Contact Us</h2>
        <p>
          If you have any questions about this Privacy Policy, please contact us at{' '}
          <a href="mailto:privacy@bizlaw.edu" className="text-blue-600 hover:underline">
            privacy@bizlaw.edu
          </a>
        </p>
      </div>
    </div>
  );
}
