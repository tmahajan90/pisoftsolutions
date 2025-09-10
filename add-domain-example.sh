#!/bin/bash

# Example: Add a domain manually
echo "🌐 Adding Domain Example"
echo "=" * 30

# Example domain to add
EXAMPLE_DOMAIN="example.com"

echo "📝 Example: Adding $EXAMPLE_DOMAIN"
echo ""

# Show current .env content
echo "Current .env configuration:"
grep -E "DOMAIN|ADDITIONAL_DOMAINS" .env
echo ""

# Add the domain to .env
echo "Adding $EXAMPLE_DOMAIN to .env..."
if grep -q "ADDITIONAL_DOMAINS" .env; then
    # Add to existing ADDITIONAL_DOMAINS
    sed -i '' "s/ADDITIONAL_DOMAINS=.*/&,$EXAMPLE_DOMAIN/" .env
else
    # Add new ADDITIONAL_DOMAINS line
    echo "ADDITIONAL_DOMAINS=$EXAMPLE_DOMAIN" >> .env
fi

echo "✅ Added $EXAMPLE_DOMAIN"
echo ""

# Show updated .env content
echo "Updated .env configuration:"
grep -E "DOMAIN|ADDITIONAL_DOMAINS" .env
echo ""

echo "🔄 To apply changes, run:"
echo "   docker-compose restart web"
echo ""
echo "📋 DNS Records needed for $EXAMPLE_DOMAIN:"
echo "   Type: A, Name: @, Value: 195.250.24.176"
echo "   Type: A, Name: www, Value: 195.250.24.176"
