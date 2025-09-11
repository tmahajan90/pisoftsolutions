#!/bin/bash

# Default to development if not specified
RAILS_ENV=${RAILS_ENV:-development}

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

# Choose the appropriate docker-compose file
if [ "$RAILS_ENV" = "production" ]; then
    COMPOSE_FILE="docker-compose.prod.yml"
    echo "🏭 Using production configuration..."
else
    COMPOSE_FILE="docker-compose.yml"
    echo "🔧 Using development configuration..."
fi

# Build and start the containers
echo "📦 Building and starting containers..."
RAILS_ENV=$RAILS_ENV docker-compose -f $COMPOSE_FILE up --build -d

# Wait for the database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 15

# Run database setup
echo "🗄️  Setting up database..."
docker-compose -f $COMPOSE_FILE exec web bundle exec rails db:create db:migrate db:seed

echo "✅ Setup complete!"
echo ""
if [ "$RAILS_ENV" = "production" ]; then
    echo "🌐 Your Rails application is now running at:"
    echo "   - IP: http://195.250.24.176:3000/"
    echo "   - Domain: http://pisoftsolutions.in"
    echo "🔧 Environment: $RAILS_ENV (Production)"
    echo ""
    echo "📋 Useful commands:"
    echo "  - View logs: docker-compose -f $COMPOSE_FILE logs -f"
    echo "  - Stop containers: docker-compose -f $COMPOSE_FILE down"
    echo "  - Restart: docker-compose -f $COMPOSE_FILE restart"
    echo "  - Rails console: docker-compose -f $COMPOSE_FILE exec web rails console"
    echo "  - Database console: docker-compose -f $COMPOSE_FILE exec web rails dbconsole"
    echo ""
    echo "🎯 Asset serving has been optimized for both IP and domain access!"
else
    echo "🌐 Your Rails application is now running at: http://localhost:3000"
    echo "🗄️  Database is accessible at: localhost:5432"
    echo "🔧 Environment: $RAILS_ENV"
    echo ""
    echo "📋 Useful commands:"
    echo "  - View logs: docker-compose -f $COMPOSE_FILE logs -f"
    echo "  - Stop containers: docker-compose -f $COMPOSE_FILE down"
    echo "  - Restart: docker-compose -f $COMPOSE_FILE restart"
    echo "  - Rails console: docker-compose -f $COMPOSE_FILE exec web rails console"
    echo "  - Database console: docker-compose -f $COMPOSE_FILE exec web rails dbconsole"
    echo ""
    echo "🚀 For production: RAILS_ENV=production ./docker-setup.sh"
fi
