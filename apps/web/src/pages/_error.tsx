import React from 'react';
import { NextPage } from 'next';
import Head from 'next/head';

interface ErrorProps {
  statusCode?: number;
  title?: string;
}

const ErrorPage: NextPage<ErrorProps> = ({ statusCode, title }) => {
  const errorMessage =
    title ||
    (statusCode
      ? `An error ${statusCode} occurred on server`
      : 'An error occurred on client');

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
        <title>{statusCode ? `${statusCode}: ${errorMessage}` : 'Error'}</title>
      </Head>
      <h1
        style={{
          margin: '0',
          fontSize: '24px',
          fontWeight: 500,
          padding: '0 20px',
        }}
      >
        {statusCode && <span>{statusCode}. </span>}
        {errorMessage}
      </h1>
      <p>Please try again or contact support if the problem persists.</p>
    </div>
  );
};

ErrorPage.getInitialProps = ({ res, err }) => {
  const statusCode = res ? res.statusCode : err ? err.statusCode : 404;
  return { statusCode };
};

export default ErrorPage;
