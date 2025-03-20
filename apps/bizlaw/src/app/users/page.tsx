'use client';

import { useState, useEffect } from 'react';

import type { User } from '@/lib/db/schema';
import { UserRole } from '@/lib/db/schema';

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);

  useEffect(() => {
    const fetchUsers = async () => {
      const response = await fetch('/api/users');
      const data = await response.json();
      setUsers(data);
    };

    fetchUsers();
  }, []);

  return (
    <div>
      <h1>Users</h1>
      <ul>
        {users.map(user => (
          <li key={user.id}>
            <strong>
              {user.firstName}
              {' '}
              {user.lastName}
            </strong>
            {' '}
            -
            {user.role === UserRole.ADMIN
              ? '(Admin)'
              : user.role === UserRole.PROFESSOR
                ? '(Professor)'
                : '(Student)'}
          </li>
        ))}
      </ul>
    </div>
  );
}
