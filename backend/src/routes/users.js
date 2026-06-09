const express = require('express');
const router = express.Router();
const userService = require('../services/userService');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../utils/validators');
const ApiResponse = require('../utils/response');

/**
 * GET /api/users/profile
 * Get current user profile
 */
router.get('/profile', authenticate, async (req, res, next) => {
  try {
    const user = await userService.getUserProfile(req.user.id);
    return ApiResponse.success(res, user);
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/users/profile
 * Update user profile
 */
router.put('/profile', authenticate, validate('updateProfile'), async (req, res, next) => {
  try {
    const user = await userService.updateProfile(req.user.id, req.validatedBody);
    return ApiResponse.success(res, user, '个人信息已更新');
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/users/elderly-preferences
 * Update elderly mode preferences
 */
router.put('/elderly-preferences', authenticate, validate('updateElderlyPreferences'), async (req, res, next) => {
  try {
    const preferences = await userService.updateElderlyPreferences(req.user.id, req.validatedBody);
    return ApiResponse.success(res, preferences, '适老化偏好已更新');
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/users/stats
 * Get medication statistics
 */
router.get('/stats', authenticate, async (req, res, next) => {
  try {
    const days = parseInt(req.query.days, 10) || 30;
    const stats = await userService.getMedicationStats(req.user.id, days);
    return ApiResponse.success(res, stats);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
