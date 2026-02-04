const mongoose = require('mongoose');

const connectDB = async () => {
  const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/countpluse';

  try {
    const connection = await mongoose.connect(mongoUri, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 3000,
      socketTimeoutMS: 5000,
      connectTimeoutMS: 3000,
    });

    console.log(`✓ MongoDB Connected: ${connection.connection.host}`);
    return connection;
  } catch (error) {
    console.error('✗ MongoDB Error:', error.message);
    console.error('  Server will still run, but database operations will fail');
    throw error;
  }
};

module.exports = connectDB;
