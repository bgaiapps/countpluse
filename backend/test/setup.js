const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongoServer;

jest.setTimeout(30000);

beforeAll(async () => {
  process.env.NODE_ENV = 'test';
  process.env.JWT_SECRET = 'test_secret';
  process.env.JWT_EXPIRE = '1d';
  process.env.FRONTEND_URL = 'http://localhost:3000';

  let explicitUri = process.env.MONGODB_URI_TEST || process.env.MONGODB_URI;

  const connectWithUri = async (uri) => {
    await mongoose.connect(uri, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 5000,
      connectTimeoutMS: 5000,
    });
  };

  if (explicitUri) {
    try {
      await connectWithUri(explicitUri);
      return;
    } catch (error) {
      console.warn(
        `MongoDB connection failed for tests at ${explicitUri}. Falling back to mongodb-memory-server.`,
      );
    }
  }

  mongoServer = await MongoMemoryServer.create();
  explicitUri = mongoServer.getUri();
  await connectWithUri(explicitUri);
});

afterEach(async () => {
  if (mongoose.connection.readyState === 1 && mongoose.connection.db) {
    const collections = await mongoose.connection.db.collections();
    for (const collection of collections) {
      await collection.deleteMany({});
    }
  }
});

afterAll(async () => {
  await mongoose.disconnect();
  if (mongoServer) {
    await mongoServer.stop();
  }
});
