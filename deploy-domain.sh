#!/bin/bash

# Domain Deployment Script for Pisoft Solutions
# Usage: ./deploy-domain.sh [domain] [email]
# Example: ./deploy-domain.sh pisoftsolutions.in admin@pisoftsolutions.in

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if domain and email are provided
if [ $# -lt 2 ]; then
    print_error "Usage: $0 <domain> <email>"
    print_error "Example: $0 pisoftsolutions.in admin@pisoftsolutions.in"
    exit 1
fi

DOMAIN=$1
EMAIL=$2

echo -e "${BLUE}🌐 Domain Deployment Script for Pisoft Solutions${NC}"
echo ""

print_status "Deploying to domain: ${GREEN}$DOMAIN${NC}"
print_status "Contact email: ${GREEN}$EMAIL${NC}"
echo ""

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    print_success "Docker is running"
}

# Check if required files exist
check_files() {
    local missing_files=()
    
    if [[ ! -f "docker-compose.prod.yml" ]]; then
        missing_files+=("docker-compose.prod.yml")
    fi
    
    if [[ ! -f "Dockerfile" ]]; then
        missing_files+=("Dockerfile")
    fi
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Missing required files: ${missing_files[*]}"
        exit 1
    fi
    
    print_success "All required files found"
}

# Create environment file for domain
create_env_file() {
    print_status "Creating environment configuration..."
    
    cat > .env.production << EOF
# Domain Configuration
DOMAIN=$DOMAIN
RAILS_ENV=production

# Database Configuration
POSTGRES_DB=pisoftsolutions_production
POSTGRES_USER=pisoftsolutions
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Redis Configuration
REDIS_URL=redis://redis:6379/0

# Rails Configuration
RAILS_MASTER_KEY=$(cat config/master.key)
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true

# Email Configuration (update these with your actual SMTP settings)
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Optional: CDN Configuration
# CDN_HOST=https://cdn.$DOMAIN

# Security
SECRET_KEY_BASE=$(openssl rand -base64 64)
EOF

    print_success "Environment file created: .env.production"
    print_warning "Please update SMTP settings in .env.production before continuing"
}

# Create Nginx configuration
create_nginx_config() {
    print_status "Creating Nginx configuration..."
    
    mkdir -p nginx
    
    cat > nginx/nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream rails_app {
        server web:3000;
    }

    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone \$binary_remote_addr zone=login:10m rate=5r/m;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:;" always;

    server {
        listen 80;
        server_name $DOMAIN www.$DOMAIN;
        
        # Redirect HTTP to HTTPS
        return 301 https://\$server_name\$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name $DOMAIN www.$DOMAIN;

        # SSL Configuration
        ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # Security
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # Rate limiting
        limit_req zone=api burst=20 nodelay;
        limit_req zone=login burst=5 nodelay;

        # Static files
        location /assets/ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            proxy_pass http://rails_app;
        }

        location /packs/ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            proxy_pass http://rails_app;
        }

        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # Main application
        location / {
            proxy_pass http://rails_app;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header X-Forwarded-Host \$host;
            proxy_set_header X-Forwarded-Port \$server_port;
            
            # WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
}
EOF

    print_success "Nginx configuration created: nginx/nginx.conf"
}

# Create production docker-compose with domain support
create_production_compose() {
    print_status "Creating production Docker Compose configuration..."
    
    cat > docker-compose.domain.yml << EOF
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    container_name: pisoftsolutions-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    depends_on:
      - web
    networks:
      - pisoftsolutions-network
    restart: unless-stopped

  certbot:
    image: certbot/certbot
    container_name: pisoftsolutions-certbot
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    command: certonly --webroot -w /var/www/certbot --force-renewal --email $EMAIL --agree-tos --no-eff-email -d $DOMAIN -d www.$DOMAIN
    networks:
      - pisoftsolutions-network

  web:
    build: .
    container_name: pisoftsolutions-web
    environment:
      - RAILS_ENV=production
      - DOMAIN=$DOMAIN
    env_file:
      - .env.production
    volumes:
      - ./storage:/app/storage
      - ./log:/app/log
    depends_on:
      - db
      - redis
    networks:
      - pisoftsolutions-network
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    container_name: pisoftsolutions-db
    environment:
      - POSTGRES_DB=pisoftsolutions_production
      - POSTGRES_USER=pisoftsolutions
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - pisoftsolutions-network
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: pisoftsolutions-redis
    volumes:
      - redis_data:/data
    networks:
      - pisoftsolutions-network
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:

networks:
  pisoftsolutions-network:
    driver: bridge
EOF

    print_success "Production Docker Compose created: docker-compose.domain.yml"
}

# Setup SSL certificates
setup_ssl() {
    print_status "Setting up SSL certificates..."
    
    # Create certbot directories
    mkdir -p certbot/conf certbot/www
    
    # Stop any existing containers
    docker-compose -f docker-compose.domain.yml down 2>/dev/null || true
    
    # Start nginx for certificate generation
    print_status "Starting nginx for certificate generation..."
    docker-compose -f docker-compose.domain.yml up -d nginx
    
    # Wait for nginx to be ready
    sleep 5
    
    # Generate SSL certificate
    print_status "Generating SSL certificate..."
    docker-compose -f docker-compose.domain.yml run --rm certbot
    
    if [ $? -eq 0 ]; then
        print_success "SSL certificate generated successfully"
    else
        print_error "Failed to generate SSL certificate"
        print_warning "Please check your domain DNS settings and try again"
        exit 1
    fi
}

# Deploy the application
deploy_application() {
    print_status "Deploying application..."
    
    # Build and start all services
    print_status "Building and starting services..."
    docker-compose -f docker-compose.domain.yml up -d --build
    
    # Wait for database to be ready
    print_status "Waiting for database to be ready..."
    sleep 20
    
    # Run migrations
    print_status "Running database migrations..."
    docker-compose -f docker-compose.domain.yml exec web rails db:migrate
    
    # Seed database
    print_status "Seeding database..."
    docker-compose -f docker-compose.domain.yml exec web rails db:seed
    
    # Precompile assets
    print_status "Precompiling assets..."
    docker-compose -f docker-compose.domain.yml exec web rails assets:precompile
    
    # Clear cache
    print_status "Clearing cache..."
    docker-compose -f docker-compose.domain.yml exec web rails tmp:clear
    
    print_success "Application deployed successfully!"
}

# Main deployment process
main() {
    echo -e "${BLUE}🚀 Starting domain deployment for $DOMAIN${NC}"
    echo ""
    
    # Check prerequisites
    check_docker
    check_files
    
    # Create configuration files
    create_env_file
    create_nginx_config
    create_production_compose
    
    # Setup SSL
    setup_ssl
    
    # Deploy application
    deploy_application
    
    # Show results
    echo ""
    print_success "Domain deployment completed!"
    echo ""
    echo -e "${BLUE}🌐 Your application is now live at:${NC}"
    echo -e "  🌐 Main Site: ${GREEN}https://$DOMAIN${NC}"
    echo -e "  🔧 Admin Panel: ${GREEN}https://$DOMAIN/admin${NC}"
    echo ""
    echo -e "${BLUE}🔑 Admin Credentials:${NC}"
    echo -e "  👤 Email: ${GREEN}tarun@pisoftsolutions.in${NC}"
    echo -e "  🔐 Password: ${GREEN}ox4ymoro${NC}"
    echo ""
    echo -e "${BLUE}📝 Useful Commands:${NC}"
    echo -e "  🛑 Stop: ${GREEN}docker-compose -f docker-compose.domain.yml down${NC}"
    echo -e "  📊 Logs: ${GREEN}docker-compose -f docker-compose.domain.yml logs -f web${NC}"
    echo -e "  🔄 Restart: ${GREEN}docker-compose -f docker-compose.domain.yml restart web${NC}"
    echo -e "  🔒 Renew SSL: ${GREEN}docker-compose -f docker-compose.domain.yml run --rm certbot renew${NC}"
    echo ""
    print_warning "Don't forget to update SMTP settings in .env.production for email functionality"
}

# Run main function
main "$@"
