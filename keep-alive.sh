#!/bin/bash

# Keep-alive script for PiSoft Solutions Docker services
# This script monitors and automatically restarts services if they stop

set -e

APP_DIR="/Users/tarun/rails_apps/pisoftsolutions"
LOG_FILE="$APP_DIR/docker-keepalive.log"
CHECK_INTERVAL=60  # Check every 60 seconds

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check if services are running
check_services() {
    cd "$APP_DIR"
    
    # Check if containers are running
    if ! docker-compose ps | grep -q "Up"; then
        log_message "WARNING: Some services are not running!"
        return 1
    fi
    
    # Check database connectivity
    if ! docker-compose exec -T db pg_isready -U postgres > /dev/null 2>&1; then
        log_message "WARNING: Database is not responding!"
        return 1
    fi
    
    # Check web service
    if ! curl -f http://localhost:3000/health > /dev/null 2>&1; then
        log_message "WARNING: Web service is not responding!"
        return 1
    fi
    
    return 0
}

# Function to restart services
restart_services() {
    log_message "Restarting services..."
    cd "$APP_DIR"
    
    # Stop services gracefully
    docker-compose down
    
    # Wait a bit
    sleep 10
    
    # Start services
    docker-compose up -d
    
    # Wait for services to be ready
    sleep 30
    
    # Check if restart was successful
    if check_services; then
        log_message "Services restarted successfully"
        return 0
    else
        log_message "ERROR: Failed to restart services"
        return 1
    fi
}

# Function to show status
show_status() {
    cd "$APP_DIR"
    echo "=== Docker Services Status ==="
    docker-compose ps
    echo ""
    echo "=== Resource Usage ==="
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
    echo ""
    echo "=== Recent Logs ==="
    tail -10 "$LOG_FILE"
}

# Function to run in background
run_monitor() {
    log_message "Starting keep-alive monitor..."
    
    while true; do
        if ! check_services; then
            log_message "Services check failed, attempting restart..."
            restart_services
        else
            log_message "All services are healthy"
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

# Main script logic
case "${1:-monitor}" in
    "monitor")
        run_monitor
        ;;
    "check")
        if check_services; then
            echo "✅ All services are healthy"
            exit 0
        else
            echo "❌ Some services are not healthy"
            exit 1
        fi
        ;;
    "restart")
        restart_services
        ;;
    "status")
        show_status
        ;;
    "logs")
        tail -f "$LOG_FILE"
        ;;
    *)
        echo "Usage: $0 [monitor|check|restart|status|logs]"
        echo ""
        echo "Commands:"
        echo "  monitor  - Run continuous monitoring (default)"
        echo "  check    - Check service health once"
        echo "  restart  - Restart all services"
        echo "  status   - Show current status"
        echo "  logs     - Show monitoring logs"
        exit 1
        ;;
esac
