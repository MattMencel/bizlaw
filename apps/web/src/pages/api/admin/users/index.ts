import { NextApiRequest, NextApiResponse } from 'next';
import { getSession } from 'next-auth/react';
import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3333';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse,
) {
  const session = await getSession({ req });

  // Check if user is logged in and is admin
  if (!session) {
    return res.status(401).json({ message: 'Not authenticated' });
  }

  if (session.user.role !== 'admin') {
    return res
      .status(403)
      .json({ message: 'Not authorized - admin role required' });
  }

  // Debug: Check if token exists
  console.log('Session token exists:', !!session.accessToken);

  if (!session.accessToken) {
    console.log('No access token available in session');
    return res
      .status(401)
      .json({ message: 'Missing access token - please login again' });
  }

  if (req.method === 'GET') {
    try {
      console.log(`Fetching users from: ${API_URL}/api/users`);

      const response = await axios.get(`${API_URL}/api/users`, {
        headers: {
          Authorization: `Bearer ${session.accessToken}`,
        },
      });

      return res.status(200).json(response.data);
    } catch (error) {
      console.error('Error fetching users:', error);

      if (axios.isAxiosError(error)) {
        console.error('Status:', error.response?.status);
        console.error(
          'Error details:',
          error.response?.data || 'No response data',
        );
        console.error('Requested URL:', error.config?.url);

        if (error.response?.status === 401) {
          return res
            .status(401)
            .json({
              message: 'Authentication failed - JWT token may be invalid',
            });
        }
      }

      return res.status(500).json({ message: 'Failed to fetch users' });
    }
  } else {
    res.setHeader('Allow', ['GET']);
    return res.status(405).end(`Method ${req.method} Not Allowed`);
  }
}
