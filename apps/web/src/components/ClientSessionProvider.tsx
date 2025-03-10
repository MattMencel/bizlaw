import React from 'react';
import { SessionProvider } from 'next-auth/react';
import type { Session } from 'next-auth';

interface ClientSessionProviderProps {
  children: React.ReactNode;
  session: Session | null | undefined;
}

const ClientSessionProvider: React.FC<ClientSessionProviderProps> = ({
  children,
  session,
}) => {
  return <SessionProvider session={session}>{children}</SessionProvider>;
};

export default ClientSessionProvider;
