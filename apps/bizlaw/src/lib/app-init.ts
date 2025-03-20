import { initDb } from './db/db';

let initialized = false;

export async function initializeApp() {
  if (initialized) {
    return;
  }

  console.info('Initializing application...');

  // Initialize database
  await initDb();

  // Add any other initialization logic here

  initialized = true;
  console.info('Application initialization complete');
}
