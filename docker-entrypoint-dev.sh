#!/bin/bash
set -e

# Exit immediately if a command exits with a non-zero status
set -o errexit

# Function to handle shutdown gracefully
cleanup() {
    echo "Shutting down development servers..."
    if [ ! -z "$RAILS_PID" ]; then
        kill $RAILS_PID 2>/dev/null || true
    fi
    if [ ! -z "$VITE_PID" ]; then
        kill $VITE_PID 2>/dev/null || true
    fi
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT


echo "Setting up database..."
bundle exec rails db:drop db:create db:migrate db:seed


# Start Vite development server in background
echo "Starting Vite development server..."
cd /rails
bundle exec rails vite:build &
VITE_PID=$!

# Wait a moment for Vite to start
sleep 3

# Start Rails server in background
echo "Starting Rails development server..."
bundle exec rails server -b 0.0.0.0 -p 3000 &
RAILS_PID=$!

# Wait for both processes
wait $RAILS_PID $VITE_PID
