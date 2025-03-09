import NextAuth from 'next-auth';
import { DefaultUser } from 'next-auth';

declare module 'next-auth' {
  interface Session {
    user: {
      id: string;
      name?: string | null;
      email?: string | null;
      image?: string | null;
      role: string; // Add the role property
    };
  }

  interface User extends DefaultUser {
    role: string; // Add the role property
  }

  interface AdapterUser extends DefaultUser {
    role: string; // Add the role property
  }
}
