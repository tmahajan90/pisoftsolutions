#!/bin/bash

# PiSoft Solutions - Docker Container Monitor
# This script keeps the Docker containers running 24/7

APP_NAME="pisoftsolutions"
LOG_FILE="monitor.log"
CHECK_INTERVAL=30  # Check every 30 seconds
MAX_RESTART_ATTEMPTS=5
RESTART_COOLDOWN=300  # 5 minutes cooldown between restart attempts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to check if containers are running
check_containers() {
    local containers_running=true
    
    # Check if docker-compose is running
    if ! docker-compose ps | grep -q "Up"; then
        containers_running=false
    fi
    
    # Check specific services
    if ! docker-compose ps web | grep -q "Up"; then
        log_message "WARN" "Web container is not running"
        containers_running=false
    fi
    
    if ! docker-compose ps db | grep -q "Up"; then
        log_message "WARN" "Database container is not running"
        containers_running=false
    fi
    
    echo $containers_running
}

# Function to restart containers
restart_containers() {
    log_message "INFO" "Attempting to restart containers..."
    
    # Stop containers gracefully
    docker-compose down --timeout 30
    
    # Wait a moment
    sleep 5
    
    # Start containers
    docker-compose up -d
    
    # Wait for containers to start
    sleep 15
    
    # Check if restart was successful
    if [ "$(check_containers)" = "true" ]; then
        log_message "SUCCESS" "Containers restarted successfully"
        return 0
    else
        log_message "ERROR" "Failed to restart containers"
        return 1
    fi
}

# Function to check application health
check_application_health() {
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f http://localhost:3000 > /dev/null 2>&1; then
            return 0
        fi
        
        log_message "WARN" "Application health check failed (attempt $attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    return 1
}

# Function to send notification (you can customize this)
send_notification() {
    local message=$1
    # Example: Send email, Slack notification, etc.
    # echo "$message" | mail -s "Docker Monitor Alert" your-email@example.com
    log_message "ALERT" "Notification: $message"
}

# Main monitoring loop
main() {
    log_message "INFO" "Starting Docker container monitor for $APP_NAME"
    log_message "INFO" "Check interval: ${CHECK_INTERVAL}s, Max restart attempts: $MAX_RESTART_ATTEMPTS"
    
    local restart_count=0
    local last_restart_time=0
    
    while true; do
        local current_time=$(date +%s)
        
        # Check if containers are running
        if [ "$(check_containers)" = "false" ]; then
            log_message "ERROR" "Containers are not running"
            
            # Check if we should attempt restart
            if [ $restart_count -lt $MAX_RESTART_ATTEMPTS ]; then
                if [ $((current_time - last_restart_time)) -gt $RESTART_COOLDOWN ]; then
                    log_message "INFO" "Attempting restart (${restart_count}/$MAX_RESTART_ATTEMPTS)"
                    
                    if restart_containers; then
                        restart_count=0
                        last_restart_time=$current_time
                        send_notification "Containers restarted successfully"
                    else
                        ((restart_count++))
                        last_restart_time=$current_time
                        send_notification "Failed to restart containers (attempt $restart_count)"
                    fi
                else
                    local remaining_cooldown=$((RESTART_COOLDOWN - (current_time - last_restart_time)))
                    log_message "WARN" "Restart cooldown active. Waiting ${remaining_cooldown}s before next attempt"
                fi
            else
                log_message "CRITICAL" "Maximum restart attempts reached. Manual intervention required"
                send_notification "CRITICAL: Maximum restart attempts reached for $APP_NAME"
                break
            fi
        else
            # Containers are running, check application health
            if check_application_health; then
                if [ $restart_count -gt 0 ]; then
                    log_message "SUCCESS" "Application is healthy after restart"
                    restart_count=0
                    send_notification "Application recovered and is running normally"
                fi
            else
                log_message "WARN" "Containers running but application health check failed"
            fi
        fi
        
        # Sleep before next check
        sleep $CHECK_INTERVAL
    done
}

# Signal handling
cleanup() {
    log_message "INFO" "Monitor stopped by user"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: docker-compose.yml not found${NC}"
    exit 1
fi

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi

# Start monitoring
main
