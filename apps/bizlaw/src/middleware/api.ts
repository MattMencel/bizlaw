import type { NextFetchEvent, NextRequest } from 'next/server';
import { NextResponse } from 'next/server';

import { initDb } from '@/lib/db/db';

export async function apiMiddleware(req: NextRequest, event: NextFetchEvent) {
  // Only process API routes
  if (!req.nextUrl.pathname.startsWith('/api')) {
    return NextResponse.next();
  }

  try {
    // Initialize database connection for all API routes
    await initDb();
  }
  catch (error) {
    console.error('Database initialization failed in API middleware:', error);
    // Continue anyway and let the route handle the error
  }

  // Continue to the route handler
  return NextResponse.next();
}
