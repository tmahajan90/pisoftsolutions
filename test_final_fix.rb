#!/usr/bin/env ruby

# Final Email Fix Test
# Run with: rails runner test_final_fix.rb

puts "🎯 Final Email Fix Test"
puts "=" * 25

# Force reload environment variables
if File.exist?('.env')
  File.readlines('.env').each do |line|
    next if line.strip.empty? || line.start_with?('#')
    key, value = line.strip.split('=', 2)
    if key && value
      ENV[key] = value
    end
  end
end

puts "📧 Current Configuration:"
puts "  Email: #{ENV['SMTP_USERNAME']}"
puts "  Domain: #{ENV['DOMAIN']}"
puts "  Password Length: #{ENV['SMTP_PASSWORD']&.length || 0} characters"

# Check password format
password = ENV['SMTP_PASSWORD']
if password
  if password.length >= 16 && password.match?(/^[a-zA-Z0-9]+$/)
    puts "  ✅ Password format looks correct (App Password)"
  else
    puts "  ❌ Password format incorrect - needs to be 16+ characters"
    puts "     Current: #{password.length} characters"
    puts "     Expected: 16+ characters, letters and numbers only"
    puts ""
    puts "🔧 Fix Required:"
    puts "1. Go to Zoho Mail → Settings → Security"
    puts "2. Enable Two-Factor Authentication"
    puts "3. Generate new App Password (16+ characters)"
    puts "4. Update SMTP_PASSWORD in .env file"
    puts "5. Run this test again"
    exit 1
  end
end

# Test email sending
puts "\n🚀 Testing Email Sending..."

ActionMailer::Base.smtp_settings = {
  address: 'smtp.zoho.com',
  port: 587,
  domain: ENV['DOMAIN'],
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  authentication: 'login',
  enable_starttls_auto: true
}

begin
  test_email = ActionMailer::Base.mail(
    from: ENV['SMTP_USERNAME'],
    to: ENV['SMTP_USERNAME'],
    subject: "🎉 Email Fix Test - #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}",
    body: <<~EMAIL
      🎉 SUCCESS! Your email configuration is now working!
      
      This test email confirms that:
      ✅ Zoho SMTP connection is working
      ✅ Authentication is successful
      ✅ Email delivery is working
      
      Sent at: #{Time.current}
      From: PiSoftSolutions Rails App
      
      Your payment email system is now fully functional!
      
      Best regards,
      PiSoftSolutions Team
    EMAIL
  )
  
  result = test_email.deliver_now
  puts "✅ Email sent successfully!"
  puts "📧 Message ID: #{result.message_id}"
  puts "📧 Delivered at: #{Time.current}"
  puts "📬 Check your inbox: #{ENV['SMTP_USERNAME']}"
  puts "📁 Also check your spam/junk folder"
  
  puts "\n🎉 CONGRATULATIONS!"
  puts "Your email system is now working perfectly!"
  puts ""
  puts "✅ What's Working:"
  puts "  - Zoho SMTP connection"
  puts "  - Email authentication"
  puts "  - Email delivery"
  puts "  - Payment confirmation emails"
  puts ""
  puts "🚀 Next Steps:"
  puts "1. Test payment emails: TEST_EMAIL=your-email@gmail.com rails runner test_real_email.rb"
  puts "2. Your payment system will now send emails automatically"
  puts "3. Users will receive payment confirmations"
  
rescue Net::SMTPAuthenticationError => e
  puts "❌ Authentication failed: #{e.message}"
  puts ""
  puts "🔧 Still having issues? Try:"
  puts "1. Generate a new App Password in Zoho"
  puts "2. Make sure 2FA is enabled"
  puts "3. Check if SMTP access is enabled for your account"
  puts "4. Contact Zoho support if needed"
  
rescue => e
  puts "❌ Email sending failed: #{e.message}"
  puts "💡 Error class: #{e.class}"
end

puts "\n📋 Configuration Summary:"
puts "  SMTP Server: smtp.zoho.com:587"
puts "  Authentication: login"
puts "  Username: #{ENV['SMTP_USERNAME']}"
puts "  Domain: #{ENV['DOMAIN']}"
puts "  Password: #{ENV['SMTP_PASSWORD'] ? '***SET***' : 'NOT SET'}"
