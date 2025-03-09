import { getSession } from 'next-auth/react';
import { GetServerSideProps } from 'next';
import Link from 'next/link';
import Breadcrumb from '../components/Breadcrumb';

export default function HomePage() {
  return (
    <div className="container">
      <Breadcrumb />
      <h1>Welcome to the Business Law Web Application!</h1>
      <nav>
        <ul>
          <li>
            <Link href="/login">
              <a>Login</a>
            </Link>
          </li>
          <li>
            <Link href="/signup">
              <a>Sign Up</a>
            </Link>
          </li>
          <li>
            <Link href="/admin">
              <a>Admin</a>
            </Link>
          </li>
          <li>
            <Link href="/course-admin">
              <a>Course Admin</a>
            </Link>
          </li>
        </ul>
      </nav>
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
    props: { session },
  };
};
