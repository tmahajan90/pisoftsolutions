#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# Wait for database to be ready
echo "Waiting for database to be ready..."
until bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" > /dev/null 2>&1; do
  echo "Database is unavailable - sleeping"
  sleep 1
done
echo "Database is ready!"

# Run database migrations
echo "Running database migrations..."
bundle exec rails db:migrate

# Seed the database if needed
if [ "$RAILS_ENV" = "development" ]; then
  echo "Seeding database..."
  bundle exec rails db:seed
fi

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
