#!/bin/bash

echo "🚀 Deploying Pisoft Solutions Rails App to Ubuntu VPS..."

# Check if running on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    echo "⚠️  This script is optimized for Ubuntu VPS deployment"
    echo "   It will still work on other systems, but some features may not apply"
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Installing Docker..."
    
    # Update package list
    sudo apt-get update
    
    # Install required packages
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    echo "✅ Docker installed. Please log out and log back in, then run this script again."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "📦 Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Check if .env.production exists
if [ ! -f .env.production ]; then
    echo "⚠️  .env.production file not found!"
    echo "📝 Creating .env.production from template..."
    cp env.production.example .env.production
    echo "🔧 Please edit .env.production with your VPS-specific values:"
    echo "   - POSTGRES_PASSWORD (use a strong password)"
    echo "   - HOST (your VPS domain or IP)"
    echo "   - RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET"
    echo ""
    echo "   After editing, run this script again."
    exit 1
fi

# Generate SECRET_KEY_BASE if missing
SECRET_KEY_BASE=4eb6bb9f669513d41747891e981a00ba83a32c6af011c4a871b5a6aa2085711b08e284eb931a0749104fa86d3476fad33d66276333d11b408ab81e497e8c2eb9
# SECRET_KEY_BASE_VALUE=$(grep "^SECRET_KEY_BASE=" .env.production | cut -d'=' -f2)
# if [ -z "$SECRET_KEY_BASE_VALUE" ] || [ "$SECRET_KEY_BASE_VALUE" = "your_secret_key_base_here" ]; then
#     echo "🔑 Generating SECRET_KEY_BASE..."
#     SECRET_KEY_BASE=$(docker run --rm ruby:3.2.3-alpine ruby -e "require 'securerandom'; puts SecureRandom.hex(64)")
#     sed -i.bak "s/^SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$SECRET_KEY_BASE/" .env.production
#     echo "✅ SECRET_KEY_BASE generated and configured"
# fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p log tmp ssl

# Set proper permissions
echo "🔐 Setting proper permissions..."
sudo chown -R $USER:$USER log tmp
chmod 755 log tmp

# Stop any existing containers
echo "🛑 Stopping any existing containers..."
docker-compose -f docker-compose.vps.yml down 2>/dev/null || true

# Build and start containers
echo "📦 Building and starting VPS containers..."
docker-compose -f docker-compose.vps.yml up --build -d

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 15

# Set up database
echo "🗄️  Setting up production database..."
docker-compose -f docker-compose.vps.yml exec web bundle exec rails db:create db:migrate db:seed

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    echo "🌐 Installing Nginx..."
    sudo apt-get update
    sudo apt-get install -y nginx
    
    # Create nginx configuration
    echo "📝 Creating Nginx configuration..."
    sudo tee /etc/nginx/sites-available/pisoftsolutions << EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /health {
        proxy_pass http://127.0.0.1:3000/health;
        proxy_set_header Host \$host;
    }
}
EOF
    
    # Enable the site
    sudo ln -sf /etc/nginx/sites-available/pisoftsolutions /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test and restart nginx
    sudo nginx -t && sudo systemctl restart nginx
    sudo systemctl enable nginx
fi

# Set up firewall (if ufw is available)
if command -v ufw &> /dev/null; then
    echo "🔥 Configuring firewall..."
    sudo ufw allow ssh
    sudo ufw allow 'Nginx Full'
    sudo ufw --force enable
fi

# Set up log rotation
echo "📋 Setting up log rotation..."
sudo tee /etc/logrotate.d/pisoftsolutions << EOF
/home/$USER/pisoftsolutions/log/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        docker-compose -f /home/$USER/pisoftsolutions/docker-compose.vps.yml restart web
    endscript
}
EOF

echo "✅ VPS deployment complete!"
echo ""
echo "🌐 Your application is now running at:"
echo "   - Internal: http://127.0.0.1:3000"
echo "   - External: http://$(curl -s ifconfig.me)"
echo "   - Health: http://$(curl -s ifconfig.me)/health"
echo ""
echo "📋 Useful VPS commands:"
echo "  - View logs: docker-compose -f docker-compose.vps.yml logs -f"
echo "  - Restart: docker-compose -f docker-compose.vps.yml restart"
echo "  - Update: git pull && docker-compose -f docker-compose.vps.yml up --build -d"
echo "  - Nginx logs: sudo tail -f /var/log/nginx/access.log"
echo "  - System logs: sudo journalctl -u docker"
echo ""
echo "🔒 Security notes:"
echo "  - Change default passwords in .env.production"
echo "  - Set up SSL certificates with Let's Encrypt"
echo "  - Configure regular backups"
echo "  - Monitor system resources"
