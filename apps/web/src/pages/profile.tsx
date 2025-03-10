import React from 'react';
import Head from 'next/head';
import Link from 'next/link';
import dynamic from 'next/dynamic';
import { GetServerSideProps } from 'next';
import { getSession } from 'next-auth/react';

// Define user interface for type safety
interface User {
  name: string | null;
  email: string | null;
  image: string | null;
  role: string;
}

// Import profile components with no SSR
const ProfileContent = dynamic<{ user: User }>(
  () => import('../components/Profile/ProfileContent'),
  { ssr: false },
);

interface ProfilePageProps {
  user: User;
}

export default function ProfilePage({ user }: ProfilePageProps) {
  return (
    <div className="container">
      <Head>
        <title>Profile - Business Law Application</title>
      </Head>

      <h1>Your Profile</h1>

      {/* Profile components loaded only on client-side */}
      <ProfileContent user={user} />

      <p style={{ marginTop: '2rem' }}>
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

export const getServerSideProps: GetServerSideProps = async (context) => {
  const session = await getSession(context);

  if (!session) {
    return {
      redirect: {
        destination: '/login',
        permanent: false,
      },
    };
  }

  return {
    props: {
      user: {
        name: session.user?.name,
        email: session.user?.email,
        image: session.user?.image,
        role: session.user?.role || 'student',
      },
    },
  };
};
