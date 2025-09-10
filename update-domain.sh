#!/bin/bash

# Update domain configuration for pisoftsolutions.in
echo "🌐 Updating domain configuration..."

# Backup current .env file
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

# Update domain in .env file
sed -i '' 's/DOMAIN=easy2invest.co.in/DOMAIN=pisoftsolutions.in/g' .env
sed -i '' 's/SUPPORT_EMAIL=support@easy2invest.co.in/SUPPORT_EMAIL=support@pisoftsolutions.in/g' .env

echo "✅ Domain updated to pisoftsolutions.in"
echo "✅ Support email updated to support@pisoftsolutions.in"

# Show the updated configuration
echo ""
echo "📋 Updated configuration:"
grep -E "DOMAIN|SUPPORT_EMAIL" .env

echo ""
echo "🔄 Restarting Docker services to apply changes..."
docker-compose restart web

echo ""
echo "🎉 Domain configuration updated successfully!"
echo "   Your app will now accept requests from:"
echo "   • pisoftsolutions.in"
echo "   • www.pisoftsolutions.in"
