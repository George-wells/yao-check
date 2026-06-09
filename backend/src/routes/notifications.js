const express = require('express');
const router = express.Router();
const notificationService = require('../services/notificationService');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../utils/validators');
const ApiResponse = require('../utils/response');

/**
 * GET /api/notifications
 * Get user's notifications
 */
router.get('/', authenticate, async (req, res, next) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const pageSize = parseInt(req.query.pageSize, 10) || 50;
    const unreadOnly = req.query.unreadOnly === 'true';
    const result = await notificationService.getUserNotifications(req.user.id, page, pageSize, unreadOnly);
    return ApiResponse.paginated(res, result.items, result.total, page, pageSize);
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/notifications/unread-count
 * Get unread notification count
 */
router.get('/unread-count', authenticate, async (req, res, next) => {
  try {
    const count = await notificationService.getUnreadCount(req.user.id);
    return ApiResponse.success(res, { count });
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/notifications/:id/read
 * Mark notification as read
 */
router.put('/:id/read', authenticate, async (req, res, next) => {
  try {
    await notificationService.markAsRead(req.params.id, req.user.id);
    return ApiResponse.success(res, null, '已标记为已读');
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/notifications/read-all
 * Mark all notifications as read
 */
router.put('/read-all', authenticate, async (req, res, next) => {
  try {
    await notificationService.markAllAsRead(req.user.id);
    return ApiResponse.success(res, null, '全部标记为已读');
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/notifications/device
 * Register device token for push notifications
 */
router.post('/device', authenticate, validate('registerDevice'), async (req, res, next) => {
  try {
    const { deviceToken, platform, deviceName } = req.validatedBody;

    // Upsert device token
    const { query } = require('../config/database');
    await query(
      `INSERT INTO device_tokens (user_id, device_token, platform, device_name)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (device_token) 
       DO UPDATE SET user_id = $1, is_active = TRUE, last_used_at = NOW(), device_name = $4`,
      [req.user.id, deviceToken, platform, deviceName]
    );

    return ApiResponse.success(res, null, '设备已注册');
  } catch (error) {
    next(error);
  }
});

module.exports = router;
