import type { Config } from 'drizzle-kit';
import * as dotenv from 'dotenv';
import path from 'path';

// Load environment variables
dotenv.config();

// Define paths more explicitly with absolute paths
const MIGRATIONS_OUT_DIR = path.join(process.cwd(), 'drizzle');

export default {
  schema: path.join(process.cwd(), 'apps/bizlaw/src/lib/db/schema.ts'),
  out: MIGRATIONS_OUT_DIR,
  dialect: 'postgresql',
  dbCredentials: {
    connectionString: process.env.POSTGRES_URL_NON_POOLING || '',
    ssl:
      process.env.NODE_ENV === 'development' || process.env.POSTGRES_REJECT_UNAUTHORIZED === 'false'
        ? { rejectUnauthorized: false }
        : true,
  },
} satisfies Config;
