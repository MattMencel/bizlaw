import { NextApiRequest, NextApiResponse } from 'next';

interface Instructor {
  name: string;
  email: string;
}

const instructors: Instructor[] = [];

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method === 'GET') {
    res.status(200).json(instructors);
  } else if (req.method === 'POST') {
    const { name, email } = req.body;
    instructors.push({ name, email });
    res.status(201).json({ message: 'Instructor added' });
  } else {
    res.status(405).json({ message: 'Method not allowed' });
  }
}
