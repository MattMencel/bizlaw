import NextAuth from 'next-auth';

import { authOptions } from '../../../../lib/auth/auth';

// Add debug logging for troubleshooting
console.info('NextAuth URL:', process.env.NEXTAUTH_URL);
console.info('NextAuth Secret is set:', Boolean(process.env.NEXTAUTH_SECRET));

const handler = NextAuth(authOptions);
export { handler as GET, handler as POST };
