#!/bin/bash

echo "🔑 Generating SECRET_KEY_BASE for production..."

# Check if .env.production exists
if [ ! -f .env.production ]; then
    echo "❌ .env.production file not found!"
    echo "📝 Creating .env.production from template..."
    cp env.production.example .env.production
fi

# Generate secret key base
echo "🔐 Generating secure random key..."
SECRET_KEY_BASE=$(docker run --rm ruby:3.2.3-alpine ruby -e "require 'securerandom'; puts SecureRandom.hex(64)")

# Update .env.production file
if grep -q "^SECRET_KEY_BASE=" .env.production; then
    # Update existing line
    sed -i.bak "s/^SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$SECRET_KEY_BASE/" .env.production
    echo "✅ Updated existing SECRET_KEY_BASE in .env.production"
else
    # Add new line
    echo "SECRET_KEY_BASE=$SECRET_KEY_BASE" >> .env.production
    echo "✅ Added SECRET_KEY_BASE to .env.production"
fi

echo ""
echo "🔑 Generated SECRET_KEY_BASE:"
echo "$SECRET_KEY_BASE"
echo ""
echo "📝 This key has been saved to .env.production"
echo "🚀 You can now run: docker-compose -f docker-compose.prod.yml up --build -d"
