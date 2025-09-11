#!/bin/bash

# PiSoft Solutions - Simple Monitor Starter
# This script starts the monitoring in the background

MONITOR_SCRIPT="monitor.sh"
PID_FILE="monitor.pid"
LOG_FILE="monitor.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}$message${NC}"
}

# Function to check if monitor is already running
is_monitor_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            # PID file exists but process is dead
            rm -f "$PID_FILE"
        fi
    fi
    return 1
}

# Function to start monitoring
start_monitor() {
    if is_monitor_running; then
        print_status $YELLOW "Monitor is already running (PID: $(cat $PID_FILE))"
        return 0
    fi
    
    print_status $BLUE "Starting Docker container monitor..."
    
    # Check if monitor script exists
    if [ ! -f "$MONITOR_SCRIPT" ]; then
        print_status $RED "Monitor script $MONITOR_SCRIPT not found"
        exit 1
    fi
    
    # Check if docker-compose.yml exists
    if [ ! -f "docker-compose.yml" ]; then
        print_status $RED "docker-compose.yml not found"
        exit 1
    fi
    
    # Start monitor in background
    nohup ./"$MONITOR_SCRIPT" > "$LOG_FILE" 2>&1 &
    local pid=$!
    
    # Save PID
    echo $pid > "$PID_FILE"
    
    # Wait a moment and check if it started successfully
    sleep 2
    if ps -p "$pid" > /dev/null 2>&1; then
        print_status $GREEN "Monitor started successfully (PID: $pid)"
        print_status $BLUE "Logs are being written to: $LOG_FILE"
        print_status $YELLOW "To stop the monitor, run: ./start-monitor.sh stop"
    else
        print_status $RED "Failed to start monitor"
        rm -f "$PID_FILE"
        exit 1
    fi
}

# Function to stop monitoring
stop_monitor() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            print_status $BLUE "Stopping monitor (PID: $pid)..."
            kill "$pid"
            
            # Wait for process to stop
            local count=0
            while ps -p "$pid" > /dev/null 2>&1 && [ $count -lt 10 ]; do
                sleep 1
                ((count++))
            done
            
            if ps -p "$pid" > /dev/null 2>&1; then
                print_status $YELLOW "Force killing monitor..."
                kill -9 "$pid"
            fi
            
            rm -f "$PID_FILE"
            print_status $GREEN "Monitor stopped"
        else
            print_status $YELLOW "Monitor is not running"
            rm -f "$PID_FILE"
        fi
    else
        print_status $YELLOW "Monitor is not running"
    fi
}

# Function to check status
check_status() {
    if is_monitor_running; then
        local pid=$(cat "$PID_FILE")
        print_status $GREEN "Monitor is running (PID: $pid)"
        
        # Show recent logs
        if [ -f "$LOG_FILE" ]; then
            print_status $BLUE "Recent logs:"
            tail -10 "$LOG_FILE"
        fi
    else
        print_status $RED "Monitor is not running"
    fi
}

# Function to view logs
view_logs() {
    if [ -f "$LOG_FILE" ]; then
        print_status $BLUE "Showing monitor logs (Ctrl+C to exit):"
        tail -f "$LOG_FILE"
    else
        print_status $YELLOW "No log file found"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     - Start the monitoring service"
    echo "  stop      - Stop the monitoring service"
    echo "  status    - Check if monitor is running"
    echo "  logs      - View monitor logs"
    echo "  restart   - Restart the monitoring service"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start     # Start monitoring"
    echo "  $0 status    # Check if running"
    echo "  $0 logs      # View logs"
    echo "  $0 stop      # Stop monitoring"
}

# Main script logic
case "$1" in
    start)
        start_monitor
        ;;
    stop)
        stop_monitor
        ;;
    restart)
        stop_monitor
        sleep 2
        start_monitor
        ;;
    status)
        check_status
        ;;
    logs)
        view_logs
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_status $RED "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac
