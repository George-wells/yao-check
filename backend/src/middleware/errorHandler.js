const logger = require('../utils/logger');
const ApiResponse = require('../utils/response');
const { AppError } = require('../utils/errors');

/**
 * Global error handler middleware
 */
function errorHandler(err, req, res, _next) {
  // Log error
  logger.error('Unhandled error', {
    error: err.message,
    stack: err.stack,
    method: req.method,
    url: req.originalUrl,
    ip: req.ip,
  });

  // Handle known operational errors
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      success: false,
      message: err.message,
      errorCode: err.errorCode,
      errors: err.errors || undefined,
      timestamp: new Date().toISOString(),
    });
  }

  // Handle Joi validation errors
  if (err.isJoi) {
    return res.status(400).json({
      success: false,
      message: '请求参数验证失败',
      errors: err.details.map((d) => ({
        field: d.path.join('.'),
        message: d.message,
      })),
      timestamp: new Date().toISOString(),
    });
  }

  // Handle PostgreSQL errors
  if (err.code && err.code.startsWith('23')) {
    // Unique violation, foreign key violation, etc.
    const messages = {
      '23505': '数据已存在',
      '23503': '关联数据不存在',
      '23502': '缺少必填字段',
    };
    return res.status(409).json({
      success: false,
      message: messages[err.code] || '数据库约束错误',
      timestamp: new Date().toISOString(),
    });
  }

  // Handle JSON parse errors
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({
      success: false,
      message: '请求体JSON格式错误',
      timestamp: new Date().toISOString(),
    });
  }

  // Default 500 error
  return res.status(500).json({
    success: false,
    message: process.env.NODE_ENV === 'production'
      ? '服务器内部错误'
      : err.message,
    timestamp: new Date().toISOString(),
  });
}

/**
 * 404 handler for unknown routes
 */
function notFoundHandler(req, res) {
  return ApiResponse.notFound(res, `接口不存在: ${req.method} ${req.originalUrl}`);
}

module.exports = {
  errorHandler,
  notFoundHandler,
};
