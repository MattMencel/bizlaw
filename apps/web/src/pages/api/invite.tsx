// filepath: /Users/matt.mencel/development/workboard/sandbox/business-law-nx/apps/web/src/pages/api/invite.ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { Sequelize } from 'sequelize';

// Define invitation model without decorators
const sequelize = new Sequelize(process.env.DATABASE_URL as string, {
  dialect: 'postgres',
});

const Invitation = sequelize.define(
  'Invitation',
  {
    id: {
      primaryKey: true,
      autoIncrement: true,
      type: Sequelize.INTEGER,
    },
    email: {
      allowNull: false,
      type: Sequelize.STRING(255),
    },
    accepted: {
      allowNull: false,
      type: Sequelize.BOOLEAN,
      defaultValue: false,
    },
  },
  {
    tableName: 'invitations',
    createdAt: 'created_at',
    updatedAt: 'updated_at',
  },
);

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse,
) {
  if (req.method === 'POST') {
    try {
      const { email } = req.body;

      const invitation = await Invitation.create({ email });

      res.status(201).json(invitation);
    } catch (error) {
      console.error('Failed to create invitation:', error);
      res.status(500).json({ error: 'Failed to create invitation' });
    }
  } else {
    console.error('Method not allowed:', req.method);
    res.status(405).json({ error: 'Method not allowed' });
  }
}
