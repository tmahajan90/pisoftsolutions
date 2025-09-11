#!/bin/bash

# Docker monitoring script for pisoftsolutions
# This script helps monitor and restart Docker services if needed

set -e

echo "🐳 Docker Services Monitor for PiSoft Solutions"
echo "================================================"

# Function to check if services are running
check_services() {
    echo "📊 Checking service status..."
    docker-compose ps
    
    echo ""
    echo "🔍 Checking service logs..."
    echo "Database logs (last 10 lines):"
    docker-compose logs --tail=10 db || echo "Database service not running"
    
    echo ""
    echo "Web logs (last 10 lines):"
    docker-compose logs --tail=10 web || echo "Web service not running"
}

# Function to restart services
restart_services() {
    echo "🔄 Restarting services..."
    docker-compose down
    docker-compose up -d
    
    echo "⏳ Waiting for services to start..."
    sleep 10
    
    echo "✅ Services restarted. Current status:"
    docker-compose ps
}

# Function to check database connectivity
check_database() {
    echo "🗄️  Checking database connectivity..."
    
    # Try to connect to database
    if docker-compose exec -T db pg_isready -U postgres > /dev/null 2>&1; then
        echo "✅ Database is ready and accepting connections"
        
        # Check if we can connect from web service
        if docker-compose exec -T web bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" > /dev/null 2>&1; then
            echo "✅ Web service can connect to database"
        else
            echo "❌ Web service cannot connect to database"
            return 1
        fi
    else
        echo "❌ Database is not ready"
        return 1
    fi
}

# Function to show resource usage
show_resources() {
    echo "💾 Resource usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
}

# Function to clean up
cleanup() {
    echo "🧹 Cleaning up Docker resources..."
    docker system prune -f
    docker volume prune -f
}

# Main script logic
case "${1:-check}" in
    "check")
        check_services
        echo ""
        check_database
        echo ""
        show_resources
        ;;
    "restart")
        restart_services
        ;;
    "cleanup")
        cleanup
        ;;
    "full-restart")
        echo "🔄 Full restart with cleanup..."
        cleanup
        restart_services
        check_database
        ;;
    *)
        echo "Usage: $0 [check|restart|cleanup|full-restart]"
        echo ""
        echo "Commands:"
        echo "  check        - Check service status and connectivity (default)"
        echo "  restart      - Restart all services"
        echo "  cleanup      - Clean up Docker resources"
        echo "  full-restart - Clean up and restart all services"
        exit 1
        ;;
esac

echo ""
echo "✨ Monitor script completed!"
