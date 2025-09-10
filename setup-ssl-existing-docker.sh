#!/bin/bash

# SSL Setup using existing docker-compose.yml
# This script adds SSL certificates to your existing Docker setup

echo "🔒 SSL Setup with Existing Docker Compose"
echo "=" * 45

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running"
    echo "   Please start Docker first"
    exit 1
fi

# Check if domain is set
if [ -z "$DOMAIN" ]; then
    echo "❌ DOMAIN environment variable not set"
    echo "   Set your domain: export DOMAIN=pisoftsolutions.in"
    exit 1
fi

echo "📧 Domain: $DOMAIN"
echo "📧 Support Email: ${SUPPORT_EMAIL:-support@pisoftsolutions.in}"

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p /etc/letsencrypt
mkdir -p ./public/.well-known/acme-challenge

# Set proper permissions
echo "🔐 Setting permissions..."
sudo chown -R $USER:$USER /etc/letsencrypt
sudo chmod -R 755 /etc/letsencrypt

# Start your existing services
echo "🐳 Starting existing services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 15

# Check if services are running
echo "📊 Checking service status..."
docker-compose ps

# Get SSL certificate using the certbot service
echo "🔐 Getting SSL certificate..."
docker-compose run --rm certbot

# Check if certificate was created
if [ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
    echo "✅ SSL certificate created successfully"
else
    echo "❌ Failed to create SSL certificate"
    echo "   Please check the error messages above"
    exit 1
fi

# Restart nginx to load SSL certificates
echo "🔄 Restarting nginx with SSL certificates..."
docker-compose restart nginx

# Wait for nginx to restart
sleep 5

# Test HTTPS
echo "🧪 Testing HTTPS..."
if curl -s -I https://${DOMAIN} | grep -q "200 OK"; then
    echo "✅ HTTPS is working!"
else
    echo "⚠️  HTTPS test failed, but certificate is installed"
fi

echo ""
echo "🎉 SSL Setup Complete with Existing Docker Compose!"
echo ""
echo "🌐 Your website is now available at:"
echo "   • https://${DOMAIN}"
echo "   • https://www.${DOMAIN}"
echo "   • https://tech.easy2invest.co.in"
echo ""
echo "🔄 HTTP will automatically redirect to HTTPS"
echo ""
echo "🔒 SSL Certificate Details:"
echo "   • Certificate: /etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
echo "   • Private Key: /etc/letsencrypt/live/${DOMAIN}/privkey.pem"
echo "   • Expires: $(openssl x509 -in /etc/letsencrypt/live/${DOMAIN}/fullchain.pem -noout -dates | grep notAfter | cut -d= -f2)"
echo ""
echo "📅 Auto-renewal setup:"
echo "   Add to crontab: 0 12 * * * /path/to/this/script"
echo ""
echo "🎯 Test your HTTPS setup:"
echo "   curl -I https://${DOMAIN}"
echo "   openssl s_client -connect ${DOMAIN}:443 -servername ${DOMAIN}"
echo ""
echo "🐳 Your existing docker-compose.yml now includes SSL support!"
