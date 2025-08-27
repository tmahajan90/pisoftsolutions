#!/bin/bash

# Default to development if not specified
RAILS_ENV=${RAILS_ENV:-development}

echo "🚀 Setting up Docker environment for Pisoft Solutions Rails App (${RAILS_ENV})..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Generate SECRET_KEY_BASE if in production and missing
if [ "$RAILS_ENV" = "production" ]; then
    if [ -z "$SECRET_KEY_BASE" ]; then
        echo "🔑 Generating SECRET_KEY_BASE for production..."
        export SECRET_KEY_BASE=$(docker run --rm ruby:3.2.3-alpine ruby -e "require 'securerandom'; puts SecureRandom.hex(64)")
        echo "✅ SECRET_KEY_BASE generated"
    fi
fi

# Build and start the containers
echo "📦 Building and starting containers..."
RAILS_ENV=$RAILS_ENV docker-compose up --build -d

# Wait for the database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 15

# Run database setup
echo "🗄️  Setting up database..."
docker-compose exec web bundle exec rails db:create db:migrate db:seed

echo "✅ Setup complete!"
echo ""
echo "🌐 Your Rails application is now running at: http://localhost:3000"
echo "🗄️  Database is accessible at: localhost:5432"
echo "🔧 Environment: $RAILS_ENV"
echo ""
echo "📋 Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Stop containers: docker-compose down"
echo "  - Restart: docker-compose restart"
echo "  - Rails console: docker-compose exec web rails console"
echo "  - Database console: docker-compose exec web rails dbconsole"
echo ""
echo "🚀 For production: RAILS_ENV=production ./docker-setup.sh"
