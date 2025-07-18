#!/bin/bash

echo "🚀 Starting Flowbit System in Development Mode..."

# Function to check if port is in use
port_in_use() {
    lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null
}

# Kill any existing processes on our ports
echo "📋 Cleaning up existing processes..."
for port in 3001 3002 3003 3000; do
    if port_in_use $port; then
        echo "Killing process on port $port..."
        lsof -ti:$port | xargs kill -9 2>/dev/null || true
    fi
done

# Start MongoDB using Docker (simpler than full docker-compose)
echo "🍃 Starting MongoDB..."
docker run -d --name flowbit-mongo -p 27017:27017 -e MONGO_INITDB_ROOT_USERNAME=admin -e MONGO_INITDB_ROOT_PASSWORD=password -e MONGO_INITDB_DATABASE=flowbit mongo:7.0 2>/dev/null || echo "MongoDB container already running"

# Start n8n using Docker  
echo "🔄 Starting n8n..."
docker run -d --name flowbit-n8n -p 5678:5678 -e N8N_BASIC_AUTH_ACTIVE=true -e N8N_BASIC_AUTH_USER=admin -e N8N_BASIC_AUTH_PASSWORD=password -e N8N_PROTOCOL=http -e N8N_HOST=0.0.0.0 -e N8N_PORT=5678 -e GENERIC_TIMEZONE=UTC n8nio/n8n:latest 2>/dev/null || echo "n8n container already running"

# Wait for MongoDB to be ready
echo "⏳ Waiting for MongoDB to be ready..."
sleep 5

# Create demo users
echo "👥 Creating demo users..."
node create-demo-users.js

echo "🎯 Starting services..."

# Start auth service
echo "🔐 Starting auth service on port 3001..."
cd auth-service
npm start &
AUTH_PID=$!
cd ..

# Start API service
echo "🚀 Starting API service on port 3002..."
cd api
npm start &
API_PID=$!
cd ..

# Start support tickets app
echo "🎫 Starting support tickets app on port 3003..."
cd support-tickets-app
npm run dev &
TICKETS_PID=$!
cd ..

# Start React shell
echo "⚛️ Starting React shell on port 3000..."
cd react-shell
npm run dev &
SHELL_PID=$!
cd ..

# Store PIDs for cleanup
echo $AUTH_PID $API_PID $TICKETS_PID $SHELL_PID > .dev-pids

echo "✅ All services started!"
echo ""
echo "🌐 Application URLs:"
echo "- Main App: http://localhost:3000"
echo "- Auth Service: http://localhost:3001"
echo "- API Service: http://localhost:3002"
echo "- Support Tickets: http://localhost:3003"
echo "- n8n: http://localhost:5678 (admin/password)"
echo ""
echo "📖 Demo accounts:"
echo "- Admin Tenant A: admin@tenant-a.com / password"
echo "- User Tenant A: user@tenant-a.com / password"
echo "- Admin Tenant B: admin@tenant-b.com / password"
echo "- User Tenant B: user@tenant-b.com / password"
echo ""
echo "🔄 To stop all services, run: ./stop-dev.sh"
echo ""
echo "⌨️  Press Ctrl+C to stop all services"

# Wait for user interrupt
trap cleanup INT

cleanup() {
    echo "🛑 Stopping services..."
    if [ -f .dev-pids ]; then
        cat .dev-pids | xargs kill 2>/dev/null || true
        rm .dev-pids
    fi
    
    # Stop Docker containers
    docker stop flowbit-mongo flowbit-n8n 2>/dev/null || true
    docker rm flowbit-mongo flowbit-n8n 2>/dev/null || true
    
    echo "✅ All services stopped!"
    exit 0
}

wait
