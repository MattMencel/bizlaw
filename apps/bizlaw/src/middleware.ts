import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { getToken } from 'next-auth/jwt';

// Explicitly opt out of Edge Runtime
export const runtime = 'nodejs';

export async function middleware(request: NextRequest) {
  // Get the pathname
  const path = request.nextUrl.pathname;

  // Handle admin routes protection
  if (path.startsWith('/admin')) {
    const session = await getToken({
      req: request,
      secret: process.env.NEXTAUTH_SECRET,
    });

    // Check if the user is authenticated and is an admin
    if (!session || session.role !== 'admin') {
      console.info(`Unauthorized access attempt to admin route: ${path}`);
      // Redirect to login or unauthorized page
      return NextResponse.redirect(new URL(`/auth/login?from=${encodeURIComponent(path)}`, request.url));
    }

    console.info(`Admin access granted for route: ${path}`);
  }

  // Handle any other middleware logic for non-admin routes
  // Add any path-based logic that doesn't require DB access
  // For example, redirects, headers, etc.

  // For API routes that need DB access, handle the DB initialization
  // in the route handlers themselves, not in middleware

  return NextResponse.next();
}

// Configure paths that will invoke this middleware
export const config = {
  matcher: [
    // Apply to admin routes
    '/admin/:path*',

    // Apply to other routes except static files, API routes, and _next
    // Comment this out if you only want to protect admin routes
    '/((?!_next/static|_next/image|favicon.ico|api/).*)',
  ],
};
