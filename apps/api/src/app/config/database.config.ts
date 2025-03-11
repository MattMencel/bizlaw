import { registerAs } from '@nestjs/config';
import { SequelizeModuleOptions } from '@nestjs/sequelize';
import * as dotenv from 'dotenv';

// Load environment variables
dotenv.config();

export default registerAs('database', () => ({
  dialect: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 5432,
  username: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'business_law',
  autoLoadModels: true,
  synchronize: process.env.NODE_ENV !== 'production',
  logging: process.env.NODE_ENV !== 'production',
  define: {
    underscored: true, // Use snake_case for all models by default
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
  },
}));
