import React from 'react';
import Link from 'next/link';
import { useSession, signOut } from 'next-auth/react';

const NavMenu = () => {
  const { data: session } = useSession();
  const isAdmin = session?.user?.role === 'admin';
  const isInstructor = ['professor', 'instructor'].includes(
    session?.user?.role as string,
  );

  return (
    <nav style={{ width: '100%', marginTop: '2rem', marginBottom: '2rem' }}>
      <ul
        style={{
          display: 'flex',
          listStyle: 'none',
          padding: 0,
          margin: 0,
          gap: '1rem',
          flexWrap: 'wrap',
          justifyContent: 'center',
        }}
      >
        {!session ? (
          <>
            <li>
              <Link
                href="/login"
                style={{
                  padding: '0.5rem 1rem',
                  backgroundColor: '#0070f3',
                  color: 'white',
                  borderRadius: '4px',
                  textDecoration: 'none',
                }}
              >
                Login
              </Link>
            </li>
          </>
        ) : (
          <>
            <li>
              <Link
                href="/cases"
                style={{
                  padding: '0.5rem 1rem',
                  backgroundColor: '#f0f7ff',
                  color: '#0070f3',
                  borderRadius: '4px',
                  textDecoration: 'none',
                }}
              >
                View Cases
              </Link>
            </li>

            {(isInstructor || isAdmin) && (
              <li>
                <Link
                  href="/course-admin"
                  style={{
                    padding: '0.5rem 1rem',
                    backgroundColor: '#f0f7ff',
                    color: '#0070f3',
                    borderRadius: '4px',
                    textDecoration: 'none',
                  }}
                >
                  Course Admin
                </Link>
              </li>
            )}

            {isAdmin && (
              <li>
                <Link
                  href="/admin"
                  style={{
                    padding: '0.5rem 1rem',
                    backgroundColor: '#f0f7ff',
                    color: '#0070f3',
                    borderRadius: '4px',
                    textDecoration: 'none',
                  }}
                >
                  Admin
                </Link>
              </li>
            )}

            <li>
              <Link
                href="/profile"
                style={{
                  padding: '0.5rem 1rem',
                  backgroundColor: '#f0f7ff',
                  color: '#0070f3',
                  borderRadius: '4px',
                  textDecoration: 'none',
                }}
              >
                Profile
              </Link>
            </li>

            <li>
              <button
                onClick={() => signOut()}
                style={{
                  padding: '0.5rem 1rem',
                  backgroundColor: '#f44336',
                  color: 'white',
                  borderRadius: '4px',
                  border: 'none',
                  cursor: 'pointer',
                }}
              >
                Sign Out
              </button>
            </li>
          </>
        )}
      </ul>

      {session && (
        <div
          style={{
            marginTop: '1rem',
            textAlign: 'center',
            padding: '0.5rem',
            backgroundColor: '#e8f5e9',
            borderRadius: '4px',
          }}
        >
          Logged in as: {session.user?.name} ({session.user?.role || 'student'})
        </div>
      )}
    </nav>
  );
};

export default NavMenu;
