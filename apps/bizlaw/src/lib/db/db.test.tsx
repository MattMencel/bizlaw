import fs from 'fs';

import { jest } from '@jest/globals';
import { neon, neonConfig } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-http';
import { drizzle as nodeDrizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';

import { closeDb, getDb, initDb } from './db';
import { runMigrations } from './migrations';
import * as schema from './schema';

// Mock external dependencies
jest.mock('@neondatabase/serverless', () => {
  const mockNeon = jest.fn().mockReturnValue({ execute: jest.fn().mockResolvedValue([{ connected: 1 }]) });
  return {
    neon: mockNeon,
    neonConfig: { fetchConnectionCache: false },
  };
});

jest.mock('drizzle-orm/neon-http', () => ({
  drizzle: jest.fn().mockReturnValue({
    execute: jest.fn().mockResolvedValue([{ connected: 1 }]),
  }),
}));

jest.mock('drizzle-orm/node-postgres', () => ({
  drizzle: jest.fn().mockReturnValue({
    execute: jest.fn().mockResolvedValue([{ connected: 1 }]),
  }),
}));

jest.mock('pg', () => {
  const mockPool = {
    end: jest.fn().mockResolvedValue(undefined),
  };
  return {
    Pool: jest.fn().mockImplementation(() => mockPool),
  };
});

jest.mock('fs', () => ({
  existsSync: jest.fn(),
  readFileSync: jest.fn(),
}));

jest.mock('./migrations', () => ({
  runMigrations: jest.fn().mockResolvedValue(undefined),
  shouldRunAutoMigrations: jest.fn().mockReturnValue(true),
}));

describe('Database module', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.resetAllMocks();
    process.env = { ...originalEnv };
    process.env.POSTGRES_URL = 'postgres://user:password@localhost:5432/database';
  });

  afterEach(async () => {
    await closeDb();
    process.env = originalEnv;
  });

  describe('initDb', () => {
    test('initializes edge runtime database connection correctly', async () => {
      process.env.NEXT_RUNTIME = 'edge';

      const db = await initDb();

      expect(neon).toHaveBeenCalledWith(process.env.POSTGRES_URL);
      expect(drizzle).toHaveBeenCalledWith(expect.anything(), { schema });
      expect(db).toBeDefined();
    });

    test('initializes Node.js runtime database connection correctly', async () => {
      delete process.env.NEXT_RUNTIME;

      const db = await initDb();

      expect(Pool).toHaveBeenCalledWith(
        expect.objectContaining({
          connectionString: process.env.POSTGRES_URL,
          ssl: expect.anything(),
        }),
      );
      expect(nodeDrizzle).toHaveBeenCalledWith(expect.anything(), { schema });
      expect(db).toBeDefined();
    });

    test('uses Supabase-specific SSL configuration for Supabase hosts', async () => {
      delete process.env.NEXT_RUNTIME;
      process.env.POSTGRES_URL = 'postgres://user:password@pooler.supabase.com:5432/database';

      await initDb();

      expect(Pool).toHaveBeenCalledWith(
        expect.objectContaining({
          ssl: { rejectUnauthorized: false },
        }),
      );
    });

    test('disables SSL verification in development when configured', async () => {
      delete process.env.NEXT_RUNTIME;
      process.env.NODE_ENV = 'development';
      process.env.POSTGRES_REJECT_UNAUTHORIZED = 'false';

      await initDb();

      expect(Pool).toHaveBeenCalledWith(
        expect.objectContaining({
          ssl: { rejectUnauthorized: false },
        }),
      );
    });

    test('uses certificate file if available', async () => {
      delete process.env.NEXT_RUNTIME;
      const mockCertContent = 'MOCK_CERTIFICATE_CONTENT';

      (fs.existsSync as jest.Mock).mockReturnValue(true);
      (fs.readFileSync as jest.Mock).mockReturnValue(mockCertContent);

      await initDb();

      expect(Pool).toHaveBeenCalledWith(
        expect.objectContaining({
          ssl: expect.objectContaining({
            ca: mockCertContent,
            rejectUnauthorized: true,
          }),
        }),
      );
    });

    test('throws error when connection string is missing', async () => {
      delete process.env.POSTGRES_URL;
      delete process.env.POSTGRES_URL_NON_POOLING;

      await expect(initDb()).rejects.toThrow('Database connection string not found');
    });

    test('runs migrations when auto-migrations are enabled', async () => {
      await initDb();

      expect(runMigrations).toHaveBeenCalled();
    });
  });

  describe('getDb', () => {
    test('returns initialized db instance', async () => {
      await initDb();
      const db = getDb();
      expect(db).toBeDefined();
    });

    test('throws error when db is not initialized', () => {
      expect(() => getDb()).toThrow('Database not initialized');
    });
  });

  describe('closeDb', () => {
    test('closes the database connection', async () => {
      await initDb();
      await closeDb();

      const mockPool = (Pool as jest.Mock).mock.results[0].value;
      expect(mockPool.end).toHaveBeenCalled();

      // Should throw after closing (db is null)
      expect(() => getDb()).toThrow('Database not initialized');
    });

    test('handles closing when not initialized', async () => {
      // Should not throw when db is already null
      await expect(closeDb()).resolves.not.toThrow();
    });
  });
});
