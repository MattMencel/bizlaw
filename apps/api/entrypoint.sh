#!/bin/bash
set -e

# Function to check database connection
check_db_connection() {
  echo "Checking database connection details:"
  echo "DB_HOST: ${DB_HOST}"
  echo "DB_PORT: ${DB_PORT}"
  echo "DB_NAME: ${DB_NAME}"
  echo "DB_USER: ${DB_USER}"
  echo "DB_DIALECT: ${DB_DIALECT:-postgres}"

  # Test direct connection with pg_isready
  if command -v pg_isready >/dev/null 2>&1; then
    echo "Testing PostgreSQL connection with pg_isready..."
    if pg_isready -h "${DB_HOST}" -p "${DB_PORT}" -d "${DB_NAME}" -U "${DB_USER}"; then
      echo "PostgreSQL is ready"
    else
      echo "PostgreSQL is not ready"
    fi
  else
    echo "pg_isready not available, skipping direct connection test"
  fi
}

# Function to wait for database with exponential backoff
wait_for_db() {
  echo "Waiting for database to be ready..."
  local max_attempts=10
  local timeout=1
  local attempt=1
  local total_wait=0

  # Print connection details for diagnostic purposes
  check_db_connection

  while [ "${attempt}" -le "${max_attempts}" ]; do
    echo "Connection attempt ${attempt} of ${max_attempts}..."

    # Test with a simple database connection query
    if PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -c "SELECT 1" >/dev/null 2>&1; then
      echo "Database is ready via direct psql!"
      return 0
    fi

    echo "Database not ready yet, waiting ${timeout}s..."
    sleep "${timeout}"
    total_wait=$((total_wait + timeout))

    # Increase timeout exponentially (1s, 2s, 4s, 8s, 16s)
    timeout=$((timeout * 2))
    attempt=$((attempt + 1))

    # Check if we've waited too long
    if [ "${total_wait}" -gt 30 ]; then
      echo "Timeout reached (30s). Database is not available."
      return 1
    fi
  done

  echo "Failed to connect to database after ${attempt} attempts"
  return 1
}

# Wait for database
if wait_for_db; then
  echo "Running Sequelize migrations..."

  # Create temporary config file for Sequelize CLI in the Docker container
  echo "Creating temporary Sequelize configuration for Docker environment..."

  mkdir -p /app/config
  cat >/app/config/sequelize.js <<EOL
module.exports = {
  development: {
    username: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_NAME || 'business_law',
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    dialect: process.env.DB_DIALECT || 'postgres',
    logging: console.log,
  },
  test: {
    username: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_NAME || 'business_law',
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    dialect: process.env.DB_DIALECT || 'postgres',
    logging: false,
  },
  production: {
    username: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_NAME || 'business_law',
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    dialect: process.env.DB_DIALECT || 'postgres',
    logging: false,
  }
};
EOL

  # Use the /app/migrations directory since we know it exists
  MIGRATIONS_PATH="/app/migrations"

  echo "Using migrations path: ${MIGRATIONS_PATH}"
  echo "Checking migrations directory content:"
  ls -la "${MIGRATIONS_PATH}"

  # Execute migrations using the correct paths (without models path)
  echo "Running migrations..."
  NODE_ENV=development npx sequelize-cli db:migrate \
    --config /app/config/sequelize.js \
    --migrations-path "${MIGRATIONS_PATH}" \
    --debug

  migration_exit_code=$?

  if [ $migration_exit_code -ne 0 ]; then
    echo "Warning: Migrations failed with exit code ${migration_exit_code}, but continuing startup"
  else
    echo "Migrations completed successfully."
  fi

  echo "Starting application..."
  exec node main.js
else
  echo "Could not connect to database, exiting"
  exit 1
fi
