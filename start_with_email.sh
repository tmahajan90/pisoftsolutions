#!/bin/bash

# Start Rails App with Email Configuration
# This script ensures your email settings are properly loaded

echo "🚀 Starting PiSoftSolutions Rails App with Email Configuration"
echo "=" * 60

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "Please create a .env file with your email configuration"
    exit 1
fi

# Load environment variables
echo "📧 Loading email configuration from .env file..."
export $(cat .env | grep -v '^#' | xargs)

# Check email configuration
echo "📧 Email Configuration:"
echo "  SMTP Address: ${SMTP_ADDRESS:-'NOT SET'}"
echo "  SMTP Port: ${SMTP_PORT:-'NOT SET'}"
echo "  SMTP Username: ${SMTP_USERNAME:-'NOT SET'}"
echo "  SMTP Password: ${SMTP_PASSWORD:+***SET***}"
echo "  Domain: ${DOMAIN:-'NOT SET'}"

# Check if email is configured
if [ -z "$SMTP_USERNAME" ] || [ -z "$SMTP_PASSWORD" ]; then
    echo ""
    echo "⚠️  Email configuration incomplete!"
    echo "Please ensure your .env file contains:"
    echo "  SMTP_USERNAME=your-email@domain.com"
    echo "  SMTP_PASSWORD=your-app-password"
    echo ""
    echo "For Zoho: Generate an App Password (16+ characters)"
    echo "For Gmail: Generate an App Password"
    echo ""
    read -p "Continue without email? (y/N): " continue_without_email
    if [[ ! $continue_without_email =~ ^[Yy]$ ]]; then
        echo "Exiting. Please configure email settings first."
        exit 1
    fi
fi

echo ""
echo "🐳 Starting Docker containers..."

# Start Docker containers
docker-compose up -d

echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Check container status
echo "📊 Container Status:"
docker-compose ps

echo ""
echo "🌐 Application URLs:"
echo "  Local: http://localhost:3000"
echo "  Health Check: http://localhost:3000/health"

echo ""
echo "📧 To test email functionality:"
echo "  rails runner test_final_fix.rb"

echo ""
echo "🎉 PiSoftSolutions is now running!"
echo "   - Rails app: http://localhost:3000"
echo "   - Database: PostgreSQL on port 5432"
echo "   - Email: Configured with your SMTP settings"
