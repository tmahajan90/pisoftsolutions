#!/bin/bash

# Docker SSL Setup Script for PiSoftSolutions
# This script sets up SSL certificates using Docker

echo "🔒 Docker SSL Setup for PiSoftSolutions"
echo "=" * 40

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

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p /etc/letsencrypt
mkdir -p ./public/.well-known/acme-challenge

# Set proper permissions
echo "🔐 Setting permissions..."
sudo chown -R $USER:$USER /etc/letsencrypt
sudo chmod -R 755 /etc/letsencrypt

# Start services without SSL first
echo "🐳 Starting services..."
docker-compose up -d db web nginx

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
echo "📊 Checking service status..."
docker-compose ps

# Get SSL certificate using Docker
echo "🔐 Getting SSL certificate..."
docker run --rm \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -v ./public:/var/www/certbot \
  certbot/certbot \
  certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email ${SUPPORT_EMAIL:-support@pisoftsolutions.in} \
  --agree-tos \
  --no-eff-email \
  -d ${DOMAIN} \
  -d www.${DOMAIN} \
  -d tech.easy2invest.co.in \
  -d www.tech.easy2invest.co.in

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
echo "🎉 Docker SSL Setup Complete!"
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
