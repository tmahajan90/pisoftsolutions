#!/bin/bash

# Production startup script for PiSoft Solutions
# This script ensures Docker containers stay running in production

set -e

echo "🚀 Starting PiSoft Solutions in Production Mode"
echo "=============================================="

# Function to check if containers are running
check_containers() {
    echo "📊 Checking container status..."
    docker-compose ps
}

# Function to start services with production settings
start_production() {
    echo "🔧 Starting services in production mode..."
    
    # Set production environment
    export RAILS_ENV=production
    
    # Start services in detached mode
    docker-compose up -d
    
    echo "⏳ Waiting for services to be ready..."
    sleep 15
    
    # Check if services are healthy
    echo "🔍 Checking service health..."
    docker-compose ps
    
    # Test database connectivity
    echo "🗄️  Testing database connectivity..."
    if docker-compose exec -T db pg_isready -U postgres > /dev/null 2>&1; then
        echo "✅ Database is ready"
    else
        echo "❌ Database is not ready, retrying..."
        sleep 10
        docker-compose exec -T db pg_isready -U postgres
    fi
    
    # Test web service
    echo "🌐 Testing web service..."
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        echo "✅ Web service is ready"
    else
        echo "❌ Web service is not ready, retrying..."
        sleep 10
        curl -f http://localhost:3000/health
    fi
}

# Function to monitor services
monitor_services() {
    echo "👀 Starting service monitoring..."
    echo "Press Ctrl+C to stop monitoring (containers will keep running)"
    
    while true; do
        echo "$(date): Checking services..."
        
        # Check if containers are still running
        if ! docker-compose ps | grep -q "Up"; then
            echo "⚠️  Warning: Some services are not running!"
            docker-compose ps
            echo "🔄 Attempting to restart services..."
            docker-compose up -d
        else
            echo "✅ All services are running"
        fi
        
        # Show resource usage
        echo "💾 Resource usage:"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | head -3
        
        sleep 60  # Check every minute
    done
}

# Function to show logs
show_logs() {
    echo "📋 Showing recent logs..."
    echo "Database logs (last 20 lines):"
    docker-compose logs --tail=20 db
    echo ""
    echo "Web logs (last 20 lines):"
    docker-compose logs --tail=20 web
}

# Main script logic
case "${1:-start}" in
    "start")
        start_production
        echo ""
        echo "🎉 Production services started successfully!"
        echo "🌐 Web service: http://localhost:3000"
        echo "🗄️  Database: localhost:5432"
        echo ""
        echo "To monitor services: $0 monitor"
        echo "To view logs: $0 logs"
        echo "To stop services: docker-compose down"
        ;;
    "monitor")
        monitor_services
        ;;
    "logs")
        show_logs
        ;;
    "restart")
        echo "🔄 Restarting services..."
        docker-compose down
        start_production
        ;;
    "status")
        check_containers
        ;;
    *)
        echo "Usage: $0 [start|monitor|logs|restart|status]"
        echo ""
        echo "Commands:"
        echo "  start    - Start services in production mode (default)"
        echo "  monitor  - Monitor services continuously"
        echo "  logs     - Show recent logs"
        echo "  restart  - Restart all services"
        echo "  status   - Check container status"
        exit 1
        ;;
esac
