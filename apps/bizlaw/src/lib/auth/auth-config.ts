import type { NextAuthOptions } from 'next-auth';

// Now properly typed as a Partial<NextAuthOptions>
export const authConfig: Partial<NextAuthOptions> = {
  session: {
    strategy: 'jwt', // This will now be correctly typed
    maxAge: 30 * 24 * 60 * 60, // 30 days
  },
  pages: {
    signIn: '/auth/signin',
    error: '/auth/error',
  },
  debug: process.env.NODE_ENV === 'development',
  cookies: {
    sessionToken: {
      name: 'next-auth.session-token',
      options: {
        httpOnly: true,
        sameSite: 'lax',
        path: '/',
        secure: process.env.NODE_ENV === 'production',
      },
    },
  },
};
