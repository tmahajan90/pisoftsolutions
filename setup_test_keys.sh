#!/bin/bash

echo "🔧 Setting up Test Razorpay Keys for Development"
echo "================================================"

# Create backup of current .env file
if [ -f ".env" ]; then
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup created: .env.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Update .env file with test keys
cat > .env << EOF
# Razorpay Configuration
# Test keys for development - Replace with your actual keys for production
# Get your keys from: https://dashboard.razorpay.com/settings/api-keys

RAZORPAY_KEY_ID=rzp_test_1234567890abcdef
RAZORPAY_KEY_SECRET=abcdef1234567890abcdef1234567890

# For production, use live keys:
# RAZORPAY_KEY_ID=rzp_live_YOUR_LIVE_KEY_ID
# RAZORPAY_KEY_SECRET=YOUR_LIVE_KEY_SECRET
EOF

echo "✅ .env file updated with test keys"
echo ""

echo "⚠️  IMPORTANT NOTES:"
echo "1. These are TEST keys for development only"
echo "2. They will NOT work for real payments"
echo "3. For production, you need real Razorpay API keys"
echo ""

echo "🧪 Testing the configuration..."
echo ""

# Test the configuration
if command -v ruby &> /dev/null; then
    ruby test_razorpay.rb
else
    echo "❌ Ruby not found. Please run: ruby test_razorpay.rb"
fi

echo ""
echo "🚀 Next steps:"
echo "1. Restart your Rails server: rails server"
echo "2. Test the payment flow in your browser"
echo "3. For real payments, get actual keys from Razorpay dashboard"
echo ""
echo "📋 Test payment details:"
echo "- Card: 4111 1111 1111 1111"
echo "- Expiry: Any future date"
echo "- CVV: Any 3 digits"
echo "- UPI: success@razorpay"
