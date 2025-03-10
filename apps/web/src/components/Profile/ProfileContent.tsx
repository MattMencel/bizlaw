import React from 'react';
import { useSession, signOut } from 'next-auth/react';
import { useRouter } from 'next/router';

interface User {
  name: string | null;
  email: string | null;
  image: string | null;
  role: string;
}

interface ProfileContentProps {
  user: User;
}

const ProfileContent: React.FC<ProfileContentProps> = ({ user }) => {
  const { data: session, status } = useSession();
  const router = useRouter();

  // Use session data if available, fall back to passed user prop
  const userData = session?.user || user;

  if (status === 'loading') {
    return <div>Loading profile...</div>;
  }

  if (!session && !user) {
    return (
      <div
        style={{
          padding: '1rem',
          backgroundColor: '#ffebee',
          borderRadius: '4px',
          marginTop: '1rem',
        }}
      >
        <p>You need to be logged in to view your profile.</p>
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

  return (
    <div
      className="profile-card"
      style={{
        display: 'flex',
        backgroundColor: 'white',
        borderRadius: '8px',
        boxShadow: '0 2px 10px rgba(0, 0, 0, 0.1)',
        padding: '20px',
        marginTop: '20px',
        gap: '20px',
      }}
    >
      {userData.image && (
        <div className="profile-image">
          <img
            src={userData.image}
            alt={userData.name || 'User'}
            style={{
              width: '120px',
              height: '120px',
              borderRadius: '60px',
              objectFit: 'cover',
              border: '3px solid #f0f0f0',
            }}
          />
        </div>
      )}

      <div className="profile-info" style={{ flex: 1 }}>
        <h2 style={{ marginTop: 0 }}>{userData.name}</h2>
        <p>Email: {userData.email}</p>
        <p>Role: {userData.role || 'Student'}</p>

        {session && (
          <div style={{ marginTop: '20px' }}>
            <button
              onClick={() => signOut()}
              style={{
                backgroundColor: '#f44336',
                color: 'white',
                border: 'none',
                padding: '8px 16px',
                borderRadius: '4px',
                cursor: 'pointer',
                fontSize: '14px',
              }}
            >
              Sign out
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default ProfileContent;
