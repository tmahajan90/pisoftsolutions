#!/bin/bash

# Setup External Database Script
# This script helps you set up a separate database outside of Docker containers

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
DB_PASSWORD="secure_password_$(date +%s)"
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
    
    sudo apt update
    sudo apt install -y postgresql postgresql-contrib
    
    # Start PostgreSQL service
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    
    success "PostgreSQL installed and started"
}

# Install PostgreSQL (CentOS/RHEL)
install_postgresql_centos() {
    log "Installing PostgreSQL on CentOS/RHEL..."
    
    sudo yum install -y postgresql-server postgresql-contrib
    sudo postgresql-setup initdb
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    
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
    
    # Configure PostgreSQL for external connections
    configure_postgresql
    
    success "Database and user created"
}

# Configure PostgreSQL for external connections
configure_postgresql() {
    log "Configuring PostgreSQL for external connections..."
    
    # Find PostgreSQL config directory
    PG_CONFIG_DIR=$(sudo -u postgres psql -t -c "SHOW data_directory;" | xargs)
    PG_CONFIG_DIR=$(dirname "$PG_CONFIG_DIR")
    
    # Backup original config
    sudo cp "$PG_CONFIG_DIR/postgresql.conf" "$PG_CONFIG_DIR/postgresql.conf.backup"
    sudo cp "$PG_CONFIG_DIR/pg_hba.conf" "$PG_CONFIG_DIR/pg_hba.conf.backup"
    
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

# Test database connection
test_connection() {
    log "Testing database connection..."
    
    if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
        success "Database connection successful"
        return 0
    else
        error "Database connection failed"
        return 1
    fi
}

# Create environment file
create_env_file() {
    log "Creating environment file for external database..."
    
    cat > .env.external_db << EOF
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

    success "Environment file created: .env.external_db"
}

# Show connection details
show_connection_details() {
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
    echo "Connection String:"
    echo "  postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME"
    echo ""
    echo "Next Steps:"
    echo "  1. Update your docker-compose.yml to use external database"
    echo "  2. Run: ./scripts/migrate_to_external_db.sh"
    echo "  3. Test your application"
    echo ""
}

# Main installation function
main() {
    log "Setting up external PostgreSQL database..."
    
    # Detect OS and install PostgreSQL
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! check_postgresql; then
            install_postgresql_macos
        fi
    elif [[ -f /etc/debian_version ]]; then
        if ! check_postgresql; then
            install_postgresql_ubuntu
        fi
    elif [[ -f /etc/redhat-release ]]; then
        if ! check_postgresql; then
            install_postgresql_centos
        fi
    else
        error "Unsupported operating system. Please install PostgreSQL manually."
    fi
    
    setup_database
    test_connection
    create_env_file
    show_connection_details
    
    success "External database setup completed!"
}

# Run main function
main "$@"
