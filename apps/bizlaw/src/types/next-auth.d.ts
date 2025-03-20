import NextAuth from 'next-auth';
import { JWT } from 'next-auth/jwt';

declare module 'next-auth' {
  /**
   * Returned by `useSession`, `getSession` and received as a prop on the `SessionProvider` React Context
   */
  interface Session {
    user: {
      id?: string
      name?: string | null
      email?: string | null
      image?: string | null
      role?: string
      firstName?: string
      lastName?: string
    }
  }

  interface User {
    id: string
    email?: string | null
    firstName?: string | null
    lastName?: string | null
    role?: string | null
    image?: string | null
  }
}

declare module 'next-auth/jwt' {
  /** Returned by the `jwt` callback and `getToken`, when using JWT sessions */
  interface JWT {
    id?: string
    role?: string
    firstName?: string
    lastName?: string
  }
}
