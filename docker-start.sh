#!/bin/bash

echo "🐳 Pisoft Solutions Docker Setup"
echo "================================"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file from template..."
    if [ -f "env_example.txt" ]; then
        cp env_example.txt .env
        echo "✅ .env file created from template"
        echo "⚠️  Please edit .env file with your actual Razorpay API keys"
    else
        echo "❌ env_example.txt not found. Creating basic .env file..."
        cat > .env << EOF
# Razorpay Configuration
RAZORPAY_KEY_ID=rzp_test_1234567890abcdef
RAZORPAY_KEY_SECRET=abcdef1234567890abcdef1234567890

# Database Configuration
POSTGRES_DB=pisoftsolutions_development
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
EOF
        echo "✅ Basic .env file created"
    fi
else
    echo "✅ .env file already exists"
fi

echo ""
echo "🔧 Building and starting Docker containers..."
echo "This may take a few minutes on first run..."
echo ""

# Build and start containers
docker-compose up --build -d

echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo "✅ Services are running!"
    echo ""
    echo "🌐 Application URLs:"
    echo "- Rails App: http://localhost:3000"
    echo "- Database: localhost:5432"
    echo "- Redis: localhost:6379"
    echo ""
    echo "📋 Useful Commands:"
    echo "- View logs: docker-compose logs -f"
    echo "- Stop services: docker-compose down"
    echo "- Rails console: docker-compose exec web rails console"
    echo "- Database console: docker-compose exec web rails dbconsole"
    echo ""
    echo "🎉 Setup complete! Your application should be running at http://localhost:3000"
else
    echo "❌ Some services failed to start. Check logs with: docker-compose logs"
    exit 1
fi
