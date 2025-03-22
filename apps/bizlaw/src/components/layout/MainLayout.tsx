'use client';

import Image from 'next/image';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useSession, signOut } from 'next-auth/react';
import { useState, useEffect } from 'react';
import type { ReactNode } from 'react';
import { FiUser, FiMenu, FiX, FiLogOut, FiSettings, FiChevronDown } from 'react-icons/fi';

type MainLayoutProps = {
  children: ReactNode;
};

export default function MainLayout({ children }: MainLayoutProps) {
  const { data: session, status } = useSession();
  const pathname = usePathname();
  const router = useRouter();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [userMenuOpen, setUserMenuOpen] = useState(false);

  // Close user menu when clicking outside
  useEffect(() => {
    const handleOutsideClick = () => {
      if (userMenuOpen) setUserMenuOpen(false);
    };

    document.addEventListener('click', handleOutsideClick);
    return () => document.removeEventListener('click', handleOutsideClick);
  }, [userMenuOpen]);

  const isActive = (path: string) => pathname === path || pathname?.startsWith(`${path}/`);

  const isAdmin = session?.user?.role === 'admin';
  const isInstructor = ['professor', 'instructor'].includes(session?.user?.role as string);

  const handleSignOut = async () => {
    await signOut({ redirect: false });
    router.push('/');
  };

  // Define navigation based on user role
  const navigation = [
    { name: 'Dashboard', href: '/dashboard' },
    { name: 'Cases', href: '/cases' },
    ...(isInstructor || isAdmin ? [{ name: 'Course Admin', href: '/course-admin' }] : []),
    ...(isAdmin ? [{ name: 'Admin', href: '/admin' }] : []),
  ];

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
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
                {status === 'loading' ? (
                  <div className="h-8 w-8 rounded-full bg-gray-200 animate-pulse" />
                ) : status === 'authenticated' ? (
                  <div className="relative">
                    <button
                      type="button"
                      onClick={e => {
                        e.stopPropagation();
                        setUserMenuOpen(!userMenuOpen);
                      }}
                      className="flex items-center gap-2 text-sm px-3 py-2 rounded-md hover:bg-gray-100"
                    >
                      {session.user?.image ? (
                        <Image
                          src={session.user.image}
                          alt="User avatar"
                          width={32}
                          height={32}
                          className="h-8 w-8 rounded-full"
                        />
                      ) : (
                        <div className="h-8 w-8 rounded-full bg-blue-500 flex items-center justify-center text-white">
                          <FiUser className="h-4 w-4" />
                        </div>
                      )}
                      <span className="hidden md:block">{session.user?.name || 'Profile'}</span>
                      <FiChevronDown className="h-4 w-4" />
                    </button>

                    {/* Dropdown menu */}
                    {userMenuOpen && (
                      <div className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-10 ring-1 ring-black ring-opacity-5">
                        <div className="px-4 py-2 text-xs text-gray-500">
                          Signed in as
                          <div className="font-medium text-gray-900">{session.user?.email}</div>
                          <div className="mt-1 text-gray-500">Role: {session.user?.role || 'student'}</div>
                        </div>
                        <hr className="my-1" />
                        <Link
                          href="/profile"
                          className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center"
                          onClick={() => setUserMenuOpen(false)}
                        >
                          <FiSettings className="mr-2 h-4 w-4" /> Profile Settings
                        </Link>
                        <button
                          onClick={handleSignOut}
                          className="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center"
                        >
                          <FiLogOut className="mr-2 h-4 w-4" /> Sign Out
                        </button>
                      </div>
                    )}
                  </div>
                ) : (
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
                  {mobileMenuOpen ? (
                    <FiX className="block h-6 w-6" aria-hidden="true" />
                  ) : (
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

            {status === 'authenticated' && (
              <button
                onClick={handleSignOut}
                className="block w-full text-left pl-3 pr-4 py-2 border-l-4 border-transparent text-base font-medium text-gray-500 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-700"
              >
                <div className="flex items-center">
                  <FiLogOut className="mr-2" /> Sign Out
                </div>
              </button>
            )}
          </div>
        </div>
      </header>

      {/* Main content */}
      <main className="py-6 flex-grow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">{children}</div>
      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-200 mt-auto">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="py-6 md:flex md:items-center md:justify-between">
            <div className="text-center md:text-left">
              <p className="text-sm text-gray-500">&copy; 2024 Business Law. All rights reserved.</p>
            </div>
            <div className="mt-4 flex justify-center md:mt-0">
              <Link href="/about" className="text-sm text-gray-500 hover:text-gray-600 mr-4">
                About
              </Link>
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
