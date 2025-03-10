import React from 'react';
import Head from 'next/head';
import dynamic from 'next/dynamic';
// Remove the CSS module import
// import styles from '../styles/Home.module.css';

// Import navigation component with authentication logic with no SSR
const NavMenu = dynamic(() => import('../components/Navigation/NavMenu'), {
  ssr: false,
});

export default function HomePage() {
  return (
    <div className="container">
      <Head>
        <title>Business Law Application</title>
        <meta name="description" content="Business Law Learning Platform" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className="main">
        <h1 className="title">Welcome to the Business Law Application</h1>

        {/* Navigation menu with proper auth state handling */}
        <NavMenu />

        <div className="description">
          <p>
            This platform helps you learn about business law concepts through
            interactive case studies.
          </p>
        </div>
      </main>

      <footer className="footer">
        <p>© 2025 Business Law Application</p>
      </footer>
    </div>
  );
}
