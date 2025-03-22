import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth/next';

import { authOptions } from '@/lib/auth/auth';
import { getDb, initDb } from '@/lib/db/db';
import { users } from '@/lib/db/schema';

export async function GET() {
  try {
    // Verify user is authenticated and is admin
    const session = await getServerSession(authOptions);
    if (!session?.user || session.user.role !== 'admin') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }

    await initDb();
    const db = getDb();

    // Get all users
    const allUsers = await db.select().from(users);

    return NextResponse.json(allUsers);
  } catch (error) {
    console.error('Error fetching users:', error);
    return NextResponse.json({ error: 'Failed to fetch users' }, { status: 500 });
  }
}
