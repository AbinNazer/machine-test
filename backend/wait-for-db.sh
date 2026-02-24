#!/bin/sh
# wait-for-db.sh

set -e

# Default to environment variables from .env
host="${MYSQL_HOST:-db}"
port="${MYSQL_PORT:-3306}"

echo "Waiting for MySQL at $host:$port..."

# Loop until MySQL is available
until nc -z "$host" "$port"; do
  echo "MySQL is unavailable, sleeping..."
  sleep 2
done

echo "MySQL is up! Starting Gunicorn..."
exec gunicorn backend.wsgi:application --bind 0.0.0.0:8000 --timeout 120
