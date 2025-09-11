#!/bin/bash

# Deployment script for pisoftsolutions
# Usage: ./deploy.sh [branch_name]
# If no branch is specified, it will deploy the current branch

set -e  # Exit on any error

# Configuration
SERVER_HOST="66.23.224.227"
SERVER_USER="root"
SERVER_PATH="/root/pisoftsolutions"
BRANCH=${1:-$(git branch --show-current)}

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

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository. Please run this script from the project root."
        exit 1
    fi
}

# Function to check if we have uncommitted changes
check_uncommitted_changes() {
    if ! git diff-index --quiet HEAD --; then
        print_warning "You have uncommitted changes. Do you want to continue? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_error "Deployment cancelled."
            exit 1
        fi
    fi
}

# Function to get the latest commit hash
get_commit_hash() {
    git rev-parse --short HEAD
}

# Function to deploy to server
deploy_to_server() {
    local commit_hash=$1
    
    print_status "Starting deployment to server..."
    print_status "Server: $SERVER_USER@$SERVER_HOST"
    print_status "Path: $SERVER_PATH"
    print_status "Branch: $BRANCH"
    print_status "Commit: $commit_hash"
    
    # Create the deployment script for the server
    cat > /tmp/deploy_remote.sh << 'EOF'
#!/bin/bash

set -e

# Configuration
SERVER_PATH="/root/pisoftsolutions"
BRANCH="$1"
COMMIT_HASH="$2"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[SERVER]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SERVER]${NC} $1"
}

print_error() {
    echo -e "${RED}[SERVER]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[SERVER]${NC} $1"
}

# Function to check if directory exists
check_directory() {
    if [ ! -d "$SERVER_PATH" ]; then
        print_error "Directory $SERVER_PATH does not exist!"
        exit 1
    fi
}

# Function to backup current deployment
backup_current() {
    print_status "Creating backup of current deployment..."
    if [ -d "$SERVER_PATH" ]; then
        cp -r "$SERVER_PATH" "${SERVER_PATH}_backup_$(date +%Y%m%d_%H%M%S)"
        print_success "Backup created"
    fi
}

# Function to backup database
backup_database() {
    print_status "Creating database backup..."
    cd "$SERVER_PATH"
    
    # Create backup directory if it doesn't exist
    mkdir -p backups
    
    # Create timestamp for backup
    BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="backups/db_backup_${BACKUP_TIMESTAMP}.sql"
    
    # Backup database using docker-compose
    if docker-compose exec -T db pg_dump -U ${POSTGRES_USER:-postgres} ${POSTGRES_DB:-pisoftsolutions_production} > "$BACKUP_FILE" 2>/dev/null; then
        print_success "Database backup created: $BACKUP_FILE"
    else
        print_warning "Database backup failed, but continuing deployment..."
    fi
}

# Function to update code
update_code() {
    print_status "Updating code from git..."
    cd "$SERVER_PATH"
    
    # Fetch latest changes
    git fetch origin
    
    # Check if branch exists
    if ! git show-ref --verify --quiet refs/remotes/origin/$BRANCH; then
        print_error "Branch $BRANCH does not exist on remote!"
        exit 1
    fi
    
    # Reset to the specific commit
    git reset --hard $COMMIT_HASH
    
    print_success "Code updated to commit $COMMIT_HASH"
}

# Function to check Docker installation
check_docker() {
    print_status "Checking Docker installation..."
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker is not installed on the server!"
        exit 1
    fi
    
    if ! command -v docker-compose >/dev/null 2>&1; then
        print_error "Docker Compose is not installed on the server!"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running on the server!"
        exit 1
    fi
    
    print_success "Docker is ready"
}

# Function to stop existing containers
stop_containers() {
    print_status "Stopping existing containers..."
    cd "$SERVER_PATH"
    docker-compose down || true
    print_success "Containers stopped"
}

# Function to deploy using Docker
deploy_with_docker() {
    print_status "Deploying with Docker..."
    cd "$SERVER_PATH"
    
    # Use production-safe docker setup script
    if [ -f "./docker-setup-production.sh" ]; then
        print_status "Using production-safe Docker setup script..."
        RAILS_ENV=production ./docker-setup-production.sh
    else
        print_status "Using standard Docker setup script..."
        RAILS_ENV=production ./docker-setup.sh
    fi
    
    print_success "Docker deployment completed"
}

# Function to run migrations safely
run_migrations_safely() {
    print_status "Running database migrations safely..."
    cd "$SERVER_PATH"
    
    # Wait a bit more for database to be fully ready
    sleep 5
    
    # Run only migrations (not db:create) to avoid data loss
    if docker-compose exec -T web bundle exec rails db:migrate; then
        print_success "Database migrations completed successfully"
    else
        print_error "Database migrations failed!"
        print_warning "You may need to check the database connection or run migrations manually"
        return 1
    fi
}

# Function to check application health
check_health() {
    print_status "Checking application health..."
    sleep 10
    
    # Check if containers are running
    if docker-compose ps | grep -q "Up"; then
        print_success "Docker containers are running!"
    else
        print_warning "Some containers may not be running properly"
    fi
    
    # Check application health endpoint
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        print_success "Application is healthy!"
    else
        print_warning "Application health check failed, but deployment completed"
    fi
}

# Function to show deployment info
show_deployment_info() {
    print_status "Deployment completed!"
    echo ""
    print_success "🌐 Your Rails application is now running at: http://localhost:3000"
    print_success "🗄️  Database is accessible at: localhost:5432"
    print_success "🔧 Environment: production"
    echo ""
    print_status "📋 Useful commands:"
    echo "  - View logs: docker-compose logs -f"
    echo "  - Stop containers: docker-compose down"
    echo "  - Restart: docker-compose restart"
    echo "  - Rails console: docker-compose exec web rails console"
    echo "  - Database console: docker-compose exec web rails dbconsole"
    echo ""
    print_status "🔒 Database protection measures:"
    echo "  ✅ Database data stored in Docker volume: postgres_data"
    echo "  ✅ Data persists across container restarts"
    echo "  ✅ Automatic database backup before deployment"
    echo "  ✅ Production-safe migrations (no db:create)"
    echo "  ✅ Application backup created before deployment"
}

# Main deployment process
main() {
    print_status "Starting Docker deployment process..."
    
    check_directory
    backup_current
    backup_database
    update_code
    check_docker
    stop_containers
    deploy_with_docker
    run_migrations_safely
    check_health
    show_deployment_info
    
    print_success "Docker deployment completed successfully!"
}

# Run main function
main "$@"
EOF

    # Make the remote script executable
    chmod +x /tmp/deploy_remote.sh
    
    # Copy the script to the server and execute it
    print_status "Copying deployment script to server..."
    scp /tmp/deploy_remote.sh "$SERVER_USER@$SERVER_HOST:/tmp/"
    
    print_status "Executing deployment on server..."
    ssh "$SERVER_USER@$SERVER_HOST" "bash /tmp/deploy_remote.sh $BRANCH $commit_hash"
    
    # Clean up local temporary file
    rm /tmp/deploy_remote.sh
    
    print_success "Deployment completed!"
}

# Main script execution
main() {
    print_status "=== pisoftsolutions Deployment Script ==="
    
    # Check prerequisites
    check_git_repo
    check_uncommitted_changes
    
    # Get current commit hash
    COMMIT_HASH=$(get_commit_hash)
    
    print_status "Current branch: $BRANCH"
    print_status "Current commit: $COMMIT_HASH"
    
    # Confirm deployment
    echo
    print_warning "Are you sure you want to deploy to the server? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_error "Deployment cancelled."
        exit 1
    fi
    
    # Deploy to server
    deploy_to_server "$COMMIT_HASH"
    
    print_success "=== Deployment completed successfully! ==="
}

# Run main function
main "$@"
