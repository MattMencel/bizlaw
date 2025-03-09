import Breadcrumb from '../components/Breadcrumb';

import { useSession, signIn, signOut } from 'next-auth/react';
import { useRouter } from 'next/router';
import { useEffect } from 'react';
import Instructors from '../components/Admin/Instructors';

const AdminPage = () => {
  const { data: session, status } = useSession();
  const router = useRouter();

  useEffect(() => {
    if (status === 'unauthenticated') {
      router.push('/login');
    }
  }, [status, router]);

  if (status === 'loading') {
    return <div>Loading...</div>;
  }

  if (session) {
    return (
      <div>
        <Breadcrumb />
        <h1>Admin Page</h1>
        <p>Welcome, {session.user?.name}</p>
        <button onClick={() => signOut()}>Sign out</button>
        <Instructors />
        {/* Add components for managing courses, students, and cases */}
      </div>
    );
  }

  return (
    <div>
      <h1>Admin Page</h1>
      <button onClick={() => signIn('google')}>Sign in with Google</button>
    </div>
  );
};

export default AdminPage;
