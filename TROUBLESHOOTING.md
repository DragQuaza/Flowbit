# Troubleshooting Guide - Flowbit System

## MongoDB Connection Issues

### Problem
```
MongooseServerSelectionError: connect ECONNREFUSED ::1:27017, connect ECONNREFUSED 127.0.0.1:27017
```

### Root Causes & Solutions

#### 1. Docker Desktop Not Running
**Symptoms:** 
- `Cannot connect to the Docker daemon at unix:///Users/debanjanmaity/.docker/run/docker.sock`
- Docker commands fail

**Solution:**
```bash
# On macOS: Start Docker Desktop application
open -a Docker

# Wait for Docker to start completely (check whale icon in menu bar)
# Then retry: ./start-dev.sh
```

#### 2. MongoDB Container Not Running Properly
**Check if MongoDB is running:**
```bash
docker ps | grep mongo
```

**If not running, start MongoDB manually:**
```bash
# Remove any existing broken containers
docker rm -f flowbit-mongo

# Start fresh MongoDB container
docker run -d --name flowbit-mongo \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=password \
  -e MONGO_INITDB_DATABASE=flowbit \
  mongo:7.0

# Wait 10 seconds for MongoDB to start
sleep 10

# Test connection
node create-demo-users.js
```

#### 3. Port 27017 Already in Use
**Check what's using port 27017:**
```bash
lsof -i :27017
```

**If another process is using it:**
```bash
# Kill the process (replace PID with actual PID from lsof output)
kill -9 <PID>

# Or use a different port for MongoDB
docker run -d --name flowbit-mongo \
  -p 27018:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=password \
  -e MONGO_INITDB_DATABASE=flowbit \
  mongo:7.0
```

#### 4. Network Configuration Issues
**If localhost doesn't work, try:**
```bash
# Update MongoDB connection string to use 127.0.0.1 instead of localhost
# Edit auth-service/server.js and api/server.js:
mongodb://admin:password@127.0.0.1:27017/flowbit?authSource=admin
```

### Quick Solutions

#### Option 1: Use Mock Database (Recommended for Demo)
```bash
# This works without Docker/MongoDB
./start-dev-mock.sh
```

#### Option 2: Install MongoDB Locally
```bash
# On macOS with Homebrew
brew install mongodb/brew/mongodb-community
brew services start mongodb/brew/mongodb-community

# Update connection strings to use local MongoDB
mongodb://localhost:27017/flowbit
```

#### Option 3: Use MongoDB Atlas (Cloud)
1. Create free account at https://cloud.mongodb.com
2. Create a cluster
3. Get connection string
4. Update MONGO_URL in .env files

### Testing Database Connection

#### Test MongoDB Connection
```bash
# If using Docker
docker exec -it flowbit-mongo mongo -u admin -p password --authenticationDatabase admin

# If using local MongoDB
mongo
```

#### Test Application Connection
```bash
# Create a simple test script
cat > test-mongo.js << 'EOF'
const mongoose = require('mongoose');

async function testConnection() {
  try {
    await mongoose.connect('mongodb://admin:password@localhost:27017/flowbit?authSource=admin');
    console.log('✅ MongoDB connection successful');
    await mongoose.connection.close();
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error.message);
  }
}

testConnection();
EOF

node test-mongo.js
```

## n8n Issues

### Problem
n8n container not starting or not accessible

### Solution
```bash
# Check n8n status
docker ps | grep n8n

# If not running, start manually
docker run -d --name flowbit-n8n \
  -p 5678:5678 \
  -e N8N_BASIC_AUTH_ACTIVE=true \
  -e N8N_BASIC_AUTH_USER=admin \
  -e N8N_BASIC_AUTH_PASSWORD=password \
  -e N8N_PROTOCOL=http \
  -e N8N_HOST=0.0.0.0 \
  -e N8N_PORT=5678 \
  -e GENERIC_TIMEZONE=UTC \
  n8nio/n8n:latest

# Access n8n at http://localhost:5678
# Login: admin/password
```

## Port Conflicts

### Check Port Usage
```bash
# Check all ports used by Flowbit
for port in 3000 3001 3002 3003 5678 27017; do
  echo "Port $port:"
  lsof -i :$port
  echo "---"
done
```

### Kill Processes on Ports
```bash
# Kill all Flowbit processes
./stop-dev.sh

# Manually kill specific ports if needed
for port in 3000 3001 3002 3003 5678; do
  lsof -ti:$port | xargs kill -9 2>/dev/null || true
done
```

## Environment Variables

### Create .env Files
```bash
# Create .env for auth-service
cat > auth-service/.env << 'EOF'
MONGO_URL=mongodb://admin:password@localhost:27017/flowbit?authSource=admin
JWT_SECRET=your-super-secret-jwt-key-change-in-production
NODE_ENV=development
PORT=3001
EOF

# Create .env for api
cat > api/.env << 'EOF'
MONGO_URL=mongodb://admin:password@localhost:27017/flowbit?authSource=admin
JWT_SECRET=your-super-secret-jwt-key-change-in-production
N8N_WEBHOOK_URL=http://localhost:5678/webhook/ticket-created
WEBHOOK_SECRET=shared-secret-for-n8n-webhook
NODE_ENV=development
PORT=3002
EOF
```

## Common Error Messages

### "Cannot find module '../mock-db'"
```bash
# Make sure mock-db.js is in the root directory
ls -la mock-db.js

# If missing, recreate it
# (The file should be created automatically by the scripts)
```

### "EADDRINUSE: address already in use"
```bash
# Find and kill the process using the port
lsof -ti:3001 | xargs kill -9 2>/dev/null || true
```

### "Module not found" errors
```bash
# Install dependencies
npm install

# Install for each service
cd auth-service && npm install && cd ..
cd api && npm install && cd ..
cd react-shell && npm install && cd ..
cd support-tickets-app && npm install && cd ..
```

## Verification Steps

### 1. Check All Services are Running
```bash
# Check process status
ps aux | grep -E "(node|npm)" | grep -v grep

# Check port status
netstat -an | grep -E "(3000|3001|3002|3003|5678|27017)"
```

### 2. Test API Endpoints
```bash
# Test auth service
curl http://localhost:3001/health

# Test API service
curl http://localhost:3002/health

# Test login
curl -X POST http://localhost:3001/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@tenant-a.com","password":"password"}'
```

### 3. Check Logs
```bash
# View container logs
docker logs flowbit-mongo
docker logs flowbit-n8n

# View application logs in terminal where services are running
```

## Quick Start Options

### Option A: Full Docker Setup
```bash
# Start Docker Desktop first
./start-dev.sh
```

### Option B: Mock Database (No Docker needed)
```bash
# Works without Docker/MongoDB
./start-dev-mock.sh
```

### Option C: Hybrid Setup
```bash
# Use local MongoDB, Docker for n8n
brew install mongodb/brew/mongodb-community
brew services start mongodb/brew/mongodb-community

# Update connection strings to use local MongoDB
# Then run: ./start-dev.sh
```

## Getting Help

If you continue to have issues:

1. **Check the logs** in the terminal windows where services are running
2. **Verify prerequisites** (Node.js, Docker, npm versions)
3. **Use mock mode** for demonstration purposes
4. **Check environment variables** in .env files
5. **Test each service individually** using curl commands above

Remember: The mock database mode (`./start-dev-mock.sh`) is perfect for demonstrations and doesn't require Docker or MongoDB to be running.
