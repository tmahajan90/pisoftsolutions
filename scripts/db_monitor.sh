#!/bin/bash

# Database Monitoring and Auto-Recovery Script
# This script monitors database health and automatically recovers from crashes

set -e

# Configuration
DB_CONTAINER="pisoftsolutions-db-1"
WEB_CONTAINER="pisoftsolutions-web-1"
LOG_FILE="/var/log/db_monitor.log"
MAX_RETRIES=3
RETRY_DELAY=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if container is running
is_container_running() {
    local container_name=$1
    docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"
}

# Check database connectivity
check_db_connectivity() {
    local container_name=$1
    docker exec "$container_name" pg_isready -U postgres -d pisoftsolutions_production >/dev/null 2>&1
}

# Check database connections
check_db_connections() {
    local container_name=$1
    local connections=$(docker exec "$container_name" psql -U postgres -d pisoftsolutions_production -t -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active';" 2>/dev/null | tr -d ' ')
    echo "${connections:-0}"
}

# Check database locks
check_db_locks() {
    local container_name=$1
    local locks=$(docker exec "$container_name" psql -U postgres -d pisoftsolutions_production -t -c "SELECT count(*) FROM pg_locks WHERE NOT granted;" 2>/dev/null | tr -d ' ')
    echo "${locks:-0}"
}

# Restart database container
restart_db_container() {
    log "${YELLOW}Restarting database container...${NC}"
    docker restart "$DB_CONTAINER"
    sleep 10
    
    # Wait for database to be ready
    local retries=0
    while [ $retries -lt 30 ]; do
        if check_db_connectivity "$DB_CONTAINER"; then
            log "${GREEN}Database container restarted successfully${NC}"
            return 0
        fi
        sleep 2
        retries=$((retries + 1))
    done
    
    log "${RED}Failed to restart database container${NC}"
    return 1
}

# Restart web container
restart_web_container() {
    log "${YELLOW}Restarting web container...${NC}"
    docker restart "$WEB_CONTAINER"
    sleep 5
    log "${GREEN}Web container restarted${NC}"
}

# Kill idle connections
kill_idle_connections() {
    local container_name=$1
    log "${YELLOW}Killing idle connections...${NC}"
    docker exec "$container_name" psql -U postgres -d pisoftsolutions_production -c "
        SELECT pg_terminate_backend(pid) 
        FROM pg_stat_activity 
        WHERE state = 'idle' 
        AND state_change < now() - interval '5 minutes'
        AND pid <> pg_backend_pid();
    " >/dev/null 2>&1
}

# Main monitoring function
monitor_database() {
    log "Starting database monitoring..."
    
    while true; do
        # Check if database container is running
        if ! is_container_running "$DB_CONTAINER"; then
            log "${RED}Database container is not running! Attempting to start...${NC}"
            docker start "$DB_CONTAINER"
            sleep 10
            continue
        fi
        
        # Check database connectivity
        if ! check_db_connectivity "$DB_CONTAINER"; then
            log "${RED}Database is not responding! Attempting recovery...${NC}"
            restart_db_container
            continue
        fi
        
        # Check connection count
        local connections=$(check_db_connections "$DB_CONTAINER")
        if [ "$connections" -gt 80 ]; then
            log "${YELLOW}High connection count: $connections. Killing idle connections...${NC}"
            kill_idle_connections "$DB_CONTAINER"
        fi
        
        # Check for locks
        local locks=$(check_db_locks "$DB_CONTAINER")
        if [ "$locks" -gt 10 ]; then
            log "${YELLOW}High lock count: $locks. This may indicate deadlocks.${NC}"
        fi
        
        # Check web container
        if ! is_container_running "$WEB_CONTAINER"; then
            log "${RED}Web container is not running! Attempting to start...${NC}"
            docker start "$WEB_CONTAINER"
        fi
        
        log "${GREEN}Database health check passed. Connections: $connections, Locks: $locks${NC}"
        sleep 60
    done
}

# Recovery function
recover_database() {
    log "${YELLOW}Starting database recovery process...${NC}"
    
    # Stop all containers
    docker compose down
    
    # Clean up any orphaned containers
    docker container prune -f
    
    # Remove any problematic volumes (be careful with this in production)
    # docker volume prune -f
    
    # Start database first
    docker compose up -d db
    
    # Wait for database to be ready
    local retries=0
    while [ $retries -lt 60 ]; do
        if check_db_connectivity "$DB_CONTAINER"; then
            log "${GREEN}Database is ready${NC}"
            break
        fi
        sleep 2
        retries=$((retries + 1))
    done
    
    if [ $retries -eq 60 ]; then
        log "${RED}Database failed to start after 2 minutes${NC}"
        return 1
    fi
    
    # Run database migrations
    docker compose run --rm web rails db:migrate
    
    # Start web container
    docker compose up -d web
    
    log "${GREEN}Database recovery completed${NC}"
}

# Main script
case "${1:-monitor}" in
    "monitor")
        monitor_database
        ;;
    "recover")
        recover_database
        ;;
    "status")
        echo "Database Container: $(is_container_running "$DB_CONTAINER" && echo "Running" || echo "Stopped")"
        echo "Web Container: $(is_container_running "$WEB_CONTAINER" && echo "Running" || echo "Stopped")"
        if is_container_running "$DB_CONTAINER"; then
            echo "Database Connectivity: $(check_db_connectivity "$DB_CONTAINER" && echo "OK" || echo "Failed")"
            echo "Active Connections: $(check_db_connections "$DB_CONTAINER")"
            echo "Blocked Locks: $(check_db_locks "$DB_CONTAINER")"
        fi
        ;;
    *)
        echo "Usage: $0 {monitor|recover|status}"
        exit 1
        ;;
esac
