const express = require('express');
const router = express.Router();
const authService = require('../services/authService');
const { validate } = require('../utils/validators');
const { authenticate } = require('../middleware/auth');
const { authLimiter, smsLimiter } = require('../middleware/rateLimiter');
const ApiResponse = require('../utils/response');

/**
 * POST /api/auth/send-code
 * Send SMS verification code
 */
router.post('/send-code', smsLimiter, validate('sendVerificationCode'), async (req, res, next) => {
  try {
    const { phone, purpose } = req.validatedBody;
    await authService.sendVerificationCode(phone, purpose);
    return ApiResponse.success(res, null, '验证码已发送');
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/auth/login
 * Login with phone + verification code
 */
router.post('/login', authLimiter, validate('login'), async (req, res, next) => {
  try {
    const { phone, code } = req.validatedBody;
    const result = await authService.loginWithCode(phone, code);
    return ApiResponse.success(res, result, '登录成功');
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/auth/refresh
 * Refresh access token
 */
router.post('/refresh', validate('refreshToken'), async (req, res, next) => {
  try {
    const { refreshToken } = req.validatedBody;
    const tokens = await authService.refreshAccessToken(refreshToken);
    return ApiResponse.success(res, tokens, '令牌刷新成功');
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/auth/logout
 * Logout - revoke all refresh tokens
 */
router.post('/logout', authenticate, async (req, res, next) => {
  try {
    await authService.revokeAllTokens(req.user.id);
    return ApiResponse.success(res, null, '已退出登录');
  } catch (error) {
    next(error);
  }
});

module.exports = router;
