import React from 'react';
import Head from 'next/head';
import Link from 'next/link';

export default function Custom404() {
  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        minHeight: '100vh',
        flexDirection: 'column',
        padding: '0 20px',
        textAlign: 'center',
      }}
    >
      <Head>
        <title>404 - Page Not Found</title>
      </Head>
      <h1
        style={{
          margin: '0',
          fontSize: '24px',
          fontWeight: 500,
        }}
      >
        404 - Page Not Found
      </h1>
      <p>The page you are looking for does not exist.</p>
      <Link
        href="/"
        style={{
          marginTop: '20px',
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
