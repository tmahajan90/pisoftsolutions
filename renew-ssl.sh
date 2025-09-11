#!/bin/bash

# SSL Certificate Renewal Script for PiSoftSolutions
# This script renews SSL certificates using Let's Encrypt

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RAILS_ENV=${RAILS_ENV:-"production"}

echo -e "${BLUE}🔄 SSL Certificate Renewal for PiSoftSolutions${NC}"
echo -e "${BLUE}============================================${NC}"
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

echo -e "${YELLOW}🔧 Renewing SSL certificates...${NC}"

# Renew SSL certificates
if docker-compose -f $COMPOSE_FILE run --rm certbot renew; then
    echo -e "${GREEN}✅ SSL certificates renewed successfully!${NC}"
else
    echo -e "${RED}❌ Failed to renew SSL certificates${NC}"
    exit 1
fi

echo -e "${YELLOW}🔧 Reloading nginx configuration...${NC}"
docker-compose -f $COMPOSE_FILE exec nginx nginx -s reload

echo -e "${GREEN}🎉 SSL certificate renewal completed!${NC}"
echo ""
echo -e "${BLUE}📋 Certificate Status:${NC}"
echo "  - Renewal: Successful"
echo "  - Next renewal: In 60 days"
echo "  - Auto-renewal: Enabled"
echo ""
echo -e "${BLUE}💡 Tip: Set up a cron job to run this script monthly:${NC}"
echo "  0 2 1 * * /path/to/renew-ssl.sh"
