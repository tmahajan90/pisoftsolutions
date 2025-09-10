#!/bin/bash

# Nginx Setup Script for PiSoftSolutions
# This script helps you set up nginx with SSL certificates

echo "🌐 Nginx Setup for PiSoftSolutions"
echo "=" * 40

# Check if running as root (needed for Let's Encrypt)
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  This script needs to be run as root for SSL certificate setup"
    echo "   Run with: sudo ./nginx-setup.sh"
    exit 1
fi

# Check if domain is set
if [ -z "$DOMAIN" ]; then
    echo "❌ DOMAIN environment variable not set"
    echo "   Set your domain: export DOMAIN=yourdomain.com"
    exit 1
fi

echo "📧 Domain: $DOMAIN"

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p /etc/letsencrypt
mkdir -p ./scripts
mkdir -p ./nginx/ssl

# Check if nginx.Dockerfile exists
if [ ! -f "nginx.Dockerfile" ]; then
    echo "❌ nginx.Dockerfile not found"
    echo "   Please ensure nginx.Dockerfile exists in the project root"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running"
    echo "   Please start Docker first"
    exit 1
fi

echo "🐳 Building nginx container..."
docker-compose build nginx

echo "🚀 Starting services..."
docker-compose up -d

echo "⏳ Waiting for services to start..."
sleep 10

# Check service status
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "🌐 Application URLs:"
echo "  HTTP: http://$DOMAIN"
echo "  HTTPS: https://$DOMAIN (after SSL setup)"
echo "  Local: http://localhost:3000"

echo ""
echo "🔒 SSL Certificate Setup:"
echo "1. Ensure your domain points to this server"
echo "2. Run: sudo certbot certonly --webroot -w ./public -d $DOMAIN"
echo "3. Restart nginx: docker-compose restart nginx"

echo ""
echo "📋 Nginx Configuration:"
echo "  - HTTP: Port 80 (redirects to HTTPS)"
echo "  - HTTPS: Port 443 (with SSL)"
echo "  - Static files: Served by nginx"
echo "  - Rails app: Proxied to web:3000"

echo ""
echo "🎉 Nginx setup complete!"
echo "   Your application is now accessible via nginx reverse proxy"
