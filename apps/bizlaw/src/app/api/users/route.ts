import { NextResponse } from 'next/server';

import { getDb } from '@/lib/db/db';
import type { User, NewUser } from '@/lib/db/schema';
import { users } from '@/lib/db/schema';

export async function GET() {
  const db = getDb();

  try {
    const allUsers: User[] = await db.select().from(users);
    return NextResponse.json(allUsers);
  }
  catch (_error) {
    return NextResponse.json(
      { error: 'Failed to fetch users' },
      { status: 500 },
    );
  }
}

export async function POST(request: Request) {
  const db = getDb();

  try {
    const body = await request.json();

    // Type checking with NewUser type
    const userData: NewUser = {
      email: body.email,
      firstName: body.firstName,
      lastName: body.lastName,
      role: body.role,
    };

    const [newUser] = await db.insert(users).values(userData).returning();

    return NextResponse.json(newUser);
  }
  catch (_error) {
    return NextResponse.json(
      { error: 'Failed to create user' },
      { status: 500 },
    );
  }
}
