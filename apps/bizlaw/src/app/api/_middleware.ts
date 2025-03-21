import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';

import { runMigrations, shouldRunAutoMigrations } from '@/lib/db/migrations';

// Only run in Node.js runtime
export const runtime = 'nodejs';

// Static flag shared across all instances to prevent duplicate runs
// This approach works because Next.js keeps the same instance alive across requests
let globalInitialized = false;

export async function middleware(req: NextRequest) {
  // Skip migration on API endpoints that handle their own migrations
  if (req.nextUrl.pathname === '/api/admin/run-migrations' || req.nextUrl.pathname === '/api/init-db') {
    return NextResponse.next();
  }

  // Only run migrations on first request and if AUTO_MIGRATE is enabled
  if (!globalInitialized && shouldRunAutoMigrations()) {
    globalInitialized = true; // Set to true immediately to prevent concurrent runs

    try {
      console.info('Running migrations from API middleware (first request)');
      await runMigrations({ force: true });
      console.info('Migrations completed successfully from middleware');
    }
    catch (error) {
      console.error('Middleware initialization failed:', error);
      // Continue processing the request even if migrations fail
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/api/:path*'],
};
