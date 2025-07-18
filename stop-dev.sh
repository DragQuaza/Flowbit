#!/bin/bash

echo "🛑 Stopping Flowbit Development Services..."

# Kill Node.js processes
if [ -f .dev-pids ]; then
    cat .dev-pids | xargs kill 2>/dev/null || true
    rm .dev-pids
    echo "✅ Node.js services stopped"
fi

# Stop Docker containers
docker stop flowbit-mongo flowbit-n8n 2>/dev/null || true
docker rm flowbit-mongo flowbit-n8n 2>/dev/null || true
echo "✅ Docker containers stopped"

# Kill any remaining processes on our ports
for port in 3001 3002 3003 3000; do
    lsof -ti:$port | xargs kill -9 2>/dev/null || true
done

echo "✅ All services stopped!"
