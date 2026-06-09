const rateLimit = require('express-rate-limit');
const ApiResponse = require('../utils/response');

/**
 * General API rate limiter
 */
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    return ApiResponse.tooManyRequests(res);
  },
});

/**
 * Strict rate limiter for auth endpoints
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    return ApiResponse.tooManyRequests(res, '验证码请求过于频繁，请稍后再试');
  },
});

/**
 * SMS verification code rate limiter
 */
const smsLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    return ApiResponse.tooManyRequests(res, '短信验证码发送过于频繁，请1小时后再试');
  },
});

module.exports = {
  generalLimiter,
  authLimiter,
  smsLimiter,
};
