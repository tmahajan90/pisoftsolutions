#!/bin/bash

# Production Deployment Script for Pisoft Solutions Rails App
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

print_info "Starting production deployment..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    print_error ".env.production file not found. Please create it first."
    print_info "You can copy from .env.production.example or run the setup script."
    exit 1
fi

# Check if required environment variables are set
print_info "Checking environment variables..."

# Source the environment file
set -a
source .env.production
set +a

# Check critical variables
if [ -z "$RAILS_MASTER_KEY" ] || [ "$RAILS_MASTER_KEY" = "your_rails_master_key_here" ]; then
    print_error "RAILS_MASTER_KEY is not set properly in .env.production"
    exit 1
fi

if [ -z "$POSTGRES_PASSWORD" ] || [ "$POSTGRES_PASSWORD" = "your_secure_database_password_here" ]; then
    print_error "POSTGRES_PASSWORD is not set properly in .env.production"
    exit 1
fi

if [ -z "$RAZORPAY_KEY_ID" ] || [ "$RAZORPAY_KEY_ID" = "your_razorpay_key_id_here" ]; then
    print_warning "RAZORPAY_KEY_ID is not set properly in .env.production"
fi

if [ -z "$RAZORPAY_KEY_SECRET" ] || [ "$RAZORPAY_KEY_SECRET" = "your_razorpay_key_secret_here" ]; then
    print_warning "RAZORPAY_KEY_SECRET is not set properly in .env.production"
fi

# Stop existing containers
print_info "Stopping existing containers..."
docker-compose -f docker-compose.prod.yml down --remove-orphans || true

# Build the production image
print_info "Building production Docker image..."
docker-compose -f docker-compose.prod.yml build --no-cache

# Start the database and wait for it to be ready
print_info "Starting database..."
docker-compose -f docker-compose.prod.yml up -d db redis

# Wait for database to be ready
print_info "Waiting for database to be ready..."
sleep 10

# Check database health
print_info "Checking database health..."
for i in {1..30}; do
    if docker-compose -f docker-compose.prod.yml exec -T db pg_isready -U postgres > /dev/null 2>&1; then
        print_success "Database is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        print_error "Database failed to start within 30 seconds"
        exit 1
    fi
    print_info "Waiting for database... ($i/30)"
    sleep 2
done

# Start the web application
print_info "Starting web application..."
docker-compose -f docker-compose.prod.yml up -d web

# Wait for web application to be ready
print_info "Waiting for web application to be ready..."
sleep 15

# Run database migrations
print_info "Running database migrations..."
docker-compose -f docker-compose.prod.yml exec -T web rails db:migrate

# Precompile assets
print_info "Precompiling assets..."
docker-compose -f docker-compose.prod.yml exec -T web rails assets:precompile

# Clear temporary files
print_info "Clearing temporary files..."
docker-compose -f docker-compose.prod.yml exec -T web rails tmp:clear

# Check if nginx should be started
if [ "$1" = "--with-nginx" ]; then
    print_info "Starting Nginx..."
    
    # Check if SSL certificates exist
    if [ ! -f "ssl/cert.pem" ] || [ ! -f "ssl/key.pem" ]; then
        print_warning "SSL certificates not found. Creating self-signed certificates for testing..."
        
        # Create self-signed certificate
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout ssl/key.pem \
            -out ssl/cert.pem \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
        
        print_warning "Self-signed certificates created. For production, replace with real certificates."
    fi
    
    # Start nginx
    docker-compose -f docker-compose.prod.yml --profile nginx up -d nginx
    print_success "Nginx started with SSL support"
else
    print_info "Nginx not started. Use --with-nginx flag to start with Nginx."
fi

# Check application health
print_info "Checking application health..."
sleep 5

if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    print_success "Application is healthy and running on http://localhost:3000"
else
    print_warning "Application health check failed. Checking logs..."
    docker-compose -f docker-compose.prod.yml logs web
fi

# Show running containers
print_info "Running containers:"
docker-compose -f docker-compose.prod.yml ps

print_success "Production deployment completed!"
print_info "Application URL: http://localhost:3000"
if [ "$1" = "--with-nginx" ]; then
    print_info "Nginx URL: https://localhost (with SSL)"
fi

print_warning "Remember to:"
print_warning "1. Update your domain in .env.production"
print_warning "2. Replace self-signed SSL certificates with real ones"
print_warning "3. Configure your firewall to allow ports 80, 443, and 3000"
print_warning "4. Set up proper monitoring and logging"
