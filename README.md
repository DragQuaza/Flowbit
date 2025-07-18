# Flowbit Multi-Tenant System

A comprehensive multi-tenant platform with n8n workflow integration, demonstrating tenant-aware authentication, RBAC, dynamic micro-frontend loading, and secure API design.

## 🎯 Core Features

### ✅ Requirements Met

- **R1: Auth & RBAC**: JWT-based authentication with bcrypt password hashing, role-based access control
- **R2: Tenant Data Isolation**: Every MongoDB collection includes `customerId` with middleware enforcement
- **R3: Use-Case Registry**: Hard-coded tenant-screen mappings in `registry.json`
- **R4: Dynamic Navigation**: React shell with Webpack Module Federation for micro-frontend loading
- **R5: Workflow Integration**: n8n workflow triggers with secure webhook callbacks
- **R6: Containerized Development**: Complete Docker Compose setup with self-configuration

### 🚀 Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React Shell   │    │   Auth Service  │    │   API Service   │
│   (Port 3000)   │    │   (Port 3001)   │    │   (Port 3002)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
         │ Support Tickets │    │   MongoDB       │    │      n8n        │
         │   (Port 3003)   │    │   (Port 27017)  │    │   (Port 5678)   │
         └─────────────────┘    └─────────────────┘    └─────────────────┘
                                         │
                                ┌─────────────────┐
                                │     ngrok       │
                                │   (Port 4040)   │
                                └─────────────────┘
```

## 🏗️ System Components

### 1. **Auth Service** (`auth-service/`)
- JWT token generation and verification
- Bcrypt password hashing
- User registration and login
- Role-based access control (Admin/User)
- Rate limiting for security

### 2. **API Service** (`api/`)
- Main business logic API
- Tenant-aware data filtering
- n8n workflow triggers
- WebSocket support for real-time updates
- Secure webhook endpoints

### 3. **React Shell** (`react-shell/`)
- Main application shell
- Dynamic micro-frontend loading
- Tenant-specific navigation
- Authentication state management
- Webpack Module Federation host

### 4. **Support Tickets App** (`support-tickets-app/`)
- Micro-frontend for ticket management
- Real-time updates via WebSocket
- Tenant-isolated ticket creation
- Module Federation remote entry

### 5. **n8n Workflow Engine**
- Processes ticket creation events
- Calls back to update ticket status
- Demonstrates workflow round-trip

## 🛠️ Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js & npm
- (Optional) ngrok account for webhook testing

### Installation

1. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd flowbit-system
   chmod +x setup.sh
   ./setup.sh
   ```

2. **Start Services**
   ```bash
   docker-compose up -d
   ```

3. **Create Demo Users**
   ```bash
   # Wait 30 seconds for services to start
   node create-demo-users.js
   ```

4. **Access Application**
   - Main App: http://localhost:3000
   - n8n Interface: http://localhost:5678 (admin/password)
   - ngrok Dashboard: http://localhost:4040

## 👥 Demo Accounts

| Email | Password | Tenant | Role |
|-------|----------|---------|------|
| admin@tenant-a.com | password | tenant-a | Admin |
| user@tenant-a.com | password | tenant-a | User |
| admin@tenant-b.com | password | tenant-b | Admin |
| user@tenant-b.com | password | tenant-b | User |

## 🔐 Security Features

### Authentication & Authorization
- JWT tokens with 24-hour expiration
- Bcrypt password hashing (10 rounds)
- Role-based middleware for admin routes
- Rate limiting on auth endpoints

### Tenant Data Isolation
- Every MongoDB collection includes `customerId`
- API middleware filters data by tenant
- JWT tokens carry tenant context
- Comprehensive test coverage for isolation

### API Security
- CORS and Helmet middleware
- Input validation and sanitization
- Secure webhook verification
- Environment-based configuration

## 🧪 Testing

### Run Unit Tests
```bash
npm test
```

### Tenant Isolation Test
The system includes a comprehensive Jest test (`tests/tenant-isolation.test.js`) that verifies:
- Admins from Tenant A cannot access Tenant B data
- All collections enforce `customerId` field
- JWT tokens contain proper tenant information
- API middleware correctly filters cross-tenant requests

### Manual Testing Flow

1. **Login as Tenant A Admin**
   - Access: admin@tenant-a.com / password
   - Verify: Can see Admin Panel in sidebar

2. **Create Support Ticket**
   - Navigate to Support Tickets
   - Create ticket (triggers n8n workflow)
   - Verify: Ticket appears in real-time

3. **Test Tenant Isolation**
   - Login as Tenant B user
   - Verify: Cannot see Tenant A tickets
   - Create Tenant B ticket
   - Verify: Only Tenant B tickets visible

## 📊 n8n Workflow Setup

### Automatic Configuration
The n8n container starts with basic auth enabled. Create a simple workflow:

1. **Webhook Trigger**
   - URL: `http://localhost:5678/webhook/ticket-created`
   - Method: POST
   - Authentication: Bearer token

2. **HTTP Request Node**
   - URL: `http://api:3002/webhook/ticket-done`
   - Method: POST
   - Headers: `Authorization: Bearer shared-secret-for-n8n-webhook`
   - Body: `{"ticketId": "{{$json.ticketId}}"}`

### Workflow Flow
1. User creates ticket in React app
2. API calls n8n webhook with ticket data
3. n8n processes the ticket (can add delays, external calls, etc.)
4. n8n calls back to API webhook
5. API updates ticket status to "Done"
6. Real-time update sent to UI via WebSocket

## 📁 Project Structure

```
flowbit-system/
├── auth-service/          # JWT authentication service
├── api/                   # Main API with business logic
├── react-shell/           # Application shell (Module Federation host)
├── support-tickets-app/   # Micro-frontend for tickets
├── tests/                 # Unit and integration tests
├── docker-compose.yml     # Full system orchestration
├── registry.json          # Tenant-screen mappings
├── setup.sh              # Automated setup script
└── README.md             # This file
```

## 🔄 Workflow Round-Trip Demo

1. **User Action**: Create support ticket
2. **API**: Saves ticket to MongoDB
3. **Trigger**: POST to n8n webhook
4. **n8n**: Processes ticket (simulated delay)
5. **Callback**: n8n calls API webhook
6. **Update**: API updates ticket status
7. **Real-time**: WebSocket pushes update to UI

## 🐛 Troubleshooting

### Common Issues

1. **Docker Port Conflicts**
   ```bash
   # Check if ports are in use
   lsof -i :3000 :3001 :3002 :3003 :5678
   ```

2. **MongoDB Connection Issues**
   ```bash
   # Check MongoDB logs
   docker-compose logs mongodb
   ```

3. **Module Federation Loading Issues**
   ```bash
   # Verify support-tickets-app is running
   curl http://localhost:3003/assets/remoteEntry.js
   ```

### Development Mode

For development, run services individually:

```bash
# Terminal 1: MongoDB
docker-compose up mongodb

# Terminal 2: Auth Service
cd auth-service && npm run dev

# Terminal 3: API Service  
cd api && npm run dev

# Terminal 4: React Shell
cd react-shell && npm run dev

# Terminal 5: Support Tickets
cd support-tickets-app && npm run dev

# Terminal 6: n8n
docker-compose up n8n
```

## 📈 Performance Considerations

- **Database Indexing**: Add indexes on `customerId` fields
- **Caching**: Implement Redis for JWT blacklisting
- **Load Balancing**: Use nginx for production deployment
- **Monitoring**: Add application metrics and logging

## 🔮 Future Enhancements

### Bonus Features Implemented
- ✅ Real-time updates via WebSocket
- ✅ Comprehensive test coverage
- ✅ Docker containerization
- ✅ Development setup automation

### Potential Additions
- [ ] Audit logging system
- [ ] Cypress end-to-end tests
- [ ] GitHub Actions CI/CD
- [ ] Admin dashboard micro-frontend
- [ ] Multi-environment configuration

## 📄 License

This project is for demonstration purposes as part of a technical assessment.

## 🤝 Contributing

This is a demo project. For production use, consider:
- Adding proper error handling
- Implementing comprehensive logging
- Adding monitoring and alerting
- Securing sensitive configuration
- Adding data backup strategies

---

**Built with ❤️ using React, Node.js, MongoDB, n8n, and Docker**
