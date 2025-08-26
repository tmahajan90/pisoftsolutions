#!/bin/bash

# Master Setup Script for Pisoft Solutions
# Usage: ./setup.sh [dev|prod|domain] [domain] [email]
# Examples: 
#   ./setup.sh dev                    # Local development
#   ./setup.sh prod                   # Production (localhost)
#   ./setup.sh domain pisoftsolutions.in admin@pisoftsolutions.in

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Function to show help
show_help() {
    echo -e "${CYAN}🚀 Pisoft Solutions - Master Setup Script${NC}"
    echo ""
    echo -e "${GREEN}Usage:${NC}"
    echo -e "  ${YELLOW}./setup.sh dev${NC}                                    # Local development setup"
    echo -e "  ${YELLOW}./setup.sh prod${NC}                                   # Production setup (localhost)"
    echo -e "  ${YELLOW}./setup.sh domain <domain> <email>${NC}               # Domain deployment with SSL"
    echo -e "  ${YELLOW}./setup.sh help${NC}                                   # Show this help message"
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo -e "  ${YELLOW}./setup.sh dev${NC}                                    # Start local development"
    echo -e "  ${YELLOW}./setup.sh prod${NC}                                   # Deploy to production"
    echo -e "  ${YELLOW}./setup.sh domain pisoftsolutions.in admin@pisoftsolutions.in${NC}"
    echo ""
    echo -e "${GREEN}What each mode does:${NC}"
    echo -e "  ${BLUE}dev${NC}     - Local development with hot reload, database seeding, asset compilation"
    echo -e "  ${BLUE}prod${NC}    - Production deployment with optimized settings, no domain"
    echo -e "  ${BLUE}domain${NC}  - Full domain deployment with SSL certificates, Nginx, security"
    echo ""
    echo -e "${YELLOW}💡 Make sure Docker is running before executing this script${NC}"
}

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
    
    if [[ ! -f "docker-compose.yml" ]]; then
        missing_files+=("docker-compose.yml")
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

# Setup development environment
setup_dev() {
    print_header "🔧 Setting up Development Environment"
    echo ""
    
    # Stop any existing containers
    print_status "Stopping existing containers..."
    docker compose down 2>/dev/null || true
    
    # Build and start services
    print_status "Building and starting Docker services..."
    docker compose --env-file .env.development up -d --build
    
    # Wait for database to be ready
    print_status "Waiting for database to be ready..."
    sleep 15
    
    # Check if database is ready
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if docker compose exec -T db pg_isready -U postgres > /dev/null 2>&1; then
            print_success "Database is ready"
            break
        fi
        
        print_status "Waiting for database... (attempt $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        print_error "Database failed to start within expected time"
        exit 1
    fi
    
    # Run migrations
    print_status "Running database migrations..."
    docker compose --env-file .env.development exec web rails db:migrate
    
    # Seed database
    print_status "Seeding database..."
    docker compose --env-file .env.development exec web rails db:seed
    
    # Precompile assets
    print_status "Precompiling assets..."
    docker compose --env-file .env.development exec web rails assets:precompile
    
    # Clear cache
    print_status "Clearing cache..."
    docker compose --env-file .env.development exec web rails tmp:clear
    
    # Wait for application to be ready
    print_status "Waiting for application to be ready..."
    sleep 10
    
    # Check application health
    local health_attempts=10
    local health_attempt=1
    
    while [[ $health_attempt -le $health_attempts ]]; do
        if curl -f http://localhost:3000/ > /dev/null 2>&1; then
            print_success "Application is running successfully!"
            break
        fi
        
        print_status "Waiting for application... (attempt $health_attempt/$health_attempts)"
        sleep 3
        ((health_attempt++))
    done
    
    if [[ $health_attempt -gt $health_attempts ]]; then
        print_warning "Application might still be starting. Please check manually."
    fi
    
    print_success "Development environment setup completed!"
    echo ""
    print_header "🎉 Your development environment is ready!"
    echo ""
    echo -e "${BLUE}📱 Access Points:${NC}"
    echo -e "  🌐 Main Application: ${GREEN}http://localhost:3000${NC}"
    echo -e "  🔧 Admin Panel: ${GREEN}http://localhost:3000/admin${NC}"
    echo -e "  📊 Database: ${GREEN}localhost:5432${NC}"
    echo -e "  🔴 Redis: ${GREEN}localhost:6379${NC}"
    echo ""
    echo -e "${BLUE}🔑 Default Credentials:${NC}"
    echo -e "  👤 Admin User: ${GREEN}tarun@pisoftsolutions.in${NC}"
    echo -e "  🔐 Admin Password: ${GREEN}ox4ymoro${NC}"
    echo -e "  👤 Demo User: ${GREEN}demo@pisoftsolutions.in${NC}"
    echo -e "  🔐 Demo Password: ${GREEN}demo123${NC}"
    echo ""
    echo -e "${BLUE}📝 Useful Commands:${NC}"
    echo -e "  🛑 Stop: ${GREEN}docker compose down${NC}"
    echo -e "  📊 Logs: ${GREEN}docker compose logs -f web${NC}"
    echo -e "  🖥️ Console: ${GREEN}docker compose exec web rails console${NC}"
    echo -e "  🧪 Tests: ${GREEN}docker compose exec web rails test${NC}"
    echo -e "  🔄 Restart: ${GREEN}docker compose restart web${NC}"
    echo ""
    echo -e "${YELLOW}💡 Tip: Run this script again to restart the application${NC}"
}

# Setup production environment
setup_prod() {
    print_header "🚀 Setting up Production Environment"
    echo ""
    
    # Set production environment
    export RAILS_ENV=production
    
    # Stop any existing containers
    print_status "Stopping existing containers..."
    docker compose -f docker-compose.prod.yml down 2>/dev/null || true
    
    # Build and start services
    print_status "Building and starting production services..."
    docker compose -f docker-compose.prod.yml up -d --build
    
    # Wait for database to be ready
    print_status "Waiting for database to be ready..."
    sleep 20
    
    # Check if database is ready
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if docker compose -f docker-compose.prod.yml exec -T db pg_isready -U postgres > /dev/null 2>&1; then
            print_success "Database is ready"
            break
        fi
        
        print_status "Waiting for database... (attempt $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        print_error "Database failed to start within expected time"
        exit 1
    fi
    
    # Run migrations
    print_status "Running database migrations..."
    docker compose -f docker-compose.prod.yml exec web bin/rails db:migrate
    
    # Seed database
    print_status "Seeding database..."
    docker compose -f docker-compose.prod.yml exec web bin/rails db:seed
    
    # Precompile assets
    print_status "Precompiling assets..."
    docker compose -f docker-compose.prod.yml exec web bin/rails assets:precompile
    
    # Clear cache
    print_status "Clearing cache..."
    docker compose -f docker-compose.prod.yml exec web bin/rails tmp:clear
    
    # Wait for application to be ready
    print_status "Waiting for application to be ready..."
    sleep 15
    
    # Check application health
    local health_attempts=15
    local health_attempt=1
    
    while [[ $health_attempt -le $health_attempts ]]; do
        if curl -f http://localhost:3000/ > /dev/null 2>&1; then
            print_success "Application is running successfully!"
            break
        fi
        
        print_status "Waiting for application... (attempt $health_attempt/$health_attempts)"
        sleep 3
        ((health_attempt++))
    done
    
    if [[ $health_attempt -gt $health_attempts ]]; then
        print_warning "Application might still be starting. Please check manually."
    fi
    
    print_success "Production environment setup completed!"
    echo ""
    print_header "🎉 Your production application is ready!"
    echo ""
    echo -e "${BLUE}📱 Access Points:${NC}"
    echo -e "  🌐 Main Application: ${GREEN}http://localhost:3000${NC}"
    echo -e "  🔧 Admin Panel: ${GREEN}http://localhost:3000/admin${NC}"
    echo ""
    echo -e "${BLUE}🔑 Default Credentials:${NC}"
    echo -e "  👤 Admin User: ${GREEN}tarun@pisoftsolutions.in${NC}"
    echo -e "  🔐 Admin Password: ${GREEN}ox4ymoro${NC}"
    echo ""
    echo -e "${BLUE}📝 Useful Commands:${NC}"
    echo -e "  🛑 Stop: ${GREEN}docker compose -f docker-compose.prod.yml down${NC}"
    echo -e "  📊 Logs: ${GREEN}docker compose -f docker-compose.prod.yml logs -f web${NC}"
    echo -e "  🔄 Restart: ${GREEN}docker compose -f docker-compose.prod.yml restart web${NC}"
    echo ""
    echo -e "${YELLOW}💡 Tip: Run this script again to restart the application${NC}"
}

# Setup domain environment
setup_domain() {
    local domain=$1
    local email=$2
    
    if [[ -z "$domain" || -z "$email" ]]; then
        print_error "Domain and email are required for domain setup"
        print_error "Usage: ./setup.sh domain <domain> <email>"
        print_error "Example: ./setup.sh domain pisoftsolutions.in admin@pisoftsolutions.in"
        exit 1
    fi
    
    print_header "🌐 Setting up Domain Deployment"
    echo ""
    print_status "Deploying to domain: ${GREEN}$domain${NC}"
    print_status "Contact email: ${GREEN}$email${NC}"
    echo ""
    
    # Create environment file for domain
    print_status "Creating environment configuration..."
    
    cat > .env.production << EOF
# Domain Configuration
DOMAIN=$domain
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

# Security
SECRET_KEY_BASE=$(openssl rand -base64 64)
EOF

    print_success "Environment file created: .env.production"
    print_warning "Please update SMTP settings in .env.production before continuing"
    
    # Create Nginx configuration
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
        server_name $domain www.$domain;
        
        # Redirect HTTP to HTTPS
        return 301 https://\$server_name\$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name $domain www.$domain;

        # SSL Configuration
        ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
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
    
    # Create production docker-compose with domain support
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
    command: certonly --webroot -w /var/www/certbot --force-renewal --email $email --agree-tos --no-eff-email -d $domain -d www.$domain
    networks:
      - pisoftsolutions-network

  web:
    build: .
    container_name: pisoftsolutions-web
    environment:
      - RAILS_ENV=production
      - DOMAIN=$domain
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
    
    # Setup SSL certificates
    print_status "Setting up SSL certificates..."
    
    # Create certbot directories
    mkdir -p certbot/conf certbot/www
    
    # Stop any existing containers
    docker compose -f docker-compose.domain.yml down 2>/dev/null || true
    
    # Start nginx for certificate generation
    print_status "Starting nginx for certificate generation..."
    docker compose -f docker-compose.domain.yml up -d nginx
    
    # Wait for nginx to be ready
    sleep 5
    
    # Generate SSL certificate
    print_status "Generating SSL certificate..."
    docker compose -f docker-compose.domain.yml run --rm certbot
    
    if [ $? -eq 0 ]; then
        print_success "SSL certificate generated successfully"
    else
        print_error "Failed to generate SSL certificate"
        print_warning "Please check your domain DNS settings and try again"
        exit 1
    fi
    
    # Deploy the application
    print_status "Deploying application..."
    
    # Build and start all services
    print_status "Building and starting services..."
    docker compose -f docker-compose.domain.yml up -d --build
    
    # Wait for database to be ready
    print_status "Waiting for database to be ready..."
    sleep 20
    
    # Run migrations
    print_status "Running database migrations..."
    docker compose -f docker-compose.domain.yml exec web bin/rails db:migrate
    
    # Seed database
    print_status "Seeding database..."
    docker compose -f docker-compose.domain.yml exec web bin/rails db:seed
    
    # Precompile assets
    print_status "Precompiling assets..."
    docker compose -f docker-compose.domain.yml exec web bin/rails assets:precompile
    
    # Clear cache
    print_status "Clearing cache..."
    docker compose -f docker-compose.domain.yml exec web bin/rails tmp:clear
    
    print_success "Application deployed successfully!"
    
    # Show results
    echo ""
    print_success "Domain deployment completed!"
    echo ""
    print_header "🎉 Your application is now live!"
    echo ""
    echo -e "${BLUE}🌐 Your application is now live at:${NC}"
    echo -e "  🌐 Main Site: ${GREEN}https://$domain${NC}"
    echo -e "  🔧 Admin Panel: ${GREEN}https://$domain/admin${NC}"
    echo ""
    echo -e "${BLUE}🔑 Admin Credentials:${NC}"
    echo -e "  👤 Email: ${GREEN}tarun@pisoftsolutions.in${NC}"
    echo -e "  🔐 Password: ${GREEN}ox4ymoro${NC}"
    echo ""
    echo -e "${BLUE}📝 Useful Commands:${NC}"
    echo -e "  🛑 Stop: ${GREEN}docker compose -f docker-compose.domain.yml down${NC}"
    echo -e "  📊 Logs: ${GREEN}docker compose -f docker-compose.domain.yml logs -f web${NC}"
    echo -e "  🔄 Restart: ${GREEN}docker compose -f docker-compose.domain.yml restart web${NC}"
    echo -e "  🔒 Renew SSL: ${GREEN}docker compose -f docker-compose.domain.yml run --rm certbot renew${NC}"
    echo ""
    print_warning "Don't forget to update SMTP settings in .env.production for email functionality"
}

# Main script logic
main() {
    local mode=${1:-dev}
    
    echo -e "${CYAN}🚀 Pisoft Solutions - Master Setup Script${NC}"
    echo ""
    
    # Check Docker
    check_docker
    
    # Check required files
    check_files
    
    case $mode in
        "dev")
            setup_dev
            ;;
        "prod")
            setup_prod
            ;;
        "domain")
            setup_domain "$2" "$3"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Invalid mode: $mode"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
