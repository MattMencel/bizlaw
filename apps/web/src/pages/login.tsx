import React from 'react';
import Head from 'next/head';
import Link from 'next/link';
import dynamic from 'next/dynamic';

// Dynamic import with no SSR for authentication components
const AuthComponents = dynamic(
  () => import('../components/Auth/AuthComponents'),
  { ssr: false },
);

export default function LoginPage() {
  return (
    <div className="container">
      <Head>
        <title>Login - Business Law Application</title>
      </Head>

      <h1>Login</h1>

      {/* Authentication components loaded only on client-side */}
      <AuthComponents />

      <p>
        <Link
          href="/"
          style={{ color: '#0070f3', textDecoration: 'underline' }}
        >
          Return to Home
        </Link>
      </p>
    </div>
  );
}
