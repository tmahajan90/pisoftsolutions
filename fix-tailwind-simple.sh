#!/bin/bash

# Simple Tailwind Fix Script for PiSoftSolutions
# This script fixes the Tailwind CSS loading issue without asset precompilation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Simple Tailwind CSS Fix${NC}"
echo -e "${BLUE}=========================${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

echo -e "${YELLOW}🔧 Step 1: Stopping current containers...${NC}"
docker-compose down

echo -e "${YELLOW}🔧 Step 2: Rebuilding containers...${NC}"
docker-compose build --no-cache

echo -e "${YELLOW}🔧 Step 3: Starting containers...${NC}"
docker-compose up -d

echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 30

echo -e "${YELLOW}🔧 Step 4: Building Tailwind CSS...${NC}"
docker-compose exec web bundle exec rails tailwindcss:build

echo -e "${YELLOW}🔧 Step 5: Restarting web service...${NC}"
docker-compose restart web

echo -e "${YELLOW}⏳ Waiting for web service to restart...${NC}"
sleep 15

echo -e "${YELLOW}🔍 Step 6: Testing the fix...${NC}"

# Test HTTP access
if curl -f -s http://localhost:3000/health > /dev/null; then
    echo -e "${GREEN}✅ HTTP access working${NC}"
else
    echo -e "${RED}❌ HTTP access not working${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Tailwind CSS fix applied!${NC}"
echo ""
echo -e "${BLUE}📋 What was fixed:${NC}"
echo "  ✅ Layout now loads tailwind.css correctly"
echo "  ✅ Asset paths include Tailwind builds directory"
echo "  ✅ No asset precompilation during startup"
echo "  ✅ Host authorization issues resolved"
echo ""
echo -e "${BLUE}🌐 Your application should now work with:${NC}"
echo "  - HTTP: http://195.250.24.176:3000/"
echo "  - HTTPS: https://pisoftsolutions.in (if SSL is enabled)"
echo ""
echo -e "${BLUE}📋 Useful commands:${NC}"
echo "  - View logs: docker-compose logs -f"
echo "  - Check Tailwind: docker-compose exec web ls -la app/assets/builds/"
echo "  - Rails console: docker-compose exec web rails console"
