#!/bin/bash

# DNS Setup Verification Script for pisoftsolutions.in
# This script helps you verify that your DNS records are working correctly

echo "🌐 DNS Setup Verification for pisoftsolutions.in"
echo "=" * 50

DOMAIN="pisoftsolutions.in"
EXPECTED_IP="195.250.24.176"

echo "📋 Testing DNS Records..."
echo ""

# Test 1: Check A record for root domain
echo "1️⃣ Testing A record for $DOMAIN:"
ROOT_IP=$(nslookup $DOMAIN | grep -A 1 "Name:" | tail -1 | awk '{print $2}')
if [ "$ROOT_IP" = "$EXPECTED_IP" ]; then
    echo "   ✅ $DOMAIN → $ROOT_IP (CORRECT)"
else
    echo "   ❌ $DOMAIN → $ROOT_IP (Expected: $EXPECTED_IP)"
fi

# Test 2: Check A record for www subdomain
echo ""
echo "2️⃣ Testing A record for www.$DOMAIN:"
WWW_IP=$(nslookup www.$DOMAIN | grep -A 1 "Name:" | tail -1 | awk '{print $2}')
if [ "$WWW_IP" = "$EXPECTED_IP" ]; then
    echo "   ✅ www.$DOMAIN → $WWW_IP (CORRECT)"
else
    echo "   ❌ www.$DOMAIN → $WWW_IP (Expected: $EXPECTED_IP)"
fi

# Test 3: Test HTTP connectivity
echo ""
echo "3️⃣ Testing HTTP connectivity:"
echo "   Testing http://$DOMAIN..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 http://$DOMAIN)
if [ "$HTTP_STATUS" = "200" ]; then
    echo "   ✅ http://$DOMAIN is accessible (Status: $HTTP_STATUS)"
else
    echo "   ❌ http://$DOMAIN is not accessible (Status: $HTTP_STATUS)"
fi

echo "   Testing http://www.$DOMAIN..."
WWW_HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 http://www.$DOMAIN)
if [ "$WWW_HTTP_STATUS" = "200" ]; then
    echo "   ✅ http://www.$DOMAIN is accessible (Status: $WWW_HTTP_STATUS)"
else
    echo "   ❌ http://www.$DOMAIN is not accessible (Status: $WWW_HTTP_STATUS)"
fi

# Test 4: Check if server is running
echo ""
echo "4️⃣ Testing server status:"
SERVER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://$EXPECTED_IP:3000)
if [ "$SERVER_STATUS" = "200" ]; then
    echo "   ✅ Server at $EXPECTED_IP:3000 is running (Status: $SERVER_STATUS)"
else
    echo "   ❌ Server at $EXPECTED_IP:3000 is not accessible (Status: $SERVER_STATUS)"
fi

# Test 5: Check nginx status
echo ""
echo "5️⃣ Testing nginx status:"
NGINX_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://$EXPECTED_IP:80)
if [ "$NGINX_STATUS" = "200" ]; then
    echo "   ✅ Nginx at $EXPECTED_IP:80 is running (Status: $NGINX_STATUS)"
else
    echo "   ❌ Nginx at $EXPECTED_IP:80 is not accessible (Status: $NGINX_STATUS)"
fi

# Summary
echo ""
echo "📊 SUMMARY:"
echo "=" * 30

if [ "$ROOT_IP" = "$EXPECTED_IP" ] && [ "$WWW_IP" = "$EXPECTED_IP" ] && [ "$HTTP_STATUS" = "200" ]; then
    echo "🎉 SUCCESS! Your DNS setup is working correctly!"
    echo "   ✅ Domain: $DOMAIN"
    echo "   ✅ www subdomain: www.$DOMAIN"
    echo "   ✅ HTTP access: Working"
    echo ""
    echo "🌐 Your website is accessible at:"
    echo "   • http://$DOMAIN"
    echo "   • http://www.$DOMAIN"
    echo ""
    echo "🔒 Next step: Set up SSL certificate for HTTPS"
    echo "   Run: sudo certbot certonly --webroot -w ./public -d $DOMAIN -d www.$DOMAIN"
else
    echo "⚠️  DNS setup needs attention:"
    if [ "$ROOT_IP" != "$EXPECTED_IP" ]; then
        echo "   ❌ Root domain A record not pointing to correct IP"
    fi
    if [ "$WWW_IP" != "$EXPECTED_IP" ]; then
        echo "   ❌ www subdomain A record not pointing to correct IP"
    fi
    if [ "$HTTP_STATUS" != "200" ]; then
        echo "   ❌ HTTP access not working"
    fi
    echo ""
    echo "🔧 Troubleshooting steps:"
    echo "   1. Check your DNS records in your domain registrar"
    echo "   2. Wait 5-30 minutes for DNS propagation"
    echo "   3. Verify server is running: docker-compose ps"
    echo "   4. Check nginx logs: docker-compose logs nginx"
fi

echo ""
echo "📚 For detailed setup instructions, see: DNS_SETUP_GUIDE.md"
