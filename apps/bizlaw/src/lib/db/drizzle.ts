import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';

import * as schema from './schema';

// For Next.js edge runtime
let client: postgres.Sql | null = null;
let db: ReturnType<typeof drizzle> | null = null;

export function getDb() {
  if (!db) {
    if (!client) {
      const connectionString
        = process.env.DATABASE_URL
          || `postgres://${process.env.DB_USER || 'postgres'}:${process.env.DB_PASSWORD || 'postgres'}@${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || '5432'}/${process.env.DB_NAME || 'business_law'}`;

      // Connection options
      const options = {
        ssl:
          process.env.DB_SSL === 'true'
            ? { rejectUnauthorized: false }
            : undefined,
      };

      client = postgres(connectionString, options);
    }

    db = drizzle(client, { schema });
  }

  return db;
}

export function closeDb() {
  if (client) {
    client.end();
    client = null;
    db = null;
  }
}
