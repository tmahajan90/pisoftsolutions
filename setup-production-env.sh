#!/bin/bash

# Production Environment Setup Script
# This script helps you set up environment variables for your production server

echo "🚀 Setting up Production Environment Variables for Cashfree Integration"
echo "=================================================================="

# Check if .env file exists
if [ -f ".env" ]; then
    echo "⚠️  .env file already exists. Creating backup..."
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup created"
fi

# Create .env file
echo "📝 Creating .env file..."
cat > .env << 'EOF'
# Rails Environment
RAILS_ENV=production
SECRET_KEY_BASE=your_secret_key_base_here

# Database Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password_here
POSTGRES_DB=pisoftsolutions_production

# Payment Gateway Configuration
# Cashfree (Primary Gateway)
CASHFREE_APP_ID=your_cashfree_app_id_here
CASHFREE_SECRET_KEY=your_cashfree_secret_key_here
CASHFREE_ENVIRONMENT=production
CASHFREE_WEBHOOK_SECRET=your_cashfree_webhook_secret_here

# Razorpay (Secondary Gateway - Optional)
RAZORPAY_KEY_ID=your_razorpay_key_id_here
RAZORPAY_KEY_SECRET=your_razorpay_secret_key_here

# Default Payment Gateway
DEFAULT_PAYMENT_GATEWAY=cashfree

# SSL Configuration
FORCE_SSL=true

# Server Configuration
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=2

# Email Configuration
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password_here
DOMAIN=yourdomain.com
ADDITIONAL_DOMAINS=www.yourdomain.com
SUPPORT_EMAIL=support@yourdomain.com

# Base URL for callbacks
BASE_URL=https://yourdomain.com
HOST=yourdomain.com
EOF

echo "✅ .env file created successfully!"
echo ""
echo "🔧 Next Steps:"
echo "1. Edit the .env file with your actual values:"
echo "   nano .env"
echo ""
echo "2. Important variables to update:"
echo "   - SECRET_KEY_BASE: Generate with 'rails secret'"
echo "   - CASHFREE_APP_ID: Your Cashfree App ID"
echo "   - CASHFREE_SECRET_KEY: Your Cashfree Secret Key"
echo "   - CASHFREE_ENVIRONMENT: 'production' for live payments"
echo "   - DOMAIN: Your actual domain name"
echo "   - BASE_URL: Your full domain URL"
echo ""
echo "3. After updating .env, restart your containers:"
echo "   docker-compose down"
echo "   docker-compose up -d"
echo ""
echo "4. Check if Cashfree is working:"
echo "   docker-compose logs web | grep -i cashfree"
echo ""
echo "🎉 Setup complete! Remember to keep your .env file secure and never commit it to version control."
