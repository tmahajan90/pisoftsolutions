#!/usr/bin/env ruby

# Quick Gmail SMTP Test
# Run with: rails runner test_gmail_smtp.rb

puts "📧 Testing Gmail SMTP (Quick Test)"
puts "=" * 35

# Temporarily use Gmail SMTP settings
ActionMailer::Base.smtp_settings = {
  address: 'smtp.gmail.com',
  port: 587,
  domain: 'gmail.com',
  user_name: 'your-gmail@gmail.com',  # Replace with your Gmail
  password: 'your-gmail-app-password', # Replace with Gmail App Password
  authentication: 'plain',
  enable_starttls_auto: true
}

puts "📧 Gmail SMTP Configuration:"
puts "  Address: #{ActionMailer::Base.smtp_settings[:address]}"
puts "  Port: #{ActionMailer::Base.smtp_settings[:port]}"
puts "  Username: #{ActionMailer::Base.smtp_settings[:user_name]}"

puts "\n💡 To test with Gmail:"
puts "1. Enable 2FA in your Google account"
puts "2. Generate an App Password"
puts "3. Update the username and password in this script"
puts "4. Run: rails runner test_gmail_smtp.rb"

puts "\n🔧 For Zoho (your current setup):"
puts "1. Go to Zoho Mail → Security → App Passwords"
puts "2. Generate a new App Password"
puts "3. Update SMTP_PASSWORD in your .env file"
puts "4. Run: rails runner test_email_fix.rb"
