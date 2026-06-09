const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const config = require('./config');
const logger = require('./utils/logger');
const { testConnection } = require('./config/database');
const { initRedis } = require('./config/redis');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');
const { generalLimiter } = require('./middleware/rateLimiter');
const routes = require('./routes');

const app = express();

// ============================================================
// Middleware
// ============================================================

// Security headers
app.use(helmet());

// CORS
app.use(cors({
  origin: config.cors.origin,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Rate limiting
app.use(generalLimiter);

// Request logging
app.use(morgan('combined', {
  stream: { write: (message) => logger.info(message.trim()) },
}));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ============================================================
// Routes
// ============================================================

app.use('/api', routes);

// ============================================================
// Error handling
// ============================================================

app.use(notFoundHandler);
app.use(errorHandler);

// ============================================================
// Server startup
// ============================================================

async function startServer() {
  // Test database connection
  const dbConnected = await testConnection();
  if (!dbConnected) {
    logger.warn('Starting server without database connection');
  }

  // Initialize Redis (non-blocking)
  initRedis().then((client) => {
    if (client) {
      logger.info('Redis cache initialized');
    } else {
      logger.warn('Redis not available, caching disabled');
    }
  });

  app.listen(config.port, () => {
    logger.info(`Smart Medication API server started`, {
      port: config.port,
      env: config.env,
      dbConnected,
    });
    console.log(`
╔══════════════════════════════════════════════╗
║       智能用药App - 后端API服务              ║
║       Port: ${config.port}                         ║
║       Env: ${config.env.padEnd(25)}║
║       DB: ${dbConnected ? '✅ Connected' : '❌ Disconnected'.padEnd(22)}║
║       Health: http://localhost:${config.port}/api/health  ║
╚══════════════════════════════════════════════╝
    `);
  });
}

startServer().catch((err) => {
  logger.error('Failed to start server', { error: err.message });
  process.exit(1);
});

module.exports = app;
