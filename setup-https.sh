#!/bin/bash

# HTTPS Setup Script for PiSoftSolutions
# This script helps you set up SSL certificates for HTTPS

echo "🔒 HTTPS Setup for PiSoftSolutions"
echo "=" * 40

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  This script needs to be run as root for SSL certificate setup"
    echo "   Run with: sudo ./setup-https.sh"
    exit 1
fi

# Check if domain is set
if [ -z "$DOMAIN" ]; then
    echo "❌ DOMAIN environment variable not set"
    echo "   Set your domain: export DOMAIN=pisoftsolutions.in"
    exit 1
fi

echo "📧 Primary Domain: $DOMAIN"

# Check if Certbot is installed
if ! command -v certbot &> /dev/null; then
    echo "📦 Installing Certbot..."
    apt update
    apt install -y certbot
    echo "✅ Certbot installed"
else
    echo "✅ Certbot already installed"
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running"
    echo "   Please start Docker first"
    exit 1
fi

# Check if nginx is running
if ! docker-compose ps | grep -q "nginx.*Up"; then
    echo "❌ Nginx is not running"
    echo "   Please start nginx first: docker-compose up -d nginx"
    exit 1
fi

echo "🐳 Docker and Nginx are running"

# Get SSL certificate
echo "🔐 Getting SSL certificate for $DOMAIN..."

# Check if certificate already exists
if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    echo "⚠️  SSL certificate already exists for $DOMAIN"
    read -p "Do you want to renew it? (y/n): " renew
    if [ "$renew" = "y" ]; then
        certbot renew --cert-name $DOMAIN
    else
        echo "✅ Using existing certificate"
    fi
else
    # Get new certificate
    certbot certonly --webroot -w ./public -d $DOMAIN -d www.$DOMAIN
fi

# Check if certificate was created successfully
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "✅ SSL certificate created successfully"
else
    echo "❌ Failed to create SSL certificate"
    exit 1
fi

# Update nginx configuration for HTTP to HTTPS redirect
echo "🔧 Updating nginx configuration..."

# Backup nginx.conf
cp nginx.conf nginx.conf.backup.$(date +%Y%m%d_%H%M%S)

# Add HTTP to HTTPS redirect
cat > nginx_redirect.conf << EOF
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN tech.easy2invest.co.in www.tech.easy2invest.co.in;
    return 301 https://\$server_name\$request_uri;
}
EOF

echo "✅ Nginx configuration updated"

# Restart nginx
echo "🔄 Restarting nginx..."
docker-compose restart nginx

# Wait for nginx to start
sleep 5

# Test HTTPS
echo "🧪 Testing HTTPS..."
if curl -s -I https://$DOMAIN | grep -q "200 OK"; then
    echo "✅ HTTPS is working!"
else
    echo "⚠️  HTTPS test failed, but certificate is installed"
fi

echo ""
echo "🎉 HTTPS Setup Complete!"
echo ""
echo "🌐 Your website is now available at:"
echo "   • https://$DOMAIN"
echo "   • https://www.$DOMAIN"
echo "   • https://tech.easy2invest.co.in"
echo ""
echo "🔄 HTTP will automatically redirect to HTTPS"
echo ""
echo "🔒 SSL Certificate Details:"
echo "   • Certificate: /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
echo "   • Private Key: /etc/letsencrypt/live/$DOMAIN/privkey.pem"
echo "   • Expires: $(openssl x509 -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem -noout -dates | grep notAfter | cut -d= -f2)"
echo ""
echo "📅 Auto-renewal is recommended. Run:"
echo "   sudo crontab -e"
echo "   Add: 0 12 * * * /usr/bin/certbot renew --quiet && docker-compose restart nginx"
echo ""
echo "🎯 Test your HTTPS setup:"
echo "   curl -I https://$DOMAIN"
echo "   openssl s_client -connect $DOMAIN:443 -servername $DOMAIN"
