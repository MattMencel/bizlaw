'use client';

import Image from 'next/image';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useSession } from 'next-auth/react';
import type { ReactNode } from 'react';
import { useState } from 'react'; // Corrected: Import `useState` as a value
import { FiUser, FiMenu, FiX } from 'react-icons/fi';

type MainLayoutProps = {
  children: ReactNode
};

export default function MainLayout({ children }: MainLayoutProps) {
  const { data: session, status } = useSession();
  const pathname = usePathname();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const isActive = (path: string) => pathname === path;

  const navigation = [
    { name: 'Dashboard', href: '/dashboard' },
    { name: 'Courses', href: '/courses' },
    { name: 'Cases', href: '/cases' },
    ...(session?.user?.role === 'admin' ? [{ name: 'Admin', href: '/admin' }] : []),
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            {/* Logo and Navigation */}
            <div className="flex">
              {/* Logo */}
              <div className="flex-shrink-0 flex items-center">
                <Link href="/" className="flex items-center">
                  <Image
                    src="/logo-placeholder.svg"
                    alt="Business Law Logo"
                    width={40}
                    height={40}
                    className="h-8 w-auto"
                  />
                  <span className="ml-2 text-xl font-bold text-gray-900">Business Law</span>
                </Link>
              </div>

              {/* Desktop Navigation */}
              <nav className="hidden md:ml-8 md:flex md:space-x-8">
                {navigation.map(item => (
                  <Link
                    key={item.name}
                    href={item.href}
                    className={`inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium ${
                      isActive(item.href)
                        ? 'border-blue-500 text-gray-900'
                        : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                    }`}
                  >
                    {item.name}
                  </Link>
                ))}
              </nav>
            </div>

            {/* User Menu & Mobile Nav Button */}
            <div className="flex items-center">
              {/* User Menu */}
              <div className="ml-4 flex items-center md:ml-6">
                {status === 'loading'
                  ? (
                    <div className="h-8 w-8 rounded-full bg-gray-200 animate-pulse" />
                  )
                  : status === 'authenticated'
                    ? (
                      <Link
                        href="/profile"
                        className="flex items-center gap-2 text-sm px-3 py-2 rounded-md hover:bg-gray-100"
                      >
                        {session.user?.image
                          ? (
                            <Image
                              src={session.user.image}
                              alt="User avatar"
                              width={32}
                              height={32}
                              className="h-8 w-8 rounded-full"
                            />
                          )
                          : (
                            <div className="h-8 w-8 rounded-full bg-blue-500 flex items-center justify-center text-white">
                              <FiUser className="h-4 w-4" />
                            </div>
                          )}
                        <span className="hidden md:block">{session.user?.name || 'Profile'}</span>
                      </Link>
                    )
                    : (
                      <Link
                        href="/api/auth/signin"
                        className="inline-flex items-center justify-center rounded-md border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-blue-700"
                      >
                        Sign In
                      </Link>
                    )}
              </div>

              {/* Mobile menu button */}
              <div className="md:hidden ml-4">
                <button
                  type="button"
                  className="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100"
                  aria-controls="mobile-menu"
                  aria-expanded={mobileMenuOpen}
                  onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                >
                  <span className="sr-only">{mobileMenuOpen ? 'Close main menu' : 'Open main menu'}</span>
                  {mobileMenuOpen
                    ? (
                      <FiX className="block h-6 w-6" aria-hidden="true" />
                    )
                    : (
                      <FiMenu className="block h-6 w-6" aria-hidden="true" />
                    )}
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Mobile menu, show/hide based on menu state */}
        <div className={`md:hidden ${mobileMenuOpen ? 'block' : 'hidden'}`} id="mobile-menu">
          <div className="pt-2 pb-3 space-y-1">
            {navigation.map(item => (
              <Link
                key={item.name}
                href={item.href}
                className={`block pl-3 pr-4 py-2 border-l-4 text-base font-medium ${
                  isActive(item.href)
                    ? 'border-blue-500 text-blue-700 bg-blue-50'
                    : 'border-transparent text-gray-500 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-700'
                }`}
                onClick={() => setMobileMenuOpen(false)}
              >
                {item.name}
              </Link>
            ))}
          </div>
        </div>
      </header>

      {/* Main content */}
      <main className="py-6">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">{children}</div>
      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="py-6 md:flex md:items-center md:justify-between">
            <div className="text-center md:text-left">
              <p className="text-sm text-gray-500">&copy; 2024 Business Law. All rights reserved.</p>
            </div>
            <div className="mt-4 flex justify-center md:mt-0">
              <Link href="/terms" className="text-sm text-gray-500 hover:text-gray-600 mr-4">
                Terms
              </Link>
              <Link href="/privacy" className="text-sm text-gray-500 hover:text-gray-600">
                Privacy
              </Link>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
