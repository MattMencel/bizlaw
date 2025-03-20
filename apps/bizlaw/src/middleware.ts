import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Explicitly opt out of Edge Runtime
export const runtime = 'nodejs';

export async function middleware(request: NextRequest) {
  // Simple middleware that doesn't need database access
  const path = request.nextUrl.pathname;

  // Add any path-based logic that doesn't require DB access
  // For example, redirects, headers, etc.

  // For API routes that need DB access, handle the DB initialization
  // in the route handlers themselves, not in middleware

  return NextResponse.next();
}

// Optional: Configure paths that will invoke this middleware
export const config = {
  matcher: [
    // Apply to all routes except static files, api routes, and _next
    '/((?!_next/static|_next/image|favicon.ico|api/).*)',
  ],
};
