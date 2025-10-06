#!/bin/bash

# Production Deployment Script with Database Crash Fixes
# This script deploys the application with all database stability improvements

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/Users/tarun/rails_apps/pisoftsolutions"
LOG_FILE="/var/log/deploy_$(date +%Y%m%d_%H%M%S).log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Error function
error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

# Warning function
warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Success function
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as root or with sudo
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        warning "Running as root. This is not recommended for production."
    fi
}

# Backup current deployment
backup_current() {
    log "Creating backup of current deployment..."
    
    if [ -d "$PROJECT_DIR" ]; then
        local backup_dir="/backup/pisoftsolutions_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"
        
        # Backup database
        if docker compose ps db | grep -q "Up"; then
            log "Backing up database..."
            docker compose exec -T db pg_dump -U postgres pisoftsolutions_production > "$backup_dir/database_backup.sql"
        fi
        
        # Backup application files
        cp -r "$PROJECT_DIR" "$backup_dir/application"
        
        log "Backup created at: $backup_dir"
    fi
}

# Stop current services
stop_services() {
    log "Stopping current services..."
    
    # Stop database monitor if running
    if systemctl is-active --quiet db-monitor; then
        systemctl stop db-monitor
    fi
    
    # Stop Docker containers
    cd "$PROJECT_DIR"
    docker compose down --remove-orphans
    
    # Clean up any orphaned containers
    docker container prune -f
    
    success "Services stopped"
}

# Update application code
update_code() {
    log "Updating application code..."
    
    cd "$PROJECT_DIR"
    
    # Pull latest changes (if using git)
    if [ -d ".git" ]; then
        git pull origin main
    fi
    
    # Update dependencies
    log "Updating dependencies..."
    docker compose run --rm web bundle install
    docker compose run --rm web yarn install
    
    success "Code updated"
}

# Apply database fixes
apply_db_fixes() {
    log "Applying database stability fixes..."
    
    cd "$PROJECT_DIR"
    
    # Start database first
    log "Starting database with optimized configuration..."
    docker compose up -d db
    
    # Wait for database to be ready
    log "Waiting for database to be ready..."
    local retries=0
    while [ $retries -lt 60 ]; do
        if docker compose exec db pg_isready -U postgres -d pisoftsolutions_production >/dev/null 2>&1; then
            break
        fi
        sleep 2
        retries=$((retries + 1))
    done
    
    if [ $retries -eq 60 ]; then
        error "Database failed to start after 2 minutes"
    fi
    
    # Run database migrations
    log "Running database migrations..."
    docker compose run --rm web rails db:migrate
    
    # Create database indexes for performance
    log "Creating performance indexes..."
    docker compose run --rm web rails runner "
        ActiveRecord::Base.connection.execute('CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users(email);')
        ActiveRecord::Base.connection.execute('CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_user_id ON orders(user_id);')
        ActiveRecord::Base.connection.execute('CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_created_at ON orders(created_at);')
        ActiveRecord::Base.connection.execute('CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);')
    "
    
    success "Database fixes applied"
}

# Start services with monitoring
start_services() {
    log "Starting services with monitoring..."
    
    cd "$PROJECT_DIR"
    
    # Start all services
    docker compose up -d
    
    # Wait for services to be ready
    log "Waiting for services to be ready..."
    sleep 30
    
    # Check service health
    if docker compose ps | grep -q "Up"; then
        success "Services started successfully"
    else
        error "Some services failed to start"
    fi
    
    # Install and start database monitor
    log "Installing database monitor service..."
    sudo cp scripts/db-monitor.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable db-monitor
    sudo systemctl start db-monitor
    
    success "Database monitor started"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    cd "$PROJECT_DIR"
    
    # Check container status
    log "Checking container status..."
    docker compose ps
    
    # Check database connectivity
    log "Checking database connectivity..."
    if docker compose exec db pg_isready -U postgres -d pisoftsolutions_production; then
        success "Database is accessible"
    else
        error "Database is not accessible"
    fi
    
    # Check web application
    log "Checking web application..."
    if curl -f http://localhost:3000/health >/dev/null 2>&1; then
        success "Web application is responding"
    else
        warning "Web application health check failed"
    fi
    
    # Check database monitor
    if systemctl is-active --quiet db-monitor; then
        success "Database monitor is running"
    else
        warning "Database monitor is not running"
    fi
    
    success "Deployment verification completed"
}

# Show monitoring commands
show_monitoring() {
    log "Monitoring commands:"
    echo ""
    echo "Check application status:"
    echo "  docker compose ps"
    echo ""
    echo "Check database health:"
    echo "  curl http://localhost:3000/health"
    echo ""
    echo "Check database monitor:"
    echo "  sudo systemctl status db-monitor"
    echo "  sudo journalctl -u db-monitor -f"
    echo ""
    echo "Manual database recovery:"
    echo "  $PROJECT_DIR/scripts/db_monitor.sh recover"
    echo ""
    echo "Check database status:"
    echo "  $PROJECT_DIR/scripts/db_monitor.sh status"
    echo ""
}

# Main deployment function
main() {
    log "Starting production deployment with database fixes..."
    
    check_permissions
    backup_current
    stop_services
    update_code
    apply_db_fixes
    start_services
    verify_deployment
    show_monitoring
    
    success "Production deployment completed successfully!"
    log "Deployment log saved to: $LOG_FILE"
}

# Run main function
main "$@"
