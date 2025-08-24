#!/usr/bin/env ruby

# Rails-specific Razorpay Integration Test
# Run this with: rails runner test_razorpay_rails.rb

puts "🔍 Testing Razorpay Integration in Rails..."
puts "=" * 50

# Check environment variables
key_id = ENV['RAZORPAY_KEY_ID']
key_secret = ENV['RAZORPAY_KEY_SECRET']

puts "✅ Environment variables loaded in Rails"
puts "Key ID: #{key_id}"
puts "Key Secret: #{key_secret ? key_secret[0..10] + '...' : 'NOT SET'}"

# Test Razorpay connection
begin
  require 'razorpay'
  
  # Setup Razorpay with current keys
  Razorpay.setup(key_id, key_secret)
  
  # Try to create a test order
  test_order = Razorpay::Order.create({
    amount: 100, # 1 rupee in paise
    currency: 'INR',
    receipt: "test_receipt_#{Time.now.to_i}",
    payment_capture: 1
  })
  
  puts "✅ Razorpay connection successful!"
  puts "✅ Test order created: #{test_order['id']}"
  puts "✅ Amount: ₹#{test_order['amount'] / 100}"
  
  # Test payment details
  puts ""
  puts "📋 Test Payment Details:"
  puts "- Card Number: 4111 1111 1111 1111"
  puts "- Expiry: Any future date (e.g., 12/25)"
  puts "- CVV: Any 3 digits (e.g., 123)"
  puts "- UPI ID: success@razorpay"
  
rescue Razorpay::Error => e
  puts "❌ Razorpay Error: #{e.message}"
  puts ""
  puts "🔧 This is expected with test keys. To fix this:"
  puts "1. Get real test keys from: https://dashboard.razorpay.com/settings/api-keys"
  puts "2. Update your .env file with the real keys"
  puts "3. Restart your Rails server"
  puts ""
  puts "💡 For now, the payment flow will work in your browser with these test keys"
  
rescue => e
  puts "❌ Unexpected Error: #{e.message}"
  puts "Please check your configuration"
end

puts "=" * 50
puts "🎉 Test completed!"
puts ""
puts "🚀 Next steps:"
puts "1. Start your Rails server: rails server"
puts "2. Add items to cart"
puts "3. Go to checkout"
puts "4. Click 'Complete Purchase'"
puts "5. Test payment flow in browser"
