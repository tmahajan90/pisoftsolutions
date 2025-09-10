#!/bin/bash

# Multi-Domain Setup Script for PiSoftSolutions
# This script helps you configure multiple domains for your Rails application

echo "🌐 Multi-Domain Setup for PiSoftSolutions"
echo "=" * 50

# Function to add domain to .env file
add_domain_to_env() {
    local domain=$1
    local env_file=".env"
    
    # Check if domain already exists
    if grep -q "ADDITIONAL_DOMAINS" "$env_file"; then
        # Add to existing ADDITIONAL_DOMAINS
        sed -i '' "s/ADDITIONAL_DOMAINS=.*/&,$domain/" "$env_file"
    else
        # Add new ADDITIONAL_DOMAINS line
        echo "ADDITIONAL_DOMAINS=$domain" >> "$env_file"
    fi
    
    echo "✅ Added $domain to additional domains"
}

# Function to show current domains
show_current_domains() {
    echo "📋 Current Domain Configuration:"
    echo ""
    
    if [ -f ".env" ]; then
        echo "Primary Domain:"
        grep "DOMAIN=" .env | sed 's/DOMAIN=/  • /'
        
        echo ""
        echo "Additional Domains:"
        if grep -q "ADDITIONAL_DOMAINS" .env; then
            grep "ADDITIONAL_DOMAINS=" .env | sed 's/ADDITIONAL_DOMAINS=/  • /' | tr ',' '\n' | sed 's/^/    /'
        else
            echo "  • None configured"
        fi
    else
        echo "❌ .env file not found"
    fi
}

# Function to update nginx configuration
update_nginx_config() {
    echo ""
    echo "🔧 Updating nginx configuration..."
    
    # Get all domains
    local primary_domain=$(grep "DOMAIN=" .env | cut -d'=' -f2)
    local additional_domains=$(grep "ADDITIONAL_DOMAINS=" .env | cut -d'=' -f2)
    
    # Create server_name line
    local server_name_line="server_name $primary_domain www.$primary_domain"
    
    if [ -n "$additional_domains" ]; then
        # Add additional domains
        IFS=',' read -ra ADDR <<< "$additional_domains"
        for domain in "${ADDR[@]}"; do
            domain=$(echo $domain | xargs) # trim whitespace
            server_name_line="$server_name_line $domain"
            if [[ ! $domain == www.* ]]; then
                server_name_line="$server_name_line www.$domain"
            fi
        done
    fi
    
    echo "📝 Nginx server_name configuration:"
    echo "   $server_name_line"
    
    # Update nginx.conf
    if [ -f "nginx.conf" ]; then
        # Backup nginx.conf
        cp nginx.conf nginx.conf.backup.$(date +%Y%m%d_%H%M%S)
        
        # Update server_name in nginx.conf
        sed -i '' "s/server_name .*/server_name $server_name_line;/" nginx.conf
        
        echo "✅ Updated nginx.conf with new domains"
    else
        echo "⚠️  nginx.conf not found"
    fi
}

# Function to restart services
restart_services() {
    echo ""
    echo "🔄 Restarting services..."
    docker-compose restart web nginx
    echo "✅ Services restarted"
}

# Main menu
echo "What would you like to do?"
echo ""
echo "1. Show current domains"
echo "2. Add a new domain"
echo "3. Update nginx configuration"
echo "4. Restart services"
echo "5. Complete setup (add domain + update nginx + restart)"
echo "6. Exit"
echo ""

read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        show_current_domains
        ;;
    2)
        read -p "Enter the new domain (e.g., example.com): " new_domain
        if [ -n "$new_domain" ]; then
            add_domain_to_env "$new_domain"
            show_current_domains
        else
            echo "❌ No domain entered"
        fi
        ;;
    3)
        update_nginx_config
        ;;
    4)
        restart_services
        ;;
    5)
        read -p "Enter the new domain (e.g., example.com): " new_domain
        if [ -n "$new_domain" ]; then
            add_domain_to_env "$new_domain"
            update_nginx_config
            restart_services
            echo ""
            echo "🎉 Complete setup finished!"
            show_current_domains
        else
            echo "❌ No domain entered"
        fi
        ;;
    6)
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "📚 For DNS setup instructions, see: DNS_SETUP_GUIDE.md"
