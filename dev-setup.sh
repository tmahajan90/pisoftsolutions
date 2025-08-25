#!/bin/bash

# Development Setup Script
# Usage: ./dev-setup.sh

set -e  # Exit on any error

echo "🛠️ Setting up development environment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Build and start services
echo "🐳 Starting Docker services..."
docker-compose up -d

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 10

# Run migrations
echo "🗄️ Running database migrations..."
docker-compose exec web rails db:migrate

# Seed database
echo "🌱 Seeding database..."
docker-compose exec web rails db:seed

# Check if everything is working
echo "🏥 Checking application health..."
sleep 5
curl -f http://localhost:3000/ || echo "⚠️ Application might still be starting..."

echo "✅ Development environment setup completed!"
echo "🌐 Application is available at: http://localhost:3000"
echo "🔧 Admin panel: http://localhost:3000/admin"
echo "📊 Check logs with: docker-compose logs -f web"
echo ""
echo "📝 Useful commands:"
echo "  - Stop services: docker-compose down"
echo "  - View logs: docker-compose logs -f web"
echo "  - Rails console: docker-compose exec web rails console"
echo "  - Run tests: docker-compose exec web rails test"
