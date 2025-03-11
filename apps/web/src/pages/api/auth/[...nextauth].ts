import NextAuth from 'next-auth';
import GoogleProvider from 'next-auth/providers/google';
import { NextAuthOptions } from 'next-auth';
import axios from 'axios';

// Very important: use the correct API_URL format for server-to-server communication
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

        if (response.data) {
          // Store the user's ID and role properly
          user.id = response.data.id;
          user.role = response.data.role;
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
      // Removed 'account' parameter
      // This is called whenever a JWT is created or updated
      if (user) {
        // Initial sign in
        token.id = user.id;
        token.role = user.role;

        try {
          // Get JWT token from your API for backend authorization
          const response = await axios.post(`${API_URL}/api/auth/login`, {
            email: user.email,
          });

          if (response.data && response.data.accessToken) {
            token.accessToken = response.data.accessToken;
            console.log(
              'JWT token obtained:',
              response.data.accessToken.substring(0, 10) + '...',
            );
          } else {
            console.error('No access token returned from API');
          }
        } catch (error) {
          console.error('Error getting JWT token:', error);
        }
      }
      return token;
    },

    async session({ session, token }) {
      // This is called whenever a session is accessed
      if (session.user) {
        session.user.id = token.id as string;
        session.user.role = token.role as string;
        session.accessToken = token.accessToken as string;

        console.log(
          'Session created with accessToken:',
          token.accessToken ? 'present' : 'missing',
        );
      }
      return session;
    },
  },
  pages: {
    signIn: '/login',
    error: '/login',
  },
  debug: process.env.NODE_ENV === 'development',
};

export default NextAuth(options);
