#!/bin/bash

# Script to manage all platform services
# Usage examples:
#   ./run.sh up
#   ./run.sh down
#   ./run.sh start all
#   ./run.sh stop mlflow

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Services array
SERVICES=("mlflow" "kafka" "monitor" "airflow")

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to run command for one service
run_for_service() {
    local service=$1
    local action=$2

    if [ -d "$SCRIPT_DIR/$service" ] && [ -f "$SCRIPT_DIR/$service/docker-compose.yaml" ]; then
        if [ "$action" = "up" ]; then
            print_message "$BLUE" "Starting $service..."
            cd "$SCRIPT_DIR/$service"
            docker compose up -d
        elif [ "$action" = "down" ]; then
            print_message "$BLUE" "Stopping $service..."
            cd "$SCRIPT_DIR/$service"
            docker compose down
        elif [ "$action" = "status" ]; then
            print_message "$BLUE" "Status of $service:"
            cd "$SCRIPT_DIR/$service"
            docker compose ps
        fi
        echo ""
    else
        print_message "$YELLOW" "Warning: $service directory or docker-compose.yaml not found"
    fi
}

# Function to start services
start_services() {
    local target=${1:-all}
    print_message "$GREEN" "Starting services: $target"
    echo ""

    if [ "$target" = "all" ]; then
        for service in "${SERVICES[@]}"; do
            run_for_service "$service" "up"
        done
    else
        run_for_service "$target" "up"
    fi

    print_message "$GREEN" "Start command completed."
}

# Function to stop services
stop_services() {
    local target=${1:-all}
    print_message "$RED" "Stopping services: $target"
    echo ""

    if [ "$target" = "all" ]; then
        for service in "${SERVICES[@]}"; do
            run_for_service "$service" "down"
        done
    else
        run_for_service "$target" "down"
    fi

    print_message "$GREEN" "Stop command completed."
}

# Function to restart all services
restart_services() {
    print_message "$YELLOW" "Restarting all platform services..."
    echo ""
    stop_services
    echo ""
    start_services
}

# Function to show status of all services
status_services() {
    local target=${1:-all}
    print_message "$BLUE" "Checking status: $target"
    echo ""

    if [ "$target" = "all" ]; then
        for service in "${SERVICES[@]}"; do
            run_for_service "$service" "status"
        done
    else
        run_for_service "$target" "status"
    fi
}

# Function to show help
show_help() {
    echo "Platform Services Management Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  up [target]        - Start services"
    echo "  down [target]      - Stop services"
    echo "  restart            - Restart all platform services"
    echo "  status [target]    - Show service status"
    echo "  start [target]     - Alias of up"
    echo "  stop [target]      - Alias of down"
    echo "  help      - Show this help message"
    echo ""
    echo "Targets: all | mlflow | kafka | monitor | airflow"
    echo ""
    echo "Services managed:"
    for service in "${SERVICES[@]}"; do
        echo "  - $service"
    done
}

# Main script logic
COMMAND="${1:-}"
TARGET="${2:-all}"

case "$COMMAND" in
    up|start)
        start_services "$TARGET"
        ;;
    down|stop)
        stop_services "$TARGET"
        ;;
    restart)
        restart_services
        ;;
    status)
        status_services "$TARGET"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_message "$RED" "Error: Invalid command '${1:-}'"
        echo ""
        show_help
        exit 1
        ;;
esac
