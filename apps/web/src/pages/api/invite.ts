import { NextApiRequest, NextApiResponse } from 'next';
import nodemailer from 'nodemailer';
import { Invitation } from '@business-law-nx/api/app/models/invitation.model';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse,
) {
  if (req.method === 'POST') {
    const { email } = req.body;

    // Store the invited instructor's email in the database
    try {
      await Invitation.create({ email });

      // Send invitation email
      const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
          user: process.env.GMAIL_USER,
          pass: process.env.GMAIL_PASS,
        },
      });

      const mailOptions = {
        from: process.env.GMAIL_USER,
        to: email,
        subject: 'You are invited to join as an instructor',
        text: `You have been invited to join as an instructor. Please login using your Google account: http://localhost:3000/login`,
      };

      await transporter.sendMail(mailOptions);
      res.status(200).json({ message: 'Invitation sent' });
    } catch {
      res.status(500).json({ message: 'Failed to send invitation' });
    }
  } else {
    res.status(405).json({ message: 'Method not allowed' });
  }
}
