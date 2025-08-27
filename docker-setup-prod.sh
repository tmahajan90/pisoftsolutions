#!/bin/bash

echo "🚀 Setting up Production Docker environment for Pisoft Solutions Rails App..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if .env.production exists
if [ ! -f .env.production ]; then
    echo "⚠️  .env.production file not found!"
    echo "📝 Creating .env.production from template..."
    cp env.production.example .env.production
    echo "🔧 Please edit .env.production with your actual values before continuing."
    echo "   Required variables:"
    echo "   - POSTGRES_PASSWORD"
    echo "   - SECRET_KEY_BASE"
    echo "   - RAZORPAY_KEY_ID"
    echo "   - RAZORPAY_KEY_SECRET"
    echo ""
    echo "   After editing, run this script again."
    exit 1
fi

# Generate SSL certificates for local testing
echo "🔐 Setting up SSL certificates..."
mkdir -p ssl
if [ ! -f ssl/cert.pem ] || [ ! -f ssl/key.pem ]; then
    echo "📜 Generating self-signed SSL certificates..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/key.pem \
        -out ssl/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
    echo "✅ SSL certificates generated"
else
    echo "✅ SSL certificates already exist"
fi

# Generate secret key base if not set
if ! grep -q "your_secret_key_base_here" .env.production; then
    echo "🔑 Secret key base already configured"
else
    echo "🔑 Generating secret key base..."
    SECRET_KEY_BASE=$(docker run --rm ruby:3.2.3-alpine ruby -e "require 'securerandom'; puts SecureRandom.hex(64)")git 
    sed -i.bak "s/your_secret_key_base_here/$SECRET_KEY_BASE/" .env.production
    echo "✅ Secret key base generated and configured"
fi

# Build and start the containers
echo "📦 Building and starting production containers..."
docker-compose -f docker-compose.prod.yml up --build -d

# Wait for the database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 15

# Run database setup
echo "🗄️  Setting up production database..."
docker-compose -f docker-compose.prod.yml exec web bundle exec rails db:create db:migrate

# Check if database needs seeding
echo "🌱 Checking if database needs seeding..."
if docker-compose -f docker-compose.prod.yml exec web bundle exec rails runner "puts Product.count" | grep -q "0"; then
    echo "📊 Seeding production database..."
    docker-compose -f docker-compose.prod.yml exec web bundle exec rails db:seed
else
    echo "✅ Database already has data, skipping seeds"
fi

echo "✅ Production setup complete!"
echo ""
echo "🌐 Your production Rails application is now running at:"
echo "   - HTTP:  http://localhost (redirects to HTTPS)"
echo "   - HTTPS: https://localhost"
echo "   - Direct Rails: http://localhost:3000"
echo ""
echo "🗄️  Database is accessible at: localhost:5432"
echo ""
echo "📋 Useful production commands:"
echo "  - View logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "  - Stop containers: docker-compose -f docker-compose.prod.yml down"
echo "  - Restart: docker-compose -f docker-compose.prod.yml restart"
echo "  - Rails console: docker-compose -f docker-compose.prod.yml exec web rails console"
echo "  - Database console: docker-compose -f docker-compose.prod.yml exec web rails dbconsole"
echo ""
echo "🔒 Security notes:"
echo "  - Change default passwords in .env.production"
echo "  - Use proper SSL certificates for production deployment"
echo "  - Configure proper backup strategies"
echo "  - Monitor logs and performance"
