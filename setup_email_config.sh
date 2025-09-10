#!/bin/bash

# Email Configuration Setup Script
# This script helps you configure email settings for your Rails app

echo "📧 Email Configuration Setup"
echo "============================="

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Creating .env file..."
    touch .env
fi

echo ""
echo "🔧 Current Email Configuration:"
echo "  SMTP_ADDRESS: ${SMTP_ADDRESS:-'NOT SET'}"
echo "  SMTP_PORT: ${SMTP_PORT:-'NOT SET'}"
echo "  SMTP_USERNAME: ${SMTP_USERNAME:-'NOT SET'}"
echo "  SMTP_PASSWORD: ${SMTP_PASSWORD:+***SET***}"
echo "  DOMAIN: ${DOMAIN:-'NOT SET'}"

echo ""
echo "📋 Choose your email provider:"
echo "1. Zoho Mail"
echo "2. Gmail"
echo "3. Custom SMTP"
echo "4. Skip (use existing settings)"

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo "🔧 Zoho Mail Configuration"
        echo "========================="
        echo "Required settings:"
        echo "  SMTP_ADDRESS: smtp.zoho.com"
        echo "  SMTP_PORT: 587"
        echo "  Authentication: plain"
        echo "  Username: your-zoho-email@domain.com"
        echo "  Password: App Password (not regular password)"
        echo ""
        echo "⚠️  Important: You need to:"
        echo "  1. Enable Two-Factor Authentication in Zoho"
        echo "  2. Generate an App Password from Zoho Security settings"
        echo "  3. Use the App Password, not your regular password"
        echo ""
        
        read -p "Enter your Zoho email address: " email
        read -s -p "Enter your Zoho App Password: " password
        echo ""
        read -p "Enter your domain (e.g., yourdomain.com): " domain
        
        # Update .env file
        echo "SMTP_ADDRESS=smtp.zoho.com" >> .env
        echo "SMTP_PORT=587" >> .env
        echo "SMTP_USERNAME=$email" >> .env
        echo "SMTP_PASSWORD=$password" >> .env
        echo "DOMAIN=$domain" >> .env
        
        echo "✅ Zoho configuration added to .env file"
        ;;
        
    2)
        echo ""
        echo "🔧 Gmail Configuration"
        echo "====================="
        echo "Required settings:"
        echo "  SMTP_ADDRESS: smtp.gmail.com"
        echo "  SMTP_PORT: 587"
        echo "  Authentication: plain"
        echo "  Username: your-gmail@gmail.com"
        echo "  Password: App Password (not regular password)"
        echo ""
        echo "⚠️  Important: You need to:"
        echo "  1. Enable Two-Factor Authentication in Google"
        echo "  2. Generate an App Password from Google Account settings"
        echo "  3. Use the App Password, not your regular password"
        echo ""
        
        read -p "Enter your Gmail address: " email
        read -s -p "Enter your Gmail App Password: " password
        echo ""
        read -p "Enter your domain (e.g., yourdomain.com): " domain
        
        # Update .env file
        echo "SMTP_ADDRESS=smtp.gmail.com" >> .env
        echo "SMTP_PORT=587" >> .env
        echo "SMTP_USERNAME=$email" >> .env
        echo "SMTP_PASSWORD=$password" >> .env
        echo "DOMAIN=$domain" >> .env
        
        echo "✅ Gmail configuration added to .env file"
        ;;
        
    3)
        echo ""
        echo "🔧 Custom SMTP Configuration"
        echo "============================"
        
        read -p "Enter SMTP server address: " smtp_address
        read -p "Enter SMTP port (usually 587 or 465): " smtp_port
        read -p "Enter your email address: " email
        read -s -p "Enter your email password: " password
        echo ""
        read -p "Enter your domain: " domain
        
        # Update .env file
        echo "SMTP_ADDRESS=$smtp_address" >> .env
        echo "SMTP_PORT=$smtp_port" >> .env
        echo "SMTP_USERNAME=$email" >> .env
        echo "SMTP_PASSWORD=$password" >> .env
        echo "DOMAIN=$domain" >> .env
        
        echo "✅ Custom SMTP configuration added to .env file"
        ;;
        
    4)
        echo "Skipping configuration setup"
        ;;
        
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "🔧 Loading environment variables..."

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo ""
echo "📧 Updated Configuration:"
echo "  SMTP_ADDRESS: ${SMTP_ADDRESS:-'NOT SET'}"
echo "  SMTP_PORT: ${SMTP_PORT:-'NOT SET'}"
echo "  SMTP_USERNAME: ${SMTP_USERNAME:-'NOT SET'}"
echo "  SMTP_PASSWORD: ${SMTP_PASSWORD:+***SET***}"
echo "  DOMAIN: ${DOMAIN:-'NOT SET'}"

echo ""
echo "🚀 Next Steps:"
echo "1. Restart your Rails server to load new configuration"
echo "2. Run: rails runner test_zoho_email.rb"
echo "3. Set TEST_EMAIL environment variable to test with real email"
echo ""
echo "Example:"
echo "  export TEST_EMAIL=your-email@example.com"
echo "  rails runner test_zoho_email.rb"
