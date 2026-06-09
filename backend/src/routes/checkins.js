const express = require('express');
const router = express.Router();
const checkinService = require('../services/checkinService');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../utils/validators');
const ApiResponse = require('../utils/response');

/**
 * POST /api/checkins
 * Create a check-in record
 */
router.post('/', authenticate, validate('createCheckin'), async (req, res, next) => {
  try {
    const log = await checkinService.createCheckin(req.user.id, req.validatedBody);
    return ApiResponse.created(res, log, '打卡成功');
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/checkins/:id/undo
 * Undo a check-in (within 5 minutes)
 */
router.post('/:id/undo', authenticate, async (req, res, next) => {
  try {
    const result = await checkinService.undoCheckin(req.params.id, req.user.id);
    return ApiResponse.success(res, result);
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/checkins
 * Get check-in records
 */
router.get('/', authenticate, async (req, res, next) => {
  try {
    const startDate = req.query.startDate || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const endDate = req.query.endDate || new Date().toISOString().split('T')[0];
    const page = parseInt(req.query.page, 10) || 1;
    const pageSize = parseInt(req.query.pageSize, 10) || 50;

    const result = await checkinService.getCheckins(req.user.id, startDate, endDate, page, pageSize);
    return ApiResponse.paginated(res, result.items, result.total, page, pageSize);
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/checkins/calendar
 * Get calendar view data
 */
router.get('/calendar', authenticate, async (req, res, next) => {
  try {
    const year = parseInt(req.query.year, 10) || new Date().getFullYear();
    const month = parseInt(req.query.month, 10) || (new Date().getMonth() + 1);
    const data = await checkinService.getCalendarView(req.user.id, year, month);
    return ApiResponse.success(res, data);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
