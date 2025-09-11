#!/bin/bash

# Fix SSL Certificate Issues
# This script addresses the SSL certificate renewal problems

echo "🔧 Fixing SSL Certificate Issues"
echo "=" * 40

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  This script needs to be run as root for SSL certificate setup"
    echo "   Run with: sudo ./fix-ssl-issues.sh"
    exit 1
fi

echo "🔍 Diagnosing SSL Certificate Issues..."

# Check if services are running
echo "📊 Checking service status..."
docker-compose ps

# Check if nginx is accessible on port 80
echo "🌐 Testing HTTP access..."
curl -I http://localhost:80 || echo "❌ Port 80 not accessible"
curl -I http://195.250.24.176:80 || echo "❌ External port 80 not accessible"

# Check DNS records
echo "🔍 Checking DNS records..."
nslookup pisoftsolutions.in
nslookup www.pisoftsolutions.in
nslookup tech.easy2invest.co.in
nslookup www.tech.easy2invest.co.in

# Check webroot directory
echo "📁 Checking webroot directory..."
ls -la ./public/.well-known/acme-challenge/ 2>/dev/null || echo "❌ .well-known directory not found"

# Create webroot directory if it doesn't exist
echo "📁 Creating webroot directory..."
mkdir -p ./public/.well-known/acme-challenge
chmod 755 ./public/.well-known/acme-challenge

# Test webroot access
echo "🧪 Testing webroot access..."
echo "test" > ./public/.well-known/acme-challenge/test
curl -I http://localhost:80/.well-known/acme-challenge/test || echo "❌ Webroot not accessible"
rm ./public/.well-known/acme-challenge/test

# Check nginx configuration
echo "🔧 Checking nginx configuration..."
docker-compose exec nginx nginx -t

# Restart services
echo "🔄 Restarting services..."
docker-compose restart nginx

# Wait for services to start
sleep 5

# Test HTTP access again
echo "🧪 Testing HTTP access after restart..."
curl -I http://localhost:80 || echo "❌ Port 80 still not accessible"

echo ""
echo "📋 Issues Found and Fixes Applied:"
echo "1. ✅ Created .well-known directory"
echo "2. ✅ Set proper permissions"
echo "3. ✅ Restarted nginx"
echo "4. ✅ Tested webroot access"
echo ""
echo "🔧 Next Steps:"
echo "1. Fix DNS records for www.tech.easy2invest.co.in"
echo "2. Ensure port 80 is open on your server"
echo "3. Verify domain routing"
echo "4. Retry SSL certificate generation"
echo ""
echo "📚 For detailed fixes, see: SSL_ISSUES_FIX_GUIDE.md"
