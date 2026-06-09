const express = require('express');
const router = express.Router();
const prescriptionService = require('../services/prescriptionService');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../utils/validators');
const ApiResponse = require('../utils/response');

/**
 * GET /api/prescriptions
 * Get user's prescriptions
 */
router.get('/', authenticate, async (req, res, next) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const pageSize = parseInt(req.query.pageSize, 10) || 20;
    const result = await prescriptionService.getUserPrescriptions(req.user.id, page, pageSize);
    return ApiResponse.paginated(res, result.items, result.total, page, pageSize);
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/prescriptions
 * Create a prescription
 */
router.post('/', authenticate, validate('createPrescription'), async (req, res, next) => {
  try {
    const prescription = await prescriptionService.createPrescription(req.user.id, req.validatedBody);
    return ApiResponse.created(res, prescription, '处方已创建');
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/prescriptions/:id
 * Get prescription details
 */
router.get('/:id', authenticate, async (req, res, next) => {
  try {
    const prescription = await prescriptionService.getPrescriptionById(req.params.id, req.user.id);
    return ApiResponse.success(res, prescription);
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/prescriptions/:id
 * Update prescription
 */
router.put('/:id', authenticate, async (req, res, next) => {
  try {
    const prescription = await prescriptionService.updatePrescription(req.params.id, req.user.id, req.body);
    return ApiResponse.success(res, prescription, '处方已更新');
  } catch (error) {
    next(error);
  }
});

/**
 * DELETE /api/prescriptions/:id
 * Delete prescription
 */
router.delete('/:id', authenticate, async (req, res, next) => {
  try {
    await prescriptionService.deletePrescription(req.params.id, req.user.id);
    return ApiResponse.success(res, null, '处方已删除');
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/prescriptions/:id/ocr
 * Submit OCR for prescription image
 */
router.post('/:id/ocr', authenticate, async (req, res, next) => {
  try {
    const { imageUrl } = req.body;
    if (!imageUrl) {
      return ApiResponse.badRequest(res, '请提供处方图片URL');
    }
    const result = await prescriptionService.submitOCR(req.params.id, req.user.id, imageUrl);
    return ApiResponse.success(res, result, 'OCR识别已提交');
  } catch (error) {
    next(error);
  }
});

module.exports = router;
