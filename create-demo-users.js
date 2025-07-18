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
