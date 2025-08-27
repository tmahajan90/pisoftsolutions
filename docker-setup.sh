#!/bin/bash

echo "🚀 Setting up Docker environment for Pisoft Solutions Rails App..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build and start the containers
echo "📦 Building and starting containers..."
docker-compose up --build -d

# Wait for the database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 10

# Run database setup
echo "🗄️  Setting up database..."
docker-compose exec web bundle exec rails db:create db:migrate db:seed

echo "✅ Setup complete!"
echo ""
echo "🌐 Your Rails application is now running at: http://localhost:3000"
echo "🗄️  Database is accessible at: localhost:5432"
echo ""
echo "📋 Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Stop containers: docker-compose down"
echo "  - Restart: docker-compose restart"
echo "  - Rails console: docker-compose exec web rails console"
echo "  - Database console: docker-compose exec web rails dbconsole"
