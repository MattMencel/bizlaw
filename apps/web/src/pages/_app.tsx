import React from 'react';
import type { AppProps } from 'next/app';
import '../styles/globals.css';
import dynamic from 'next/dynamic';

// Create a client-only wrapper component for SessionProvider
const ClientSessionProvider = dynamic(
  () => import('../components/ClientSessionProvider'),
  {
    ssr: false,
    // Use a simple loading component that doesn't try to access children
    loading: () => <div>Loading...</div>,
  },
);

function MyApp({ Component, pageProps }: AppProps) {
  return (
    <ClientSessionProvider session={pageProps.session}>
      <Component {...pageProps} />
    </ClientSessionProvider>
  );
}

export default MyApp;
