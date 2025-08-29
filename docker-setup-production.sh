#!/bin/bash

# Production-safe Docker setup script
# This script avoids running db:create to prevent data loss

RAILS_ENV=${RAILS_ENV:-production}

echo "🚀 Setting up Docker environment for Pisoft Solutions Rails App (${RAILS_ENV})..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found. Please create a .env file with your environment variables."
    exit 1
fi

# Load environment variables from .env file
export $(cat .env | grep -v '^#' | xargs)

# Build and start the containers
echo "📦 Building and starting containers..."
RAILS_ENV=$RAILS_ENV docker-compose up --build -d

# Wait for the database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 15

# Run database setup (production-safe: no db:create)
echo "🗄️  Setting up database..."
if [ "$RAILS_ENV" = "production" ]; then
    echo "🔒 Production mode: Running migrations only (no db:create to protect data)"
    docker-compose exec -T web bundle exec rails db:migrate
else
    echo "🛠️  Development mode: Running full database setup"
    docker-compose exec -T web bundle exec rails db:create db:migrate db:seed
fi

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
echo "🔒 Database protection:"
echo "  - Database data is stored in Docker volume: postgres_data"
echo "  - Data persists across container restarts"
echo "  - Production deployments only run migrations (no db:create)"
