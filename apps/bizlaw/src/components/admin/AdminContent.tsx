import dynamic from 'next/dynamic';
import { useRouter } from 'next/router';
import { useSession } from 'next-auth/react';
import React from 'react';

// Use dynamic imports for nested components that use client hooks
const InstructorManagement = dynamic(() => import('./InstructorManagement'), {
  ssr: false,
});

const AdminContent = () => {
  const { data: session, status } = useSession();
  const router = useRouter();

  if (status === 'loading') {
    return <div>Loading...</div>;
  }

  if (!session) {
    return (
      <div
        style={{
          padding: '1rem',
          backgroundColor: '#ffebee',
          borderRadius: '4px',
          marginTop: '1rem',
        }}
      >
        <p>You need to be logged in to view this page.</p>
        <button
          onClick={() => router.push('/login')}
          style={{
            background: '#0070f3',
            color: 'white',
            border: 'none',
            padding: '8px 16px',
            borderRadius: '4px',
            cursor: 'pointer',
            marginTop: '10px',
          }}
        >
          Go to Login
        </button>
      </div>
    );
  }

  if (session.user?.role !== 'admin') {
    return (
      <div
        style={{
          padding: '1rem',
          backgroundColor: '#ffebee',
          borderRadius: '4px',
          marginTop: '1rem',
        }}
      >
        <p>You don&apos;t have permission to access this page. Admin access required.</p>
        <button
          onClick={() => router.push('/')}
          style={{
            background: '#0070f3',
            color: 'white',
            border: 'none',
            padding: '8px 16px',
            borderRadius: '4px',
            cursor: 'pointer',
            marginTop: '10px',
          }}
        >
          Return to Home
        </button>
      </div>
    );
  }

  return (
    <div>
      <p>
        Welcome,
        {session.user?.name}
        ! (Admin)
      </p>

      <h2 style={{ marginTop: '2rem' }}>User Management</h2>
      <InstructorManagement />

      {/* Add more admin sections as needed */}
    </div>
  );
};

export default AdminContent;
