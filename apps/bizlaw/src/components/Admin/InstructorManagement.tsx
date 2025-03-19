import axios from 'axios';
import { useState, useEffect } from 'react';

interface User {
  id: number
  email: string
  firstName: string
  lastName: string
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
  const handleRoleChange = async (userId: number, isInstructor: boolean) => {
    try {
      const role = isInstructor ? 'professor' : 'student';
      await axios.put(`/api/admin/users/${userId}/role`, { role });

      // Update local state
      setUsers(users.map(user => (user.id === userId ? { ...user, role } : user)));
    }
    catch (err) {
      console.error('Error updating user role:', err);
      setError('Failed to update user role');
    }
  };

  if (loading) return <div>Loading users...</div>;
  if (error) return <div className="error">{error}</div>;

  return (
    <div className="instructor-management">
      <h2>Manage Instructors</h2>

      {users.length === 0
        ? (
          <p>No users found.</p>
        )
        : (
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Current Role</th>
                <th>Instructor</th>
              </tr>
            </thead>
            <tbody>
              {users.map(user => (
                <tr key={user.id}>
                  <td>{`${user.firstName} ${user.lastName}`}</td>
                  <td>{user.email}</td>
                  <td>{user.role}</td>
                  <td>
                    <input
                      type="checkbox"
                      checked={user.role === 'professor'}
                      onChange={e => handleRoleChange(user.id, e.target.checked)}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
    </div>
  );
};

export default InstructorManagement;
