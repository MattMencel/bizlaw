import { NextApiRequest, NextApiResponse } from 'next';
import { getSession } from 'next-auth/react';
import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3333/api';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse,
) {
  const session = await getSession({ req });

  // Check if user is logged in and is admin
  if (!session || session.user.role !== 'admin') {
    return res.status(401).json({ message: 'Unauthorized' });
  }

  const { id } = req.query;

  if (req.method === 'PUT') {
    try {
      const { role } = req.body;

      if (!role || !['student', 'professor', 'admin'].includes(role)) {
        return res.status(400).json({ message: 'Invalid role' });
      }

      const response = await axios.put(
        `${API_URL}/users/${id}`,
        { role },
        {
          headers: {
            Authorization: `Bearer ${session.accessToken}`,
          },
        },
      );

      return res.status(200).json(response.data);
    } catch (error) {
      console.error('Error updating user role:', error);
      return res.status(500).json({ message: 'Failed to update user role' });
    }
  } else {
    res.setHeader('Allow', ['PUT']);
    return res.status(405).end(`Method ${req.method} Not Allowed`);
  }
}
