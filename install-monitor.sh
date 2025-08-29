#!/bin/bash

# PiSoft Solutions - Monitor Installation Script
# This script installs and manages the Docker container monitoring service

SERVICE_NAME="pisoftsolutions-monitor"
SERVICE_FILE="pisoftsolutions-monitor.service"
CURRENT_DIR=$(pwd)

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

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_status $RED "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to install the service
install_service() {
    print_status $BLUE "Installing PiSoft Solutions monitoring service..."
    
    # Check if service file exists
    if [ ! -f "$SERVICE_FILE" ]; then
        print_status $RED "Service file $SERVICE_FILE not found"
        exit 1
    fi
    
    # Check if monitor script exists
    if [ ! -f "monitor.sh" ]; then
        print_status $RED "Monitor script monitor.sh not found"
        exit 1
    fi
    
    # Copy service file to systemd directory
    cp "$SERVICE_FILE" "/etc/systemd/system/"
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable service to start on boot
    systemctl enable "$SERVICE_NAME"
    
    print_status $GREEN "Service installed and enabled successfully!"
    print_status $YELLOW "To start the service now, run: sudo ./install-monitor.sh start"
}

# Function to start the service
start_service() {
    print_status $BLUE "Starting monitoring service..."
    systemctl start "$SERVICE_NAME"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        print_status $GREEN "Service started successfully!"
    else
        print_status $RED "Failed to start service"
        systemctl status "$SERVICE_NAME"
        exit 1
    fi
}

# Function to stop the service
stop_service() {
    print_status $BLUE "Stopping monitoring service..."
    systemctl stop "$SERVICE_NAME"
    print_status $GREEN "Service stopped"
}

# Function to restart the service
restart_service() {
    print_status $BLUE "Restarting monitoring service..."
    systemctl restart "$SERVICE_NAME"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        print_status $GREEN "Service restarted successfully!"
    else
        print_status $RED "Failed to restart service"
        systemctl status "$SERVICE_NAME"
        exit 1
    fi
}

# Function to check service status
status_service() {
    print_status $BLUE "Checking service status..."
    systemctl status "$SERVICE_NAME"
}

# Function to view logs
view_logs() {
    print_status $BLUE "Viewing service logs..."
    journalctl -u "$SERVICE_NAME" -f
}

# Function to uninstall the service
uninstall_service() {
    print_status $YELLOW "Uninstalling monitoring service..."
    
    # Stop and disable service
    systemctl stop "$SERVICE_NAME" 2>/dev/null
    systemctl disable "$SERVICE_NAME" 2>/dev/null
    
    # Remove service file
    rm -f "/etc/systemd/system/$SERVICE_FILE"
    
    # Reload systemd
    systemctl daemon-reload
    
    print_status $GREEN "Service uninstalled successfully!"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install    - Install and enable the monitoring service"
    echo "  start      - Start the monitoring service"
    echo "  stop       - Stop the monitoring service"
    echo "  restart    - Restart the monitoring service"
    echo "  status     - Check service status"
    echo "  logs       - View service logs"
    echo "  uninstall  - Uninstall the monitoring service"
    echo "  help       - Show this help message"
    echo ""
    echo "Examples:"
    echo "  sudo $0 install    # Install the service"
    echo "  sudo $0 start      # Start monitoring"
    echo "  sudo $0 status     # Check if running"
    echo "  sudo $0 logs       # View logs"
}

# Main script logic
case "$1" in
    install)
        check_root
        install_service
        ;;
    start)
        check_root
        start_service
        ;;
    stop)
        check_root
        stop_service
        ;;
    restart)
        check_root
        restart_service
        ;;
    status)
        status_service
        ;;
    logs)
        view_logs
        ;;
    uninstall)
        check_root
        uninstall_service
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
