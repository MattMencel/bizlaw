'use client';

import { usePathname, useRouter } from 'next/navigation';
import { useSession } from 'next-auth/react';
import type { ReactNode } from 'react';
import { createContext, useContext, useState, useEffect } from 'react';

// Define user type
export interface User {
  id: string
  email: string
  firstName?: string
  lastName?: string
  role: 'admin' | 'instructor' | 'student'
  profileImage?: string
}

// Define context type
interface AuthContextType {
  user: User | null
  loading: boolean
  isAdmin: boolean
  isInstructor: boolean
  isStudent: boolean
}

// Create the context with default values
const AuthContextValue = createContext<AuthContextType>({
  user: null,
  loading: true,
  isAdmin: false,
  isInstructor: false,
  isStudent: false,
});

// Export the hook for using auth context
export const useAuth = () => useContext(AuthContextValue);

// Provider component
export function AuthContext({ children }: { children: ReactNode }) {
  const { data: session, status } = useSession();
  const [user, setUser] = useState<User | null>(null);
  const router = useRouter();
  const pathname = usePathname();

  // Determine if we're loading
  const loading = status === 'loading';

  // Derived state for role checks
  const isAdmin = user?.role === 'admin';
  const isInstructor = user?.role === 'instructor';
  const isStudent = user?.role === 'student';

  useEffect(() => {
    // When session changes, update our user state
    if (session?.user) {
      // Extract first and last name from the name field if available
      let firstName = undefined;
      let lastName = undefined;

      if (session.user.name) {
        const nameParts = session.user.name.split(' ');
        firstName = nameParts[0];
        lastName
          = nameParts.length > 1 ? nameParts.slice(1).join(' ') : undefined;
      }

      setUser({
        id: session.user.id as string,
        email: session.user.email as string,
        firstName, // Use extracted firstName
        lastName, // Use extracted lastName
        role:
          (session.user.role as 'admin' | 'instructor' | 'student')
          || 'student',
        profileImage: session.user.image || undefined, // Use standard image property
      });
    }
    else if (status === 'unauthenticated') {
      setUser(null);

      // Redirect to login if on a protected page
      const protectedRoutes = ['/dashboard', '/courses', '/admin'];
      const isProtected = protectedRoutes.some(route =>
        pathname?.startsWith(route),
      );

      if (isProtected) {
        router.push('/api/auth/signin');
      }
    }
  }, [session, status, router, pathname]);

  return (
    <AuthContextValue.Provider
      value={{
        user,
        loading,
        isAdmin,
        isInstructor,
        isStudent,
      }}
    >
      {children}
    </AuthContextValue.Provider>
  );
}
