#!/usr/bin/env ruby

# Real Email Testing Script
# Run with: TEST_EMAIL=your-email@example.com rails runner test_real_email.rb

puts "📧 Real Email Delivery Test"
puts "=" * 30

# Check if TEST_EMAIL is set
test_email = ENV['TEST_EMAIL']
if test_email.nil? || test_email.empty?
  puts "❌ TEST_EMAIL environment variable not set!"
  puts ""
  puts "💡 Usage:"
  puts "  TEST_EMAIL=your-email@example.com rails runner test_real_email.rb"
  puts ""
  puts "Example:"
  puts "  TEST_EMAIL=test@gmail.com rails runner test_real_email.rb"
  exit 1
end

puts "📧 Testing with email: #{test_email}"

# Check current configuration
puts "\n🔧 Current SMTP Configuration:"
puts "  Address: #{ActionMailer::Base.smtp_settings[:address]}"
puts "  Port: #{ActionMailer::Base.smtp_settings[:port]}"
puts "  Domain: #{ActionMailer::Base.smtp_settings[:domain]}"
puts "  Username: #{ActionMailer::Base.smtp_settings[:user_name]}"
puts "  Authentication: #{ActionMailer::Base.smtp_settings[:authentication]}"

# Test email sending
puts "\n🚀 Sending test email..."

begin
  # Create a test email with payment success template
  order = Order.joins(:order_items).first
  
  if order.nil?
    puts "❌ No orders found. Creating a test order..."
    
    # Create a minimal test order
    user = User.first || User.create!(
      name: "Test User",
      email: test_email,
      password: "password123",
      password_confirmation: "password123"
    )
    
    product = Product.active.first
    if product.nil?
      puts "❌ No products found. Please create a product first."
      exit 1
    end
    
    order = Order.create!(
      user: user,
      user_email: test_email,
      total_amount: 1000,
      status: 'paid',
      payment_status: 'success',
      payment_gateway: 'test',
      payment_gateway_payment_id: 'test_payment_123',
      payment_gateway_order_id: 'test_order_123'
    )
    
    OrderItem.create!(
      order: order,
      product: product,
      quantity: 1,
      price: 1000
    )
    
    puts "✅ Test order created: ##{order.id}"
  end
  
  # Send payment success email
  puts "📧 Sending payment success email..."
  PaymentMailer.payment_success(order).deliver_now
  
  puts "\n✅ Email sent successfully!"
  puts "📬 Check your email inbox for the payment confirmation email"
  puts "📁 Also check your spam/junk folder"
  
  puts "\n🎉 SUCCESS! Your email configuration is working correctly!"
  puts "📧 The payment success email should arrive shortly."
  
rescue => e
  puts "\n❌ Email sending failed: #{e.message}"
  puts "💡 Error class: #{e.class}"
  
  case e
  when Net::SMTPAuthenticationError
    puts "\n🔐 Authentication Error:"
    puts "  - Check your email and password"
    puts "  - Make sure you're using an App Password (not regular password)"
    puts "  - Verify Two-Factor Authentication is enabled"
    
  when Net::SMTPFatalError
    puts "\n🚫 SMTP Fatal Error:"
    puts "  - Check your email address format"
    puts "  - Verify your account is active"
    puts "  - Check if SMTP access is enabled"
    
  when Net::SMTPServerBusy
    puts "\n⏳ Server Busy:"
    puts "  - Try again in a few minutes"
    puts "  - The email server might be temporarily unavailable"
    
  when Errno::ECONNREFUSED
    puts "\n🔌 Connection Refused:"
    puts "  - Check your internet connection"
    puts "  - Verify SMTP server address and port"
    puts "  - Check if firewall is blocking the connection"
    
  else
    puts "\n❓ Other Error:"
    puts "  - Check your SMTP configuration"
    puts "  - Verify all environment variables are set correctly"
    puts "  - Check Rails logs for more details"
  end
  
  puts "\n🔧 Troubleshooting Steps:"
  puts "1. Verify your .env file has correct SMTP settings"
  puts "2. Restart your Rails server after changing configuration"
  puts "3. Check your email provider's SMTP documentation"
  puts "4. Test with a different email address"
end

puts "\n📋 Configuration Summary:"
puts "  Environment: #{Rails.env}"
puts "  SMTP Server: #{ActionMailer::Base.smtp_settings[:address]}"
puts "  SMTP Port: #{ActionMailer::Base.smtp_settings[:port]}"
puts "  From Email: #{ActionMailer::Base.smtp_settings[:user_name]}"
puts "  Test Email: #{test_email}"
