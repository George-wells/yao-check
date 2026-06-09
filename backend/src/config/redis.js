const redis = require('redis');
const config = require('./index');
const logger = require('../utils/logger');

let client = null;

/**
 * Initialize Redis connection
 */
async function initRedis() {
  try {
    client = redis.createClient({
      socket: {
        host: config.redis.host,
        port: config.redis.port,
      },
      password: config.redis.password || undefined,
      database: config.redis.db,
    });

    client.on('error', (err) => {
      logger.error('Redis client error', { error: err.message });
    });

    client.on('connect', () => {
      logger.info('Redis connected successfully');
    });

    await client.connect();
    return client;
  } catch (error) {
    logger.warn('Redis connection failed, caching disabled', { error: error.message });
    return null;
  }
}

/**
 * Get Redis client
 */
function getClient() {
  return client;
}

/**
 * Set cache value
 */
async function setCache(key, value, ttlSeconds = 3600) {
  if (!client) return null;
  try {
    const serialized = JSON.stringify(value);
    await client.setEx(key, ttlSeconds, serialized);
    return true;
  } catch (error) {
    logger.warn('Redis set cache failed', { key, error: error.message });
    return false;
  }
}

/**
 * Get cache value
 */
async function getCache(key) {
  if (!client) return null;
  try {
    const value = await client.get(key);
    return value ? JSON.parse(value) : null;
  } catch (error) {
    logger.warn('Redis get cache failed', { key, error: error.message });
    return null;
  }
}

/**
 * Delete cache key
 */
async function deleteCache(key) {
  if (!client) return;
  try {
    await client.del(key);
  } catch (error) {
    logger.warn('Redis delete cache failed', { key, error: error.message });
  }
}

/**
 * Invalidate cache by pattern
 */
async function invalidatePattern(pattern) {
  if (!client) return;
  try {
    const keys = await client.keys(pattern);
    if (keys.length > 0) {
      await client.del(keys);
      logger.debug('Cache invalidated', { pattern, count: keys.length });
    }
  } catch (error) {
    logger.warn('Redis invalidate pattern failed', { pattern, error: error.message });
  }
}

module.exports = {
  initRedis,
  getClient,
  setCache,
  getCache,
  deleteCache,
  invalidatePattern,
};
