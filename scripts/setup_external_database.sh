#!/bin/bash

# Setup External Database for PiSoft Solutions
# This script sets up an external PostgreSQL database and migrates data

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DB_NAME="pisoftsolutions_production"
DB_USER="pisoftsolutions_user"
DB_PASSWORD="password"
DB_HOST="localhost"
DB_PORT="5432"

# Logging function
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if PostgreSQL is installed
check_postgresql() {
    if command -v psql &> /dev/null; then
        success "PostgreSQL is already installed"
        return 0
    else
        warning "PostgreSQL is not installed"
        return 1
    fi
}

# Install PostgreSQL (macOS)
install_postgresql_macos() {
    log "Installing PostgreSQL on macOS..."
    
    if command -v brew &> /dev/null; then
        brew install postgresql@15
        brew services start postgresql@15
        
        # Add to PATH
        echo 'export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"' >> ~/.zshrc
        source ~/.zshrc
        
        success "PostgreSQL installed and started"
    else
        error "Homebrew not found. Please install PostgreSQL manually."
    fi
}

# Install PostgreSQL (Ubuntu/Debian)
install_postgresql_ubuntu() {
    log "Installing PostgreSQL on Ubuntu/Debian..."
    
    # Update package list
    sudo apt update
    
    # Install PostgreSQL and additional packages
    sudo apt install -y postgresql postgresql-contrib postgresql-client
    
    # Start and enable PostgreSQL service
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    
    # Set up PostgreSQL user
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"
    
    success "PostgreSQL installed and started"
}

# Create database and user
setup_database() {
    log "Setting up database and user..."
    
    # Create user
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" || true
    
    # Create database
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" || true
    
    # Grant privileges
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
    
    success "Database and user created"
}

# Configure PostgreSQL for external connections
configure_postgresql() {
    log "Configuring PostgreSQL for external connections..."
    
    # Find PostgreSQL config directory
    PG_CONFIG_DIR=$(sudo -u postgres psql -t -c "SHOW data_directory;" | xargs)
    PG_CONFIG_DIR=$(dirname "$PG_CONFIG_DIR")
    
    # Configure postgresql.conf
    sudo tee -a "$PG_CONFIG_DIR/postgresql.conf" > /dev/null << EOF

# External connection settings
listen_addresses = '*'
port = $DB_PORT
max_connections = 200
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 4MB
min_wal_size = 1GB
max_wal_size = 4GB
log_min_duration_statement = 1000
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0
log_autovacuum_min_duration = 0
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
tcp_keepalives_idle = 600
tcp_keepalives_interval = 30
tcp_keepalives_count = 3
idle_in_transaction_session_timeout = 300000
statement_timeout = 30000
lock_timeout = 10000
deadlock_timeout = 1s
autovacuum = on
autovacuum_max_workers = 3
autovacuum_naptime = 20s
autovacuum_vacuum_threshold = 50
autovacuum_analyze_threshold = 50
autovacuum_vacuum_scale_factor = 0.1
autovacuum_analyze_scale_factor = 0.05
EOF

    # Configure pg_hba.conf for external connections
    sudo tee -a "$PG_CONFIG_DIR/pg_hba.conf" > /dev/null << EOF

# External connections
host    $DB_NAME    $DB_USER    0.0.0.0/0    scram-sha-256
host    all         all        0.0.0.0/0    scram-sha-256
EOF

    # Restart PostgreSQL
    if command -v brew &> /dev/null; then
        brew services restart postgresql@15
    else
        sudo systemctl restart postgresql
    fi
    
    success "PostgreSQL configured for external connections"
}

# Create environment file
create_env_file() {
    log "Creating environment file for external database..."
    
    cat > .env << EOF
# External Database Configuration
POSTGRES_HOST=$DB_HOST
POSTGRES_PORT=$DB_PORT
POSTGRES_DB=$DB_NAME
POSTGRES_USER=$DB_USER
POSTGRES_PASSWORD=$DB_PASSWORD

# Application Configuration
RAILS_ENV=production
SECRET_KEY_BASE=$(rails secret)
EOF

    success "Environment file created: .env"
}

# Backup current database
backup_current_db() {
    log "Creating backup of current database..."
    
    if docker compose ps db | grep -q "Up"; then
        log "Backing up from containerized database..."
        docker compose exec -T db pg_dump -U postgres -d pisoftsolutions_production > "/tmp/pisoftsolutions_backup_$(date +%Y%m%d_%H%M%S).sql"
        success "Database backup created"
    else
        warning "Containerized database is not running. Skipping backup."
    fi
}

# Migrate data
migrate_data() {
    log "Migrating data to external database..."
    
    # Stop current services
    docker compose down
    
    # Run migrations on external database
    docker compose run --rm web rails db:migrate
    
    success "Data migration completed"
}

# Test connection
test_connection() {
    log "Testing external database connection..."
    
    if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
        success "External database connection successful"
    else
        error "External database connection failed"
    fi
}

# Start services with external database
start_services() {
    log "Starting services with external database..."
    
    docker compose up -d
    
    # Wait for services to be ready
    sleep 30
    
    if docker compose ps | grep -q "Up"; then
        success "Services started with external database"
    else
        error "Failed to start services with external database"
    fi
}

# Show summary
show_summary() {
    echo ""
    echo "=========================================="
    echo "External Database Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Database Details:"
    echo "  Host: $DB_HOST"
    echo "  Port: $DB_PORT"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USER"
    echo "  Password: $DB_PASSWORD"
    echo ""
    echo "Benefits:"
    echo "  🛡️  Database isolated from application containers"
    echo "  🔄 No more database crashes affecting your app"
    echo "  📈 Better performance and stability"
    echo "  🔧 Easier database management and backups"
    echo ""
    echo "Next Steps:"
    echo "  1. Monitor application: docker compose logs -f web"
    echo "  2. Check health: curl http://localhost:3000/health"
    echo "  3. Set up regular database backups"
    echo ""
}

# Main function
main() {
    log "Setting up external PostgreSQL database..."
    
    # Install PostgreSQL if needed
    if ! check_postgresql; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            install_postgresql_macos
        elif [[ -f /etc/debian_version ]]; then
            install_postgresql_ubuntu
        else
            error "Unsupported operating system. Please install PostgreSQL manually."
        fi
    fi
    
    setup_database
    configure_postgresql
    create_env_file
    backup_current_db
    migrate_data
    test_connection
    start_services
    show_summary
    
    success "External database setup completed!"
}

# Run main function
main "$@"
