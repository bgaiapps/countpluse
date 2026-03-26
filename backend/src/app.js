const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/authRoutes');
const countRoutes = require('./routes/countRoutes');
const { getDatabaseStatus } = require('./config/database');
const env = require('./config/env');

const app = express();

// Middleware
app.disable('x-powered-by');
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('Referrer-Policy', 'no-referrer');
  next();
});
app.use(
  cors({
    origin: (origin, callback) => {
      if (!env.isProduction) return callback(null, true);
      if (!origin) return callback(null, true);
      if (env.corsOrigins.length > 0 && env.corsOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error('CORS origin not allowed'));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-User-Id'],
  })
);
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/counts', countRoutes);

// Health check (no DB required)
app.get('/health', (req, res) => {
  const dbStatus = getDatabaseStatus();
  const healthy = dbStatus === 'connected' || !env.isProduction;
  res.status(healthy ? 200 : 503).json({
    status: healthy ? 'OK' : 'DEGRADED',
    environment: env.nodeEnv,
    database: dbStatus,
    uptimeSeconds: Math.round(process.uptime()),
    message: 'Japlo backend is running',
  });
});

app.get('/ready', (req, res) => {
  const dbStatus = getDatabaseStatus();
  if (dbStatus !== 'connected') {
    return res.status(503).json({
      status: 'NOT_READY',
      database: dbStatus,
    });
  }
  return res.status(200).json({
    status: 'READY',
    database: dbStatus,
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
  });
});

// Error handler
app.use((err, req, res, _next) => {
  console.error('Error:', err);
  const statusCode = err.message === 'CORS origin not allowed' ? 403 : 500;
  res.status(statusCode).json({
    success: false,
    message: statusCode === 403 ? 'CORS origin not allowed' : 'Internal server error',
    error: !env.isProduction ? err.message : undefined,
  });
});

module.exports = app;
