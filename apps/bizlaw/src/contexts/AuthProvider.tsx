'use client';

import { SessionProvider } from 'next-auth/react';

import { AuthContext } from './AuthContext';

export function AuthProvider({ children }: { children: React.ReactNode }) {
  return (
    <SessionProvider>
      <AuthContext>{children}</AuthContext>
    </SessionProvider>
  );
}
