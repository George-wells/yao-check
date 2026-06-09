const express = require('express');
const router = express.Router();
const planService = require('../services/planService');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../utils/validators');
const ApiResponse = require('../utils/response');

/**
 * GET /api/plans
 * Get user's medication plans
 */
router.get('/', authenticate, async (req, res, next) => {
  try {
    const includeInactive = req.query.includeInactive === 'true';
    const plans = await planService.getUserPlans(req.user.id, includeInactive);
    return ApiResponse.success(res, plans);
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/plans/today
 * Get today's medication schedule
 */
router.get('/today', authenticate, async (req, res, next) => {
  try {
    const schedule = await planService.getTodaySchedule(req.user.id);
    return ApiResponse.success(res, schedule);
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/plans
 * Create medication plan
 */
router.post('/', authenticate, validate('createPlan'), async (req, res, next) => {
  try {
    const plan = await planService.createPlan(req.user.id, req.validatedBody);
    return ApiResponse.created(res, plan, '用药计划已创建');
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/plans/:id
 * Get plan details
 */
router.get('/:id', authenticate, async (req, res, next) => {
  try {
    const plan = await planService.getPlanById(req.params.id, req.user.id);
    return ApiResponse.success(res, plan);
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/plans/:id
 * Update medication plan
 */
router.put('/:id', authenticate, validate('updatePlan'), async (req, res, next) => {
  try {
    const plan = await planService.updatePlan(req.params.id, req.user.id, req.validatedBody);
    return ApiResponse.success(res, plan, '用药计划已更新');
  } catch (error) {
    next(error);
  }
});

/**
 * DELETE /api/plans/:id
 * Delete medication plan
 */
router.delete('/:id', authenticate, async (req, res, next) => {
  try {
    await planService.deletePlan(req.params.id, req.user.id);
    return ApiResponse.success(res, null, '用药计划已删除');
  } catch (error) {
    next(error);
  }
});

module.exports = router;
