import type { Metadata } from 'next';
import { Inter } from 'next/font/google';

import AuthProvider from '@/components/auth/AuthProvider';
import MainLayout from '@/components/layout/MainLayout';

import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: {
    default: 'Business Law',
    template: '%s | Business Law',
  },
  description: 'A web application for Business Law education',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <AuthProvider>
          <MainLayout>{children}</MainLayout>
        </AuthProvider>
      </body>
    </html>
  );
}
