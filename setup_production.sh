#!/bin/bash

# Quick Production Setup Script for Pisoft Solutions Rails App
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_info "Pisoft Solutions Production Setup"
print_info "This script will help you configure your production environment."

# Check if .env.production already exists
if [ -f ".env.production" ]; then
    print_warning ".env.production already exists. Do you want to overwrite it? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_info "Setup cancelled."
        exit 0
    fi
fi

# Get user input
print_info "Please provide the following information:"

# Domain
echo -n "Enter your domain (e.g., example.com): "
read -r domain

# Database password
echo -n "Enter database password: "
read -s db_password
echo

# Rails master key
echo -n "Enter Rails master key (or press Enter to generate): "
read -r rails_master_key

# Razorpay keys
echo -n "Enter Razorpay Key ID: "
read -r razorpay_key_id

echo -n "Enter Razorpay Key Secret: "
read -s razorpay_key_secret
echo

# SMTP settings
echo -n "Enter SMTP username (email): "
read -r smtp_username

echo -n "Enter SMTP password: "
read -s smtp_password
echo

# Generate Rails master key if not provided
if [ -z "$rails_master_key" ]; then
    print_info "Generating Rails master key..."
    rails_master_key=$(openssl rand -hex 32)
    print_success "Generated Rails master key: $rails_master_key"
fi

# Generate secret key base
secret_key_base=$(openssl rand -hex 64)

# Create .env.production
print_info "Creating .env.production file..."

cat > .env.production << EOF
# Production Environment Variables for Pisoft Solutions Rails App

# Rails Configuration
RAILS_ENV=production
RAILS_MASTER_KEY=$rails_master_key
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true

# Database Configuration
POSTGRES_DB=pisoftsolutions_production
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$db_password
POSTGRES_HOST=db
POSTGRES_PORT=5432
DATABASE_URL=postgresql://postgres:$db_password@db:5432/pisoftsolutions_production

# Redis Configuration
REDIS_URL=redis://redis:6379/0

# Razorpay Configuration
RAZORPAY_KEY_ID=$razorpay_key_id
RAZORPAY_KEY_SECRET=$razorpay_key_secret

# Domain Configuration
DOMAIN=$domain
CDN_HOST=https://$domain

# SMTP Configuration for Email
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=$smtp_username
SMTP_PASSWORD=$smtp_password

# Security
SECRET_KEY_BASE=$secret_key_base

# Application Settings
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=2

# Optional: External Services
# AWS_S3_BUCKET=your-s3-bucket-name
# AWS_ACCESS_KEY_ID=your-aws-access-key
# AWS_SECRET_ACCESS_KEY=your-aws-secret-key
# AWS_REGION=us-east-1
EOF

print_success ".env.production file created!"

# Create SSL directory
mkdir -p ssl

# Create self-signed certificate for testing
print_info "Creating self-signed SSL certificate for testing..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/key.pem \
    -out ssl/cert.pem \
    -subj "/C=US/ST=State/L=City/O=Pisoft Solutions/CN=$domain"

print_success "Self-signed SSL certificate created in ssl/ directory"

# Make deployment script executable
chmod +x deploy_production.sh

print_success "Production setup completed!"
print_info ""
print_info "Next steps:"
print_info "1. Review and edit .env.production if needed"
print_info "2. Replace self-signed SSL certificate with real one for production"
print_info "3. Run: ./deploy_production.sh --with-nginx"
print_info ""
print_warning "Important: Keep your .env.production file secure and never commit it to version control!"
