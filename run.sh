#!/bin/bash

# Complete Project Setup and Run Script
# Usage: ./run.sh [dev|prod]
# Examples: ./run.sh dev    (for development)
#          ./run.sh prod   (for production)

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

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check if required files exist
check_files() {
    local missing_files=()
    
    if [[ ! -f "docker-compose.yml" ]]; then
        missing_files+=("docker-compose.yml")
    fi
    
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

# Function to setup development environment
setup_dev() {
    print_status "Setting up development environment..."
    
    # Stop any existing containers
    print_status "Stopping existing containers..."
    docker-compose down 2>/dev/null || true
    
    # Build and start services
    print_status "Building and starting Docker services..."
    docker-compose up -d --build
    
    # Wait for database to be ready
    print_status "Waiting for database to be ready..."
    sleep 15
    
    # Check if database is ready
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if docker-compose exec -T db pg_isready -U postgres > /dev/null 2>&1; then
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
    docker-compose exec web rails db:migrate
    
    # Seed database
    print_status "Seeding database..."
    docker-compose exec web rails db:seed
    
    # Precompile assets (for development)
    print_status "Precompiling assets..."
    docker-compose exec web rails assets:precompile
    
    # Clear cache
    print_status "Clearing cache..."
    docker-compose exec web rails tmp:clear
    
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
    echo -e "${GREEN}🎉 Your application is ready!${NC}"
    echo ""
    echo -e "${BLUE}📱 Access Points:${NC}"
    echo -e "  🌐 Main Application: ${GREEN}http://localhost:3000${NC}"
    echo -e "  🔧 Admin Panel: ${GREEN}http://localhost:3000/admin${NC}"
    echo -e "  📊 Database: ${GREEN}localhost:5432${NC}"
    echo -e "  🔴 Redis: ${GREEN}localhost:6379${NC}"
    echo ""
    echo -e "${BLUE}🔑 Default Credentials:${NC}"
    echo -e "  👤 Admin User: ${GREEN}admin@shopease.com${NC}"
    echo -e "  🔐 Demo User: ${GREEN}demo@example.com${NC} / ${GREEN}demo123${NC}"
    echo ""
    echo -e "${BLUE}📝 Useful Commands:${NC}"
    echo -e "  🛑 Stop: ${GREEN}docker-compose down${NC}"
    echo -e "  📊 Logs: ${GREEN}docker-compose logs -f web${NC}"
    echo -e "  🖥️ Console: ${GREEN}docker-compose exec web rails console${NC}"
    echo -e "  🧪 Tests: ${GREEN}docker-compose exec web rails test${NC}"
    echo -e "  🔄 Restart: ${GREEN}docker-compose restart web${NC}"
    echo ""
    echo -e "${YELLOW}💡 Tip: Run this script again to restart the application${NC}"
}

# Function to setup production environment
setup_prod() {
    print_status "Setting up production environment..."
    
    # Set production environment
    export RAILS_ENV=production
    
    # Stop any existing containers
    print_status "Stopping existing containers..."
    docker-compose -f docker-compose.prod.yml down 2>/dev/null || true
    
    # Build and start services
    print_status "Building and starting production services..."
    docker-compose -f docker-compose.prod.yml up -d --build
    
    # Wait for database to be ready
    print_status "Waiting for database to be ready..."
    sleep 20
    
    # Check if database is ready
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if docker-compose -f docker-compose.prod.yml exec -T db pg_isready -U postgres > /dev/null 2>&1; then
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
    docker-compose -f docker-compose.prod.yml exec web rails db:migrate
    
    # Seed database (if needed)
    print_status "Seeding database..."
    docker-compose -f docker-compose.prod.yml exec web rails db:seed
    
    # Precompile assets
    print_status "Precompiling assets..."
    docker-compose -f docker-compose.prod.yml exec web rails assets:precompile
    
    # Clear cache
    print_status "Clearing cache..."
    docker-compose -f docker-compose.prod.yml exec web rails tmp:clear
    
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
    echo -e "${GREEN}🎉 Your production application is ready!${NC}"
    echo ""
    echo -e "${BLUE}📱 Access Points:${NC}"
    echo -e "  🌐 Main Application: ${GREEN}http://localhost:3000${NC}"
    echo -e "  🔧 Admin Panel: ${GREEN}http://localhost:3000/admin${NC}"
    echo ""
    echo -e "${BLUE}📝 Useful Commands:${NC}"
    echo -e "  🛑 Stop: ${GREEN}docker-compose -f docker-compose.prod.yml down${NC}"
    echo -e "  📊 Logs: ${GREEN}docker-compose -f docker-compose.prod.yml logs -f web${NC}"
    echo -e "  🔄 Restart: ${GREEN}docker-compose -f docker-compose.prod.yml restart web${NC}"
    echo ""
    echo -e "${YELLOW}💡 Tip: Run this script again to restart the application${NC}"
}

# Function to show help
show_help() {
    echo -e "${BLUE}🚀 Pisoft Solutions - Complete Setup Script${NC}"
    echo ""
    echo -e "${GREEN}Usage:${NC}"
    echo -e "  ${YELLOW}./run.sh dev${NC}   - Setup and run development environment"
    echo -e "  ${YELLOW}./run.sh prod${NC}  - Setup and run production environment"
    echo -e "  ${YELLOW}./run.sh help${NC}  - Show this help message"
    echo ""
    echo -e "${GREEN}What this script does:${NC}"
    echo -e "  ✅ Checks Docker is running"
    echo -e "  ✅ Verifies required files exist"
    echo -e "  ✅ Builds and starts Docker containers"
    echo -e "  ✅ Waits for database to be ready"
    echo -e "  ✅ Runs database migrations"
    echo -e "  ✅ Seeds database with initial data"
    echo -e "  ✅ Precompiles assets"
    echo -e "  ✅ Clears cache"
    echo -e "  ✅ Verifies application is running"
    echo -e "  ✅ Shows access URLs and credentials"
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo -e "  ${YELLOW}./run.sh dev${NC}    # Start development environment"
    echo -e "  ${YELLOW}./run.sh prod${NC}   # Start production environment"
    echo ""
    echo -e "${YELLOW}💡 Make sure Docker is running before executing this script${NC}"
}

# Main script logic
main() {
    local environment=${1:-dev}
    
    echo -e "${BLUE}🚀 Pisoft Solutions - Complete Setup Script${NC}"
    echo ""
    
    # Check Docker
    check_docker
    
    # Check required files
    check_files
    
    # Setup based on environment
    case $environment in
        "dev"|"development")
            setup_dev
            ;;
        "prod"|"production")
            setup_prod
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Invalid environment. Use 'dev' or 'prod'"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
