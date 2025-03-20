#!/bin/bash
set -e

echo "Environment check:"
echo "DB_HOST: $DB_HOST"
echo "DB_PORT: $DB_PORT"
echo "DB_USER: $DB_USER"
echo "DB_NAME: $DB_NAME"
echo "NEXTAUTH_URL: $NEXTAUTH_URL"
echo "NEXTAUTH_SECRET is set: $([ -n "$NEXTAUTH_SECRET" ] && echo "yes" || echo "no")"
echo "AUTO_MIGRATE: $AUTO_MIGRATE"

# Wait for database to be ready
echo "Waiting for PostgreSQL to be ready at $DB_HOST:$DB_PORT..."
max_retries=30
retry_count=0

# Try to connect to PostgreSQL
until pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME; do
  retry_count=$((retry_count + 1))
  if [ $retry_count -ge $max_retries ]; then
    echo "PostgreSQL is still not available after $max_retries retries. Starting app anyway..."
    break
  fi
  echo "PostgreSQL is unavailable - sleeping for 2 seconds (retry $retry_count/$max_retries)"
  sleep 2
done

if [ $retry_count -lt $max_retries ]; then
  echo "PostgreSQL is up!"
fi

# Make /tmp writable for non-root users (Next.js needs this)
chmod 777 /tmp

# Start the application
echo "Starting application with: $@"
exec "$@"
