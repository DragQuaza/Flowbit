#!/bin/bash

echo "🚀 Setting up Flowbit Multi-Tenant System..."

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command_exists docker; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command_exists docker-compose; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

if ! command_exists npm; then
    echo "❌ npm is not installed. Please install Node.js and npm first."
    exit 1
fi

echo "✅ Prerequisites check passed!"

# Install dependencies for all services
echo "📦 Installing dependencies..."

# Auth Service
echo "Installing auth service dependencies..."
cd auth-service
npm install
cd ..

# API Service  
echo "Installing API service dependencies..."
cd api
npm install
cd ..

# React Shell
echo "Installing React shell dependencies..."
cd react-shell
npm install
cd ..

# Support Tickets App
echo "Installing support tickets app dependencies..."
cd support-tickets-app
npm install
cd ..

# Test dependencies
echo "Installing test dependencies..."
npm init -y
npm install --save-dev jest supertest mongoose bcrypt jsonwebtoken

echo "✅ Dependencies installed!"

# Create demo users script
echo "📝 Creating demo users setup script..."

cat > create-demo-users.js << 'EOF'
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

async function createDemoUsers() {
  try {
    await mongoose.connect('mongodb://admin:password@localhost:27017/flowbit?authSource=admin');
    
    const userSchema = new mongoose.Schema({
      email: { type: String, required: true, unique: true },
      password: { type: String, required: true },
      customerId: { type: String, required: true },
      role: { type: String, enum: ['Admin', 'User'], default: 'User' }
    });

    const User = mongoose.model('User', userSchema);

    // Create demo users
    const users = [
      { email: 'admin@tenant-a.com', password: 'password', customerId: 'tenant-a', role: 'Admin' },
      { email: 'user@tenant-a.com', password: 'password', customerId: 'tenant-a', role: 'User' },
      { email: 'admin@tenant-b.com', password: 'password', customerId: 'tenant-b', role: 'Admin' },
      { email: 'user@tenant-b.com', password: 'password', customerId: 'tenant-b', role: 'User' }
    ];

    for (const userData of users) {
      const existingUser = await User.findOne({ email: userData.email });
      if (!existingUser) {
        const hashedPassword = await bcrypt.hash(userData.password, 10);
        await User.create({
          ...userData,
          password: hashedPassword
        });
        console.log(`Created user: ${userData.email}`);
      } else {
        console.log(`User already exists: ${userData.email}`);
      }
    }

    console.log('Demo users created successfully!');
  } catch (error) {
    console.error('Error creating demo users:', error);
  } finally {
    await mongoose.connection.close();
  }
}

createDemoUsers();
EOF

echo "✅ Setup completed!"

echo "🎯 Next steps:"
echo "1. Run: docker-compose up -d"
echo "2. Wait for services to start (about 30 seconds)"
echo "3. Run: node create-demo-users.js"
echo "4. Access the application at http://localhost:3000"
echo ""
echo "📖 Demo accounts:"
echo "- Admin Tenant A: admin@tenant-a.com / password"
echo "- User Tenant A: user@tenant-a.com / password"
echo "- Admin Tenant B: admin@tenant-b.com / password"
echo "- User Tenant B: user@tenant-b.com / password"
echo ""
echo "🧪 To run tests:"
echo "npm test"
echo ""
echo "💡 Access n8n at http://localhost:5678 (admin/password)"
echo "💡 Access ngrok dashboard at http://localhost:4040"
