import Breadcrumb from '../components/Breadcrumb';
import { useSession, signIn, signOut } from 'next-auth/react';
import { useRouter } from 'next/router';
import { useEffect } from 'react';
import StudentRoster from '../components/CourseAdmin/StudentRoster';
import Teams from '../components/CourseAdmin/Teams';
import { GetServerSideProps } from 'next';
import { getSession } from 'next-auth/react';

const CourseAdminPage = () => {
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
        <h1>Course Admin Page</h1>
        <p>Welcome, {session.user?.name}</p>
        <button onClick={() => signOut()}>Sign out</button>
        <StudentRoster />
        <Teams />
      </div>
    );
  }

  return (
    <div>
      <h1>Course Admin Page</h1>
      <button onClick={() => signIn('google')}>Sign in with Google</button>
    </div>
  );
};

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

  if (session.user.role !== 'instructor') {
    return {
      redirect: {
        destination: '/',
        permanent: false,
      },
    };
  }

  return {
    props: { session },
  };
};

export default CourseAdminPage;
