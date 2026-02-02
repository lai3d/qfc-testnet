#!/bin/bash
# Deploy QFC Testnet locally

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$PROJECT_DIR/docker"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    }

    log_info "Docker is ready"
}

# Check Docker Compose
check_compose() {
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    log_info "Docker Compose is ready"
}

# Setup environment
setup_env() {
    if [ ! -f "$DOCKER_DIR/.env" ]; then
        log_info "Creating .env file from template..."
        cp "$DOCKER_DIR/.env.example" "$DOCKER_DIR/.env"
    fi
}

# Build images
build_images() {
    log_info "Building Docker images..."

    cd "$PROJECT_DIR/.."

    # Build qfc-core (if exists)
    if [ -d "qfc-core" ]; then
        log_info "Building qfc-core..."
        docker build -t qfc/node:latest ./qfc-core || log_warn "Failed to build qfc-core"
    fi

    # Build qfc-explorer (if exists)
    if [ -d "qfc-explorer" ]; then
        log_info "Building qfc-explorer..."
        docker build -t qfc/explorer:latest ./qfc-explorer || log_warn "Failed to build qfc-explorer"
    fi

    # Build qfc-faucet (if exists)
    if [ -d "qfc-faucet" ]; then
        log_info "Building qfc-faucet..."
        docker build -t qfc/faucet:latest ./qfc-faucet || log_warn "Failed to build qfc-faucet"
    fi
}

# Start services
start_single() {
    log_info "Starting single-node testnet..."
    cd "$DOCKER_DIR"
    docker-compose up -d
}

start_multi() {
    log_info "Starting multi-node testnet (5 validators)..."
    cd "$DOCKER_DIR"
    docker-compose -f docker-compose.multi.yml up -d
}

# Stop services
stop_all() {
    log_info "Stopping all services..."
    cd "$DOCKER_DIR"
    docker-compose down 2>/dev/null || true
    docker-compose -f docker-compose.multi.yml down 2>/dev/null || true
}

# Show status
show_status() {
    log_info "Service status:"
    cd "$DOCKER_DIR"
    docker-compose ps 2>/dev/null || docker-compose -f docker-compose.multi.yml ps 2>/dev/null
}

# Show logs
show_logs() {
    cd "$DOCKER_DIR"
    docker-compose logs -f "$@"
}

# Print usage
usage() {
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  single    Start single-node testnet"
    echo "  multi     Start multi-node testnet (5 validators)"
    echo "  stop      Stop all services"
    echo "  status    Show service status"
    echo "  logs      Show logs (add service name for specific logs)"
    echo "  build     Build Docker images"
    echo ""
    echo "Examples:"
    echo "  $0 single          # Start single node"
    echo "  $0 multi           # Start 5 validators"
    echo "  $0 logs node-1     # Show node-1 logs"
}

# Main
main() {
    check_docker
    check_compose
    setup_env

    case "${1:-}" in
        single)
            build_images
            start_single
            log_info "Testnet started!"
            log_info "RPC: http://localhost:8545"
            log_info "Explorer: http://localhost:3000"
            log_info "Faucet: http://localhost:3001"
            log_info "Grafana: http://localhost:3002 (admin/admin)"
            ;;
        multi)
            build_images
            start_multi
            log_info "Multi-node testnet started!"
            ;;
        stop)
            stop_all
            log_info "All services stopped"
            ;;
        status)
            show_status
            ;;
        logs)
            shift
            show_logs "$@"
            ;;
        build)
            build_images
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
