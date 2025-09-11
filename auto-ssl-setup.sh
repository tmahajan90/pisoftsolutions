#!/bin/bash

# Auto SSL Setup Script for PiSoftSolutions
# This script automatically sets up SSL if FORCE_SSL=true in .env

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔒 Auto SSL Setup for PiSoftSolutions${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found. Please create a .env file with your environment variables.${NC}"
    exit 1
fi

# Load environment variables from .env file
export $(cat .env | grep -v '^#' | xargs)

# Check if FORCE_SSL is enabled
if [ "$FORCE_SSL" = "true" ] || [ "$FORCE_SSL" = "1" ]; then
    echo -e "${GREEN}🔒 FORCE_SSL is enabled - SSL setup required${NC}"
    echo ""
    
    # Check if required SSL variables are set
    if [ -z "$DOMAIN" ] || [ -z "$SUPPORT_EMAIL" ]; then
        echo -e "${RED}❌ Error: DOMAIN and SUPPORT_EMAIL must be set in .env for SSL${NC}"
        echo ""
        echo "Required variables:"
        echo "  DOMAIN=pisoftsolutions.in"
        echo "  SUPPORT_EMAIL=support@pisoftsolutions.in"
        echo "  FORCE_SSL=true"
        exit 1
    fi
    
    echo -e "${YELLOW}📋 SSL Configuration:${NC}"
    echo "  Domain: $DOMAIN"
    echo "  Email: $SUPPORT_EMAIL"
    echo "  Force SSL: $FORCE_SSL"
    echo ""
    
    # Check if SSL certificates already exist
    if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
        echo -e "${GREEN}✅ SSL certificates already exist for $DOMAIN${NC}"
        echo -e "${YELLOW}🔄 Renewing certificates...${NC}"
        ./renew-ssl.sh
    else
        echo -e "${YELLOW}🔧 SSL certificates not found - generating new ones...${NC}"
        ./setup-ssl.sh
    fi
    
    echo ""
    echo -e "${GREEN}🎉 SSL setup completed!${NC}"
    echo -e "${BLUE}🌐 Your secure website is available at:${NC}"
    echo "  - https://$DOMAIN"
    echo "  - https://www.$DOMAIN"
    
else
    echo -e "${YELLOW}ℹ️  FORCE_SSL is disabled - SSL setup skipped${NC}"
    echo ""
    echo "To enable SSL, set in your .env file:"
    echo "  FORCE_SSL=true"
    echo "  DOMAIN=pisoftsolutions.in"
    echo "  SUPPORT_EMAIL=support@pisoftsolutions.in"
    echo ""
    echo "Then run: ./auto-ssl-setup.sh"
fi
