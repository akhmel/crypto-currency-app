#!/bin/bash

# Development startup script for crypto-currency-app
# This script sets up and runs the development environment

set -e

echo "🚀 Starting crypto-currency-app development environment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose is not installed. Please install it and try again."
    exit 1
fi

# Function to cleanup on exit
cleanup() {
    echo "🛑 Shutting down development environment..."
    docker-compose -f docker-compose.dev.yml down
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Build the development image
echo "🔨 Building development Docker image..."
docker-compose -f docker-compose.dev.yml build

# Start the services
echo "📦 Starting development services..."
docker-compose -f docker-compose.dev.yml up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check service health
echo "🔍 Checking service health..."
if docker-compose -f docker-compose.dev.yml ps | grep -q "unhealthy"; then
    echo "⚠️  Some services are unhealthy. Check the logs with: docker-compose -f docker-compose.dev.yml logs"
else
    echo "✅ All services are healthy!"
fi

echo ""
echo "🎉 Development environment is ready!"
echo ""
echo "📱 Access your application:"
echo "   • Rails app: http://localhost:3000"
echo "   • Vite dev server: http://localhost:3036"
echo "   • MailHog (email testing): http://localhost:8025"
echo ""
echo "🗄️  Database connections:"
echo "   • PostgreSQL: localhost:5432"
echo "   • Redis: localhost:6379"
echo "   • Kafka: localhost:9092"
echo ""
echo "📋 Useful commands:"
echo "   • View logs: docker-compose -f docker-compose.dev.yml logs -f"
echo "   • Stop services: docker-compose -f docker-compose.dev.yml down"
echo "   • Rebuild: docker-compose -f docker-compose.dev.yml build --no-cache"
echo "   • Shell access: docker-compose -f docker-compose.dev.yml exec app bash"
echo ""

# Keep the script running and show logs
echo "📺 Following logs (press Ctrl+C to stop)..."
docker-compose -f docker-compose.dev.yml logs -f
