#!/usr/bin/env ruby

# Zoho Email Testing Script
# Run with: rails runner test_zoho_email.rb

puts "📧 Testing Zoho Email Configuration"
puts "=" * 40

# Check environment variables
puts "🔧 Environment Variables:"
puts "  SMTP_ADDRESS: #{ENV['SMTP_ADDRESS'] || 'NOT SET'}"
puts "  SMTP_PORT: #{ENV['SMTP_PORT'] || 'NOT SET'}"
puts "  SMTP_USERNAME: #{ENV['SMTP_USERNAME'] || 'NOT SET'}"
puts "  SMTP_PASSWORD: #{ENV['SMTP_PASSWORD'] ? '***SET***' : 'NOT SET'}"
puts "  DOMAIN: #{ENV['DOMAIN'] || 'NOT SET'}"

# Test with a real email address
test_email_address = ENV['TEST_EMAIL'] || 'your-email@example.com'
puts "\n📧 Test Email Address: #{test_email_address}"
puts "💡 Set TEST_EMAIL environment variable to test with your real email"

# Create a test email
puts "\n🚀 Sending Test Email..."

begin
  # Create a simple test email
  test_email = ActionMailer::Base.mail(
    from: ENV['SMTP_USERNAME'] || 'test@example.com',
    to: test_email_address,
    subject: "Zoho SMTP Test - #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}",
    body: <<~EMAIL
      Hello!
      
      This is a test email to verify your Zoho SMTP configuration.
      
      Sent at: #{Time.current}
      From: PiSoftSolutions Rails App
      
      If you receive this email, your Zoho SMTP configuration is working correctly!
      
      Best regards,
      PiSoftSolutions Team
    EMAIL
  )
  
  puts "  📧 Email Details:"
  puts "    From: #{test_email.from}"
  puts "    To: #{test_email.to}"
  puts "    Subject: #{test_email.subject}"
  
  # Send the email
  result = test_email.deliver_now
  
  puts "\n  ✅ Email sent successfully!"
  puts "  📧 Message ID: #{result.message_id}"
  puts "  📧 Delivered at: #{Time.current}"
  
  puts "\n🎉 SUCCESS! Your Zoho SMTP configuration is working!"
  puts "📬 Check your email inbox (and spam folder) for the test email."
  
rescue Net::SMTPAuthenticationError => e
  puts "\n  ❌ SMTP Authentication Failed: #{e.message}"
  puts "\n💡 Zoho Authentication Issues:"
  puts "  1. Make sure you're using an App Password, not your regular password"
  puts "  2. Enable Two-Factor Authentication in your Zoho account"
  puts "  3. Generate a new App Password from Zoho Security settings"
  puts "  4. Check your username format: email@domain.com"
  
rescue Net::SMTPFatalError => e
  puts "\n  ❌ SMTP Fatal Error: #{e.message}"
  puts "\n💡 Possible Issues:"
  puts "  1. Check your email address format"
  puts "  2. Verify your Zoho account is active"
  puts "  3. Check if SMTP access is enabled in Zoho"
  
rescue Net::SMTPServerBusy => e
  puts "\n  ❌ SMTP Server Busy: #{e.message}"
  puts "\n💡 Try again in a few minutes"
  
rescue => e
  puts "\n  ❌ Email sending failed: #{e.message}"
  puts "  💡 Error class: #{e.class}"
  
  if e.message.include?('connection')
    puts "\n💡 Connection Issues:"
    puts "  1. Check your internet connection"
    puts "  2. Verify SMTP server address: smtp.zoho.com"
    puts "  3. Check if port 587 is blocked by firewall"
    puts "  4. Try port 465 with SSL instead"
  end
end

puts "\n🔍 Current SMTP Settings:"
puts "  Address: #{ActionMailer::Base.smtp_settings[:address]}"
puts "  Port: #{ActionMailer::Base.smtp_settings[:port]}"
puts "  Domain: #{ActionMailer::Base.smtp_settings[:domain]}"
puts "  Authentication: #{ActionMailer::Base.smtp_settings[:authentication]}"
puts "  Username: #{ActionMailer::Base.smtp_settings[:user_name]}"

puts "\n📋 Zoho SMTP Configuration Checklist:"
puts "  ✅ SMTP Address: smtp.zoho.com"
puts "  ✅ Port: 587 (STARTTLS) or 465 (SSL)"
puts "  ✅ Authentication: plain"
puts "  ✅ Username: your-zoho-email@domain.com"
puts "  ✅ Password: App Password (not regular password)"
puts "  ✅ Enable STARTTLS: true (for port 587)"

puts "\n🎯 Next Steps:"
puts "  1. If email was sent successfully, check your inbox"
puts "  2. If failed, fix the configuration issues above"
puts "  3. Test with a real email address by setting TEST_EMAIL env var"
puts "  4. Check spam/junk folder if email was sent but not received"
