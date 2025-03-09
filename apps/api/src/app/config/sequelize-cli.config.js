const dotenv = require('dotenv');

// Try to load .env file if exists
try {
  dotenv.config();
} catch (e) {
  console.log('No .env file found or error loading it');
}

module.exports = {
  development: {
    dialect: 'postgres',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    username: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_NAME || 'business_law',
    migrationStorageTableName: 'SequelizeMeta'
  },
  production: {
    dialect: 'postgres',
    host: process.env.DB_HOST || 'postgres',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    username: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_NAME || 'business_law',
    migrationStorageTableName: 'SequelizeMeta',
    logging: false
  }
};