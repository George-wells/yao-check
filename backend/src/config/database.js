const { Pool } = require('pg');
const config = require('./index');
const logger = require('../utils/logger');

const pool = new Pool({
  host: config.db.host,
  port: config.db.port,
  database: config.db.database,
  user: config.db.user,
  password: config.db.password,
  min: config.db.pool.min,
  max: config.db.pool.max,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('error', (err) => {
  logger.error('Unexpected database pool error', { error: err.message });
});

pool.on('connect', () => {
  logger.debug('New database connection established');
});

/**
 * Execute a single query
 */
async function query(text, params) {
  const start = Date.now();
  const result = await pool.query(text, params);
  const duration = Date.now() - start;
  logger.debug('Executed query', { text: text.substring(0, 100), duration, rows: result.rowCount });
  return result;
}

/**
 * Get a client from the pool for transactions
 */
async function getClient() {
  const client = await pool.connect();
  return client;
}

/**
 * Test database connection
 */
async function testConnection() {
  try {
    const result = await query('SELECT NOW()');
    logger.info('Database connection successful', { serverTime: result.rows[0].now });
    return true;
  } catch (error) {
    logger.error('Database connection failed', { error: error.message });
    return false;
  }
}

module.exports = {
  pool,
  query,
  getClient,
  testConnection,
};
