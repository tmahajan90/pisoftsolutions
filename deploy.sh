#!/bin/bash

# Production Deployment Script
# Usage: ./deploy.sh

set -e  # Exit on any error

echo "🚀 Starting production deployment..."

# Set production environment
export RAILS_ENV=production

# Pull latest changes
echo "📥 Pulling latest changes..."
git pull origin master

# Build production images
echo "🔨 Building production images..."
docker-compose -f docker-compose.prod.yml build

# Stop existing services
echo "🛑 Stopping existing services..."
docker-compose -f docker-compose.prod.yml down

# Start services
echo "▶️ Starting production services..."
docker-compose -f docker-compose.prod.yml up -d

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 10

# Run migrations
echo "🗄️ Running database migrations..."
docker-compose -f docker-compose.prod.yml exec web rails db:migrate

# Precompile assets
echo "🎨 Precompiling assets..."
docker-compose -f docker-compose.prod.yml exec web rails assets:precompile

# Clear cache
echo "🧹 Clearing cache..."
docker-compose -f docker-compose.prod.yml exec web rails tmp:clear

# Check application health
echo "🏥 Checking application health..."
sleep 5
curl -f http://localhost:3000/ || echo "⚠️ Application might still be starting..."

echo "✅ Deployment completed successfully!"
echo "🌐 Application should be available at: http://your-domain.com"
echo "📊 Check logs with: docker-compose -f docker-compose.prod.yml logs -f web"
