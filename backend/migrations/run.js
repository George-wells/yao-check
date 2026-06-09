/**
 * Database migration runner
 * Usage: node migrations/run.js
 */

const fs = require('fs');
const path = require('path');
const { pool } = require('../src/config/database');
const logger = require('../src/utils/logger');

async function runMigrations() {
  logger.info('Starting database migration...');

  try {
    // Read schema file
    const schemaPath = path.join(__dirname, '..', 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf-8');

    logger.info(`Schema file loaded (${schema.length} bytes)`);

    // Execute schema
    const client = await pool.connect();
    try {
      await client.query(schema);
      logger.info('Database schema applied successfully');
    } finally {
      client.release();
    }
  } catch (error) {
    logger.error('Migration failed', { error: error.message });
    process.exit(1);
  } finally {
    await pool.end();
  }
}

runMigrations();
