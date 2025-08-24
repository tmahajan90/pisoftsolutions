#!/usr/bin/env ruby

# Simple Razorpay Integration Test
# Run this script to test if your Razorpay configuration is working

require 'razorpay'

puts "🔍 Testing Razorpay Integration..."
puts "=" * 50

# Check environment variables
key_id = ENV['RAZORPAY_KEY_ID']
key_secret = ENV['RAZORPAY_KEY_SECRET']

if key_id.nil? || key_secret.nil?
  puts "❌ ERROR: Razorpay environment variables not set!"
  puts "Please set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET"
  puts "See RAZORPAY_SETUP.md for instructions"
  exit 1
end

puts "✅ Environment variables found"
puts "Key ID: #{key_id[0..10]}..." if key_id
puts "Key Secret: #{key_secret[0..10]}..." if key_secret

# Test Razorpay connection
begin
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
  
  # Clean up test order
  puts "🧹 Cleaning up test order..."
  
rescue Razorpay::Error => e
  puts "❌ Razorpay Error: #{e.message}"
  puts "Please check your API keys and try again"
  exit 1
rescue => e
  puts "❌ Unexpected Error: #{e.message}"
  puts "Please check your configuration"
  exit 1
end

puts "=" * 50
puts "🎉 Razorpay integration test completed successfully!"
puts "Your setup is ready for payments!"
puts ""
puts "Next steps:"
puts "1. Start your Rails server: rails server"
puts "2. Add items to cart"
puts "3. Go to checkout"
puts "4. Click 'Complete Purchase'"
puts "5. Test payment with test card: 4111 1111 1111 1111"
