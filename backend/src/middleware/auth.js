const jwt = require('jsonwebtoken');
const config = require('../config');
const ApiResponse = require('../utils/response');
const { pool } = require('../config/database');
const logger = require('../utils/logger');

/**
 * Verify JWT access token
 */
function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return ApiResponse.unauthorized(res, '缺少认证令牌');
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, config.jwt.secret);
    req.user = {
      id: decoded.sub,
      phone: decoded.phone,
    };
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return ApiResponse.unauthorized(res, '认证令牌已过期，请刷新令牌');
    }
    logger.warn('JWT verification failed', { error: error.message });
    return ApiResponse.unauthorized(res, '无效的认证令牌');
  }
}

/**
 * Optional authentication - sets req.user if token present, but doesn't block
 */
function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    req.user = null;
    return next();
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, config.jwt.secret);
    req.user = {
      id: decoded.sub,
      phone: decoded.phone,
    };
  } catch (error) {
    req.user = null;
  }
  next();
}

/**
 * Verify user is the owner of the resource or a guardian
 */
function requireOwnership(paramName = 'userId') {
  return async (req, res, next) => {
    const targetUserId = req.params[paramName] || req.body[paramName];

    if (!targetUserId) {
      return next();
    }

    // User is accessing their own resource
    if (req.user.id === targetUserId) {
      return next();
    }

    // Check if user is an active guardian of the target user
    try {
      const result = await pool.query(
        `SELECT id FROM guardians 
         WHERE guardian_id = $1 AND patient_id = $2 AND status = 'active'`,
        [req.user.id, targetUserId]
      );

      if (result.rows.length > 0) {
        return next();
      }
    } catch (error) {
      logger.error('Guardian check failed', { error: error.message });
    }

    return ApiResponse.forbidden(res, '无权访问该资源');
  };
}

module.exports = {
  authenticate,
  optionalAuth,
  requireOwnership,
};
