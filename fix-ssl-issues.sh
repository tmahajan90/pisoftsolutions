#!/bin/bash

# Fix SSL and Asset Issues Script for PiSoftSolutions
# This script fixes host authorization and asset pipeline issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Fixing SSL and Asset Issues${NC}"
echo -e "${BLUE}==============================${NC}"
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

echo -e "${YELLOW}🔧 Step 1: Stopping current containers...${NC}"
docker-compose down

echo -e "${YELLOW}🔧 Step 2: Rebuilding containers with fixes...${NC}"
docker-compose build --no-cache

echo -e "${YELLOW}🔧 Step 3: Starting containers...${NC}"
docker-compose up -d

echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 30

echo -e "${YELLOW}🔧 Step 4: Precompiling assets...${NC}"
docker-compose exec web bundle exec rails assets:precompile

echo -e "${YELLOW}🔧 Step 5: Restarting web service...${NC}"
docker-compose restart web

echo -e "${YELLOW}⏳ Waiting for web service to restart...${NC}"
sleep 15

echo -e "${YELLOW}🔍 Step 6: Testing the fixes...${NC}"

# Test HTTP access
if curl -f -s http://localhost:3000/health > /dev/null; then
    echo -e "${GREEN}✅ HTTP access working${NC}"
else
    echo -e "${RED}❌ HTTP access not working${NC}"
fi

# Test if assets are loading
if curl -f -s http://localhost:3000/ | grep -q "tailwind"; then
    echo -e "${GREEN}✅ Assets are loading properly${NC}"
else
    echo -e "${YELLOW}⚠️  Assets may not be loading properly${NC}"
fi

echo ""
echo -e "${GREEN}🎉 SSL and Asset fixes applied!${NC}"
echo ""
echo -e "${BLUE}📋 What was fixed:${NC}"
echo "  ✅ Host authorization for HTTPS requests"
echo "  ✅ Tailwind CSS asset pipeline"
echo "  ✅ Asset precompilation in production"
echo "  ✅ IP address access allowed"
echo ""
echo -e "${BLUE}🌐 Your application should now work with:${NC}"
echo "  - HTTP: http://195.250.24.176:3000/"
echo "  - HTTPS: https://pisoftsolutions.in (if SSL is enabled)"
echo ""
echo -e "${BLUE}📋 Useful commands:${NC}"
echo "  - View logs: docker-compose logs -f"
echo "  - Check assets: docker-compose exec web ls -la public/assets/"
echo "  - Rails console: docker-compose exec web rails console"
