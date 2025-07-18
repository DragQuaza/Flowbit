#!/bin/bash

echo "🚀 Starting Flowbit System with Mock Database (for demo purposes)..."

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

echo "⚠️  Starting with mock database - some features may be limited"
echo "📝 For full functionality, start Docker Desktop and use ./start-dev.sh"

# Create a simple mock database file
cat > mock-db.json << 'EOF'
{
  "users": [
    {
      "id": "1",
      "email": "admin@tenant-a.com",
      "password": "$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi",
      "customerId": "tenant-a",
      "role": "Admin"
    },
    {
      "id": "2",
      "email": "admin@tenant-b.com",
      "password": "$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi",
      "customerId": "tenant-b",
      "role": "Admin"
    }
  ],
  "tickets": []
}
EOF

echo "🎯 Starting services..."

# Start auth service with mock flag
echo "🔐 Starting auth service on port 3001..."
cd auth-service
npm run start:mock &
AUTH_PID=$!
cd ..

# Start API service with mock flag
echo "🚀 Starting API service on port 3002..."
cd api
npm run start:mock &
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
echo ""
echo "📖 Demo accounts (password: 'password'):"
echo "- Admin Tenant A: admin@tenant-a.com"
echo "- Admin Tenant B: admin@tenant-b.com"
echo ""
echo "⚠️  Note: Using mock database - data won't persist between restarts"
echo "💡 For full functionality with MongoDB and n8n:"
echo "   1. Start Docker Desktop"
echo "   2. Run: ./start-dev.sh"
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
    
    rm -f mock-db.json
    echo "✅ All services stopped!"
    exit 0
}

wait
