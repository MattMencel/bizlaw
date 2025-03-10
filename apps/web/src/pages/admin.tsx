import { GetServerSideProps } from 'next';
import { getSession } from 'next-auth/react';
import Breadcrumb from '../components/Breadcrumb';
import { signOut } from 'next-auth/react';
import Link from 'next/link';
import dynamic from 'next/dynamic';
import Head from 'next/head';

// Use dynamic import with SSR disabled for components that use client-side hooks
const AdminContent = dynamic(() => import('../components/Admin/AdminContent'), {
  ssr: false,
});

interface AdminPageProps {
  userName: string | null;
  isLoggedIn: boolean;
  userRole: string | null;
}

const AdminPage = ({ userName, isLoggedIn, userRole }: AdminPageProps) => {
  if (!isLoggedIn) {
    return (
      <div>
        <h1>Access Denied</h1>
        <p>Please login to access this page.</p>
        <Link
          href="/login"
          style={{
            color: '#0070f3',
            textDecoration: 'underline',
            cursor: 'pointer',
          }}
        >
          Login
        </Link>
      </div>
    );
  }

  if (userRole !== 'admin') {
    return (
      <div>
        <h1>Access Denied</h1>
        <p>You do not have permission to access this page.</p>
        <Link
          href="/"
          style={{
            color: '#0070f3',
            textDecoration: 'underline',
            cursor: 'pointer',
          }}
        >
          Return to Home
        </Link>
      </div>
    );
  }

  return (
    <div className="container">
      <Head>
        <title>Admin - Business Law Application</title>
      </Head>
      <Breadcrumb />
      <h1>Admin Dashboard</h1>
      <p>Welcome, {userName}</p>
      <button onClick={() => signOut()}>Sign out</button>

      {/* Admin components loaded only on client-side */}
      <AdminContent />

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
};

export const getServerSideProps: GetServerSideProps = async context => {
  const session = await getSession(context);

  if (!session) {
    return {
      redirect: {
        destination: '/login',
        permanent: false,
      },
    };
  }

  // Check if the user is an admin
  if (session.user.role !== 'admin') {
    return {
      redirect: {
        destination: '/',
        permanent: false,
      },
    };
  }

  return {
    props: {
      userName: session.user?.name || null,
      isLoggedIn: true,
      userRole: session.user?.role || null,
    },
  };
};

export default AdminPage;
