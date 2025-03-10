import NextAuth from 'next-auth';
import GoogleProvider from 'next-auth/providers/google';
import { NextAuthOptions } from 'next-auth';
import axios from 'axios';

// Very important: use the correct API_URL format
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3333';

const options: NextAuthOptions = {
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID as string,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET as string,
    }),
  ],
  secret: process.env.NEXTAUTH_SECRET as string,
  callbacks: {
    async signIn({ user }) {
      try {
        console.log('Starting signIn callback, checking user:', user.email);

        // Make sure to add the /api prefix if your NestJS app uses it
        const checkUserUrl = `${API_URL}/api/auth/check-user`;
        console.log('Making request to:', checkUserUrl);

        const response = await axios.post(checkUserUrl, {
          email: user.email,
          name: user.name,
          image: user.image,
          checkFirstUser: true,
        });

        console.log('Check user response:', response.data);

        if (response.data && response.data.role) {
          user.role = response.data.role;
          user.id = response.data.id;
        } else {
          user.role = 'student';
        }

        return true;
      } catch (error) {
        console.error('Error checking user:', error);
        // If API fails, default to student and allow login
        user.role = 'student';
        return true;
      }
    },

    async jwt({ token, user }) {
      if (user) {
        token.id = user.id as string;
        token.role = user.role as string; // Add the role to the token
      }
      return token;
    },

    async session({ session, token }) {
      // Add user information to the session
      if (session.user) {
        session.user.id = token.id as string;
        session.user.role = token.role as string; // Add the role to the session
      }
      return session;
    },
  },
  pages: {
    signIn: '/login',
    error: '/login',
  },
};

export default NextAuth(options);
