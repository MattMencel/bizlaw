import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

import { initDb } from './lib/db/db';

// List of paths that should trigger DB initialization
const DB_DEPENDENT_PATHS = ['/api/', '/auth/'];

export async function middleware(request: NextRequest) {
  const path = request.nextUrl.pathname;

  // Check if the request is for a route that needs DB access
  if (DB_DEPENDENT_PATHS.some(p => path.includes(p))) {
    try {
      await initDb();
    }
    catch (error) {
      console.error('Middleware: Failed to initialize database:', error);
      // Continue anyway to let the route handle the error
    }
  }

  return NextResponse.next();
}

// Optional: configure paths that will invoke this middleware
export const config = {
  matcher: ['/api/:path*', '/auth/:path*'],
};
