const fs = require('fs');
const path = require('path');

class MockDatabase {
  constructor() {
    this.dbPath = path.join(__dirname, 'mock-db.json');
    this.initializeData();
  }

  initializeData() {
    if (!fs.existsSync(this.dbPath)) {
      const initialData = {
        users: [
          {
            _id: '1',
            email: 'admin@tenant-a.com',
            password: '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password: 'password'
            customerId: 'tenant-a',
            role: 'Admin',
            createdAt: new Date(),
            lastLogin: null
          },
          {
            _id: '2',
            email: 'admin@tenant-b.com',
            password: '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password: 'password'
            customerId: 'tenant-b',
            role: 'Admin',
            createdAt: new Date(),
            lastLogin: null
          }
        ],
        tickets: []
      };
      fs.writeFileSync(this.dbPath, JSON.stringify(initialData, null, 2));
    }
  }

  readData() {
    try {
      const data = fs.readFileSync(this.dbPath, 'utf8');
      return JSON.parse(data);
    } catch (error) {
      console.error('Error reading mock database:', error);
      return { users: [], tickets: [] };
    }
  }

  writeData(data) {
    try {
      fs.writeFileSync(this.dbPath, JSON.stringify(data, null, 2));
    } catch (error) {
      console.error('Error writing mock database:', error);
    }
  }

  // User methods
  async findUser(query) {
    const data = this.readData();
    return data.users.find(user => {
      if (query.email) return user.email === query.email;
      if (query._id) return user._id === query._id;
      return false;
    });
  }

  async createUser(userData) {
    const data = this.readData();
    const newUser = {
      _id: Date.now().toString(),
      ...userData,
      createdAt: new Date(),
      lastLogin: null
    };
    data.users.push(newUser);
    this.writeData(data);
    return newUser;
  }

  async updateUser(id, updates) {
    const data = this.readData();
    const userIndex = data.users.findIndex(user => user._id === id);
    if (userIndex !== -1) {
      data.users[userIndex] = { ...data.users[userIndex], ...updates };
      this.writeData(data);
      return data.users[userIndex];
    }
    return null;
  }

  // Ticket methods
  async findTickets(query) {
    const data = this.readData();
    return data.tickets.filter(ticket => {
      if (query.customerId) return ticket.customerId === query.customerId;
      return true;
    }).sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  }

  async createTicket(ticketData) {
    const data = this.readData();
    const newTicket = {
      _id: Date.now().toString(),
      ...ticketData,
      status: 'Open',
      createdAt: new Date(),
      updatedAt: null
    };
    data.tickets.push(newTicket);
    this.writeData(data);
    return newTicket;
  }

  async updateTicket(id, updates) {
    const data = this.readData();
    const ticketIndex = data.tickets.findIndex(ticket => ticket._id === id);
    if (ticketIndex !== -1) {
      data.tickets[ticketIndex] = { 
        ...data.tickets[ticketIndex], 
        ...updates, 
        updatedAt: new Date() 
      };
      this.writeData(data);
      return data.tickets[ticketIndex];
    }
    return null;
  }

  async findTicketById(id) {
    const data = this.readData();
    return data.tickets.find(ticket => ticket._id === id);
  }
}

module.exports = MockDatabase;
