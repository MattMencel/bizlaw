#!/bin/sh
set -e

echo "Creating migration script..."
cat >run-migrations.js <<'EOF'
const { Sequelize } = require('sequelize');
const path = require('path');
const fs = require('fs');

// Load environment variables from CLI config file
const config = require('./config/sequelize-cli.config');
const env = process.env.NODE_ENV || 'development';
const dbConfig = config[env];

// Create Sequelize instance
const sequelize = new Sequelize(
  dbConfig.database,
  dbConfig.username,
  dbConfig.password,
  {
    host: dbConfig.host,
    port: dbConfig.port,
    dialect: dbConfig.dialect,
    logging: message => console.log(`[DB] ${message}`),
  }
);

async function runMigrations() {
  try {
    // Check connection
    await sequelize.authenticate();
    console.log('Database connection established successfully.');

    // Create migration metadata table if it doesn't exist
    await sequelize.query(`
      CREATE TABLE IF NOT EXISTS "SequelizeMeta" (
        "name" VARCHAR(255) NOT NULL PRIMARY KEY
      );
    `);

    // Read all SQL files from migrations directory
    const migrationDir = './migrations';
    const migrationFiles = fs.readdirSync(migrationDir)
      .filter(file => file.endsWith('.sql'))
      .sort(); // Sort to ensure consistent ordering
      
    console.log(`Found ${migrationFiles.length} migration files.`);

    // For each migration file
    for (const file of migrationFiles) {
      // Check if this migration has already been applied
      const [existingMigrations] = await sequelize.query(
        'SELECT * FROM "SequelizeMeta" WHERE name = :fileName',
        { 
          replacements: { fileName: file },
          type: sequelize.QueryTypes.SELECT
        }
      );
      
      if (existingMigrations) {
        console.log(`Migration ${file} has already been applied.`);
        continue;
      }
      
      console.log(`Applying migration: ${file}`);
      
      try {
        // Read SQL file content
        const sqlPath = path.join(migrationDir, file);
        const sql = fs.readFileSync(sqlPath, 'utf8');
        
        // Split SQL content into statements (handling comments and multi-line statements)
        const statements = sql
          .replace(/--.*$/gm, '') // Remove SQL comments
          .split(';')
          .filter(stmt => stmt.trim());
        
        // Execute all statements in a transaction
        await sequelize.transaction(async transaction => {
          for (const statement of statements) {
            if (statement.trim()) {
              try {
                await sequelize.query(statement, { transaction });
              } catch (error) {
                // If the error is about relation already existing, we can continue
                if (error.message.includes('already exists')) {
                  console.log(`Note: ${error.message}`);
                } else {
                  throw error; // Re-throw other errors
                }
              }
            }
          }
          
          // Mark migration as completed
          await sequelize.query(
            'INSERT INTO "SequelizeMeta" (name) VALUES (:fileName)',
            { 
              replacements: { fileName: file },
              transaction
            }
          );
        });
        
        console.log(`Migration ${file} applied successfully.`);
      } catch (error) {
        console.error(`Error applying migration ${file}:`, error.message);
        // We don't exit here to allow the application to start 
        // even if some migrations fail
      }
    }
    
    console.log('All migrations processed.');
  } catch (error) {
    console.error('Migration process error:', error.message);
    // Don't exit, allow application to start anyway
  } finally {
    await sequelize.close();
  }
}

// Run the migrations
runMigrations();
EOF

echo "Running database migrations..."
node run-migrations.js

echo "Starting application..."
exec node main.js
