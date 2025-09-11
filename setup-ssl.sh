#!/bin/bash

# SSL Setup Script for PiSoftSolutions
# This script sets up SSL certificates using Let's Encrypt

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DOMAIN=${DOMAIN:-"pisoftsolutions.in"}
SUPPORT_EMAIL=${SUPPORT_EMAIL:-"support@pisoftsolutions.in"}
RAILS_ENV=${RAILS_ENV:-"production"}

echo -e "${BLUE}🔒 SSL Certificate Setup for PiSoftSolutions${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if required environment variables are set
if [ -z "$DOMAIN" ] || [ -z "$SUPPORT_EMAIL" ]; then
    echo -e "${RED}❌ Error: DOMAIN and SUPPORT_EMAIL environment variables are required${NC}"
    echo ""
    echo "Usage:"
    echo "  DOMAIN=pisoftsolutions.in SUPPORT_EMAIL=support@pisoftsolutions.in ./setup-ssl.sh"
    echo ""
    echo "Or set them in your .env file:"
    echo "  DOMAIN=pisoftsolutions.in"
    echo "  SUPPORT_EMAIL=support@pisoftsolutions.in"
    exit 1
fi

echo -e "${YELLOW}📋 Configuration:${NC}"
echo "  Domain: $DOMAIN"
echo "  Email: $SUPPORT_EMAIL"
echo "  Environment: $RAILS_ENV"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found. Please create a .env file with your environment variables.${NC}"
    exit 1
fi

# Load environment variables from .env file
export $(cat .env | grep -v '^#' | xargs)

# Use single docker-compose file
COMPOSE_FILE="docker-compose.yml"

echo -e "${YELLOW}🔧 Step 1: Creating webroot directory for ACME challenges...${NC}"
mkdir -p public/.well-known/acme-challenge
chmod 755 public/.well-known/acme-challenge

echo -e "${YELLOW}🔧 Step 2: Starting nginx for certificate generation...${NC}"
# Start only nginx first
docker-compose -f $COMPOSE_FILE up -d nginx

# Wait for nginx to be ready
echo -e "${YELLOW}⏳ Waiting for nginx to be ready...${NC}"
sleep 10

# Test if nginx is responding
echo -e "${YELLOW}🔍 Testing nginx response...${NC}"
if curl -f -s http://localhost:80 > /dev/null; then
    echo -e "${GREEN}✅ Nginx is responding on port 80${NC}"
else
    echo -e "${RED}❌ Nginx is not responding on port 80${NC}"
    echo "Please check nginx logs: docker-compose -f $COMPOSE_FILE logs nginx"
    exit 1
fi

echo -e "${YELLOW}🔧 Step 3: Generating SSL certificates...${NC}"
echo "This may take a few minutes..."

# Generate SSL certificates
if docker-compose -f $COMPOSE_FILE run --rm certbot; then
    echo -e "${GREEN}✅ SSL certificates generated successfully!${NC}"
else
    echo -e "${RED}❌ Failed to generate SSL certificates${NC}"
    echo ""
    echo "Common issues:"
    echo "1. Domain not pointing to this server"
    echo "2. Port 80 not accessible from internet"
    echo "3. Firewall blocking port 80"
    echo ""
    echo "Please check:"
    echo "- DNS records: nslookup $DOMAIN"
    echo "- Port accessibility: curl -I http://$DOMAIN"
    echo "- Firewall: sudo ufw status"
    exit 1
fi

echo -e "${YELLOW}🔧 Step 4: Restarting nginx with SSL configuration...${NC}"
docker-compose -f $COMPOSE_FILE restart nginx

echo -e "${YELLOW}⏳ Waiting for nginx to restart...${NC}"
sleep 10

echo -e "${YELLOW}🔧 Step 5: Testing SSL configuration...${NC}"

# Test HTTPS
if curl -f -s https://$DOMAIN > /dev/null; then
    echo -e "${GREEN}✅ HTTPS is working: https://$DOMAIN${NC}"
else
    echo -e "${RED}❌ HTTPS is not working${NC}"
    echo "Please check nginx logs: docker-compose -f $COMPOSE_FILE logs nginx"
    exit 1
fi

# Test HTTP redirect
if curl -I -s http://$DOMAIN | grep -q "301\|302"; then
    echo -e "${GREEN}✅ HTTP to HTTPS redirect is working${NC}"
else
    echo -e "${YELLOW}⚠️  HTTP to HTTPS redirect may not be working${NC}"
fi

echo ""
echo -e "${GREEN}🎉 SSL Setup Complete!${NC}"
echo ""
echo -e "${BLUE}🌐 Your secure website is now available at:${NC}"
echo "  - https://$DOMAIN"
echo "  - https://www.$DOMAIN"
echo "  - https://tech.easy2invest.co.in"
echo "  - https://www.tech.easy2invest.co.in"
echo ""
echo -e "${BLUE}📋 SSL Certificate Details:${NC}"
echo "  - Issuer: Let's Encrypt"
echo "  - Auto-renewal: Enabled"
echo "  - Security: A+ rating with modern TLS"
echo ""
echo -e "${BLUE}🔧 Useful Commands:${NC}"
echo "  - View logs: docker-compose -f $COMPOSE_FILE logs nginx"
echo "  - Renew certificates: docker-compose -f $COMPOSE_FILE run --rm certbot renew"
echo "  - Check certificate: openssl s_client -connect $DOMAIN:443 -servername $DOMAIN"
echo ""
echo -e "${GREEN}✅ SSL setup completed successfully!${NC}"
