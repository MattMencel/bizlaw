import { eq, count as drizzleCount } from 'drizzle-orm';
import type { NextAuthOptions } from 'next-auth';
import GoogleProvider from 'next-auth/providers/google';

import { authConfig } from './auth-config';
import { getDb, initDb } from '../db/db';
import { users } from '../db/schema';

// Get OAuth credentials with validation
const getGoogleCredentials = () => {
  const clientId = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;

  if (!clientId || clientId.length === 0) {
    throw new Error('Missing GOOGLE_CLIENT_ID environment variable');
  }

  if (!clientSecret || clientSecret.length === 0) {
    throw new Error('Missing GOOGLE_CLIENT_SECRET environment variable');
  }

  return { clientId, clientSecret };
};

export const authOptions: NextAuthOptions = {
  providers: [
    GoogleProvider({
      clientId: getGoogleCredentials().clientId,
      clientSecret: getGoogleCredentials().clientSecret,
    }),
  ],
  session: authConfig.session,
  secret: process.env.NEXTAUTH_SECRET,
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id;
        // Fix: Convert null to undefined to match expected types
        token.role = user.role || undefined;
      }
      return token;
    },
    async session({ session, token }) {
      if (session.user) {
        session.user.id = token.id as string;
        // Use consistent null handling here too
        session.user.role = (token.role as string) || undefined;
      }
      return session;
    },
    async signIn({ user, account }) {
      if (account?.provider === 'google') {
        try {
          let db;
          try {
            await initDb();
            db = getDb();
          }
          catch (dbError) {
            console.error('Failed to connect to database in signIn callback:', dbError);
            return true;
          }

          try {
            const existingUsers = await db
              .select()
              .from(users)
              .where(eq(users.email, user.email || ''))
              .limit(1);

            const dbUser = existingUsers[0];

            if (!dbUser) {
              const result = await db.select({ value: drizzleCount() }).from(users);
              const userCount = result[0]?.value || 0;
              const role = userCount === 0 ? 'admin' : 'student';

              const [newUser] = await db
                .insert(users)
                .values({
                  email: user.email || '',
                  firstName: user.name?.split(' ')[0] || '',
                  lastName: user.name?.split(' ').slice(1).join(' ') || '',
                  role,
                })
                .returning();

              user.id = newUser.id;
              user.role = newUser.role;
            }
            else {
              user.id = dbUser.id;
              user.role = dbUser.role;
            }
          }
          catch (dbError) {
            console.error('Database operation failed in signIn callback:', dbError);
            return true;
          }
        }
        catch (error) {
          console.error('Unexpected error in signIn callback:', error);
          return true;
        }
      }
      return true;
    },
  },
  pages: authConfig.pages,
  debug: authConfig.debug,
};
