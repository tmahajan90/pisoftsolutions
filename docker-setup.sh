#!/bin/bash

# Default to development if not specified
RAILS_ENV=${RAILS_ENV:-development}

echo "🚀 Setting up Docker environment for Pisoft Solutions Rails App (${RAILS_ENV})..."

# Check if SSL setup is requested or if FORCE_SSL is enabled
if [ "$1" = "ssl" ] || [ "$1" = "--ssl" ]; then
    echo "🔒 SSL setup requested..."
    echo "📋 Make sure you have set DOMAIN and SUPPORT_EMAIL in your .env file"
    echo ""
    read -p "Do you want to continue with SSL setup? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔒 Starting SSL setup..."
        ./setup-ssl.sh
        exit $?
    else
        echo "⏭️  Skipping SSL setup, continuing with regular setup..."
    fi
fi

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

# Run database setup
echo "🗄️  Setting up database..."
docker-compose exec web bundle exec rails db:create db:migrate db:seed

echo "✅ Setup complete!"

# Check if SSL should be automatically set up
if [ "$FORCE_SSL" = "true" ] || [ "$FORCE_SSL" = "1" ]; then
    echo ""
    echo "🔒 FORCE_SSL is enabled - setting up SSL automatically..."
    ./auto-ssl-setup.sh
fi
echo ""
if [ "$RAILS_ENV" = "production" ]; then
    echo "🌐 Your Rails application is now running at:"
    echo "   - IP: http://195.250.24.176:3000/"
    echo "   - Domain: http://pisoftsolutions.in"
    echo "🔧 Environment: $RAILS_ENV (Production)"
    echo ""
    echo "📋 Useful commands:"
    echo "  - View logs: docker-compose logs -f"
    echo "  - Stop containers: docker-compose down"
    echo "  - Restart: docker-compose restart"
    echo "  - Rails console: docker-compose exec web rails console"
    echo "  - Database console: docker-compose exec web rails dbconsole"
    echo ""
    echo "🎯 Asset serving has been optimized for both IP and domain access!"
    echo "🔒 SSL will be automatically enabled if FORCE_SSL=true in .env"
else
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
    echo "🔒 For SSL setup: RAILS_ENV=production ./docker-setup.sh ssl"
fi
