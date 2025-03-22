import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'About | Business Law',
  description: 'Learn about our application and our mission to teach business law concepts.',
};

export default function AboutPage() {
  return (
    <div className="container mx-auto py-8 px-4">
      <h1 className="text-3xl font-bold mb-6">About Business Law</h1>

      <div className="bg-white rounded-lg shadow-md p-6">
        <h2 className="text-xl font-semibold mb-4">Our Mission</h2>
        <p className="mb-4">
          The Business Law application is designed to provide business-law students with practical experience through
          interactive case studies and simulations.
        </p>

        <h2 className="text-xl font-semibold mb-4 mt-8">About the Platform</h2>
        <p className="mb-4">
          Our platform offers a comprehensive learning environment where students can engage with realistic business law
          scenarios, receive feedback from instructors, and develop critical thinking skills necessary for legal
          practice.
        </p>

        <h2 className="text-xl font-semibold mb-4 mt-8">Contact</h2>
        <p>
          For questions or support, please reach out to us at{' '}
          <a href="mailto:support@bizlaw.edu" className="text-blue-600 hover:underline">
            support@bizlaw.edu
          </a>
        </p>
      </div>
    </div>
  );
}
