require('dotenv').config();
const { connectDB } = require('./config/database');
const env = require('./config/env');
const app = require('./app');

let server;

const startServer = async () => {
  if (env.isProduction) {
    await connectDB();
  } else {
    connectDB().catch(err => {
      console.error('DB connection error:', err.message);
    });
  }

  server = app.listen(env.port, () => {
    console.log(`Server running on port ${env.port}`);
    console.log(`Environment: ${env.nodeEnv}`);
  });

  return server;
};

const shutdown = (signal) => {
  console.log(`${signal} received, shutting down gracefully`);
  if (!server) {
    process.exit(0);
  }
  server.close(() => {
    process.exit(0);
  });
  setTimeout(() => {
    console.error('Forced shutdown after timeout');
    process.exit(1);
  }, 10000).unref();
};

if (require.main === module) {
  startServer().catch(error => {
    console.error('Startup failure:', error.message);
    process.exit(1);
  });
  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

module.exports = { app, startServer };
