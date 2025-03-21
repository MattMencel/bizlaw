import axios from 'axios';
import { useState, useEffect } from 'react';

interface User {
  id: string
  firstName: string
  lastName: string
  email: string
  role: string
}

const InstructorManagement = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch all users
  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const token = localStorage.getItem('token'); // Adjust based on your auth method
        const { data } = await axios.get('/api/admin/users', {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        });
        setUsers(data);
        setLoading(false);
      }
      catch (err) {
        console.error('Error fetching users:', err);
        setError('Failed to load users');
        setLoading(false);
      }
    };

    fetchUsers();
  }, []);

  // Update user role
  const handleRoleChange = async (userId: string, isInstructor: boolean) => {
    try {
      const token = localStorage.getItem('token');
      await axios.patch(
        `/api/admin/users/${userId}`,
        {
          role: isInstructor ? 'professor' : 'student',
        },
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        },
      );

      // Update the local state
      setUsers(
        users.map((user) => {
          if (user.id === userId) {
            return {
              ...user,
              role: isInstructor ? 'professor' : 'student',
            };
          }
          return user;
        }),
      );
    }
    catch (err) {
      console.error('Error updating user role:', err);
      setError('Failed to update user role');
    }
  };

  if (loading) {
    return <div>Loading users...</div>;
  }

  if (error) {
    return <div className="error">{error}</div>;
  }

  return (
    <div>
      <h2>Instructor Management</h2>
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Name
            </th>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Email
            </th>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Role
            </th>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {users.map(user => (
            <tr key={user.id}>
              <td className="px-6 py-4 whitespace-nowrap">
                {user.firstName}
                {' '}
                {user.lastName}
              </td>
              <td className="px-6 py-4 whitespace-nowrap">{user.email}</td>
              <td className="px-6 py-4 whitespace-nowrap">{user.role}</td>
              <td className="px-6 py-4 whitespace-nowrap">
                <button
                  onClick={() => handleRoleChange(user.id, user.role !== 'professor')}
                  className="text-blue-600 hover:text-blue-900"
                >
                  {user.role === 'professor' ? 'Make Student' : 'Make Instructor'}
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default InstructorManagement;
