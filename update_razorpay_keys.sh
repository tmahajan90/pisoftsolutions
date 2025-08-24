#!/bin/bash

echo "🔑 Razorpay API Keys Setup"
echo "=========================="
echo ""

echo "Please enter your Razorpay API keys:"
echo ""

# Get Key ID
read -p "Enter your Razorpay Key ID (starts with rzp_test_): " key_id

# Validate Key ID format
if [[ ! $key_id =~ ^rzp_(test|live)_[a-zA-Z0-9]+$ ]]; then
    echo "❌ Invalid Key ID format. It should start with 'rzp_test_' or 'rzp_live_'"
    exit 1
fi

# Get Key Secret
read -s -p "Enter your Razorpay Key Secret: " key_secret
echo ""

# Validate Key Secret
if [[ ${#key_secret} -lt 20 ]]; then
    echo "❌ Key Secret seems too short. Please check your key."
    exit 1
fi

echo ""
echo "Updating .env file..."

# Create backup
cp .env .env.backup

# Update .env file
cat > .env << EOF
# Razorpay Configuration
# Replace these with your actual Razorpay API keys
# Get your keys from: https://dashboard.razorpay.com/settings/api-keys

RAZORPAY_KEY_ID=$key_id
RAZORPAY_KEY_SECRET=$key_secret

# For production, use live keys:
# RAZORPAY_KEY_ID=rzp_live_YOUR_LIVE_KEY_ID
# RAZORPAY_KEY_SECRET=YOUR_LIVE_KEY_SECRET
EOF

echo "✅ .env file updated successfully!"
echo ""

echo "🔧 Next steps:"
echo "1. Restart your Rails server:"
echo "   rails server"
echo ""
echo "2. Test the configuration:"
echo "   ruby test_razorpay.rb"
echo ""
echo "3. Test the payment flow in your browser"
echo ""

echo "📋 Your keys have been saved to .env file"
echo "🔒 Original .env file backed up as .env.backup"
