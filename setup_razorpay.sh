#!/bin/bash

echo "🔧 Setting up Razorpay Environment Variables"
echo "=============================================="

# Check if .env file exists
if [ -f ".env" ]; then
    echo "✅ .env file already exists"
else
    echo "📝 Creating .env file..."
    cat > .env << EOF
# Razorpay Configuration
# Replace these with your actual Razorpay API keys
# Get your keys from: https://dashboard.razorpay.com/settings/api-keys

RAZORPAY_KEY_ID=rzp_test_YOUR_TEST_KEY_ID
RAZORPAY_KEY_SECRET=YOUR_TEST_KEY_SECRET

# For production, use live keys:
# RAZORPAY_KEY_ID=rzp_live_YOUR_LIVE_KEY_ID
# RAZORPAY_KEY_SECRET=YOUR_LIVE_KEY_SECRET
EOF
    echo "✅ .env file created"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Get your Razorpay API keys from: https://dashboard.razorpay.com/settings/api-keys"
echo "2. Edit the .env file and replace the placeholder values with your actual keys"
echo "3. For testing, use the 'Test Mode' keys"
echo "4. For production, use the 'Live Mode' keys"
echo ""
echo "🔑 Example .env file content:"
echo "RAZORPAY_KEY_ID=rzp_test_1234567890abcdef"
echo "RAZORPAY_KEY_SECRET=abcdef1234567890abcdef1234567890"
echo ""
echo "🚀 After updating the .env file, restart your Rails server:"
echo "   rails server"
echo ""
echo "🧪 Test the integration:"
echo "   ruby test_razorpay.rb"
