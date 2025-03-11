import React, { useEffect } from 'react';
import { useSession, signIn, signOut } from 'next-auth/react';
import { useRouter } from 'next/router';

const AuthComponents = () => {
  const { data: session, status } = useSession();
  const router = useRouter();

  // Redirect after successful login with a slight delay
  // to ensure token propagation
  useEffect(() => {
    if (status === 'authenticated' && session) {
      const timer = setTimeout(() => {
        router.push('/');
      }, 1500); // 1.5 second delay

      return () => clearTimeout(timer);
    }
  }, [status, session, router]);

  if (status === 'loading') {
    return <div>Loading...</div>;
  }

  if (session) {
    return (
      <div>
        <p>Logged in as {session.user?.name}</p>
        <p>Email: {session.user?.email}</p>
        <p>Role: {session.user?.role || 'Not assigned'}</p>
        <p>Redirecting to home page...</p>
        <button
          onClick={() => signOut()}
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
          Sign out
        </button>
      </div>
    );
  }

  return (
    <div>
      <button
        onClick={() => signIn('google')}
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
        Sign in with Google
      </button>
    </div>
  );
};

export default AuthComponents;
