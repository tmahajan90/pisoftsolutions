#!/bin/bash

# Production deployment script for PiSoft Solutions
# This script deploys the application with stable configuration

set -e

echo "🚀 Deploying PiSoft Solutions to Production"
echo "==========================================="

# Check if we're on the production server
if [ "$(hostname)" != "production-server" ] && [ ! -f "/root/pisoftsolutions/.production" ]; then
    echo "⚠️  This script is designed for production deployment"
    echo "Make sure you're running this on the production server"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Set production environment
export RAILS_ENV=production

echo "📦 Stopping existing services..."
docker-compose down || true

echo "🔧 Using production-optimized configuration..."
# Use the production-optimized docker-compose file
cp docker-compose.prod.yml docker-compose.yml

echo "🗄️  Ensuring database exists..."
# Start only the database first
docker-compose up -d db

echo "⏳ Waiting for database to be ready..."
sleep 30

# Check if database exists, create if not
if ! docker-compose exec -T db psql -U postgres -lqt | cut -d \| -f 1 | grep -qw pisoftsolutions_production; then
    echo "📊 Creating production database..."
    docker-compose exec -T db createdb -U postgres pisoftsolutions_production
fi

echo "🔄 Running database migrations..."
docker-compose exec -T web bundle exec rails db:migrate RAILS_ENV=production

echo "🌐 Starting web service..."
docker-compose up -d web

echo "⏳ Waiting for services to be ready..."
sleep 30

echo "🔍 Checking service health..."
docker-compose ps

echo "🧪 Testing connectivity..."
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo "✅ Web service is healthy"
else
    echo "❌ Web service health check failed"
    echo "📋 Web service logs:"
    docker-compose logs --tail=20 web
    exit 1
fi

if docker-compose exec -T db pg_isready -U postgres > /dev/null 2>&1; then
    echo "✅ Database is healthy"
else
    echo "❌ Database health check failed"
    echo "📋 Database logs:"
    docker-compose logs --tail=20 db
    exit 1
fi

echo "📊 Resource usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo ""
echo "🎉 Production deployment completed successfully!"
echo "🌐 Web service: http://$(curl -s ifconfig.me):3000"
echo "🗄️  Database: localhost:5432"
echo ""
echo "📋 Useful commands:"
echo "  Check status: docker-compose ps"
echo "  View logs: docker-compose logs -f"
echo "  Monitor: ./keep-alive.sh monitor"
echo "  Restart: docker-compose restart"
echo ""
echo "🔒 Services are now running with production-optimized settings"
