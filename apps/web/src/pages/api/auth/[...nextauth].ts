import NextAuth from 'next-auth';
import GoogleProvider from 'next-auth/providers/google';
import { NextAuthOptions } from 'next-auth';

const invitedInstructors: string[] = [];

const options: NextAuthOptions = {
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID as string,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET as string,
    }),
  ],
  secret: process.env.NEXTAUTH_SECRET as string,
  callbacks: {
    async signIn({ user, account, profile, email, credentials }) {
      // Check if the user is an invited instructor
      if (user.email && invitedInstructors.includes(user.email)) {
        // Create the instructor account if necessary
        // In a real application, you would create the account in the database
        user.role = 'instructor'; // Assign the role
        return true;
      } else {
        return false;
      }
    },
    async session({ session, token, user }) {
      // Add user information to the session
      if (session.user) {
        session.user.id = token.id as string;
        session.user.role = token.role as string; // Add the role to the session
      }
      return session;
    },
    async jwt({ token, user, account, profile, isNewUser }) {
      if (user) {
        token.id = user.id as string;
        token.role = user.role as string; // Add the role to the token
      }
      return token;
    },
  },
};

export default NextAuth(options);
