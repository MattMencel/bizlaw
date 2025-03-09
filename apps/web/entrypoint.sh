#!/bin/sh
set -e

echo "Waiting for API to be ready..."
# Using curl utility to check if API is up
# The loop will continue until the API is reachable or max retries reached
RETRIES=30
until curl -s "$NEXT_PUBLIC_API_URL/api/health" || [ $RETRIES -eq 0 ]; do
  echo "Waiting for API server ($NEXT_PUBLIC_API_URL), $RETRIES remaining attempts..."
  RETRIES=$((RETRIES - 1))
  sleep 2
done

echo "Starting web application..."
exec npx next start
