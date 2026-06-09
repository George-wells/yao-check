const express = require('express');
const router = express.Router();
const medicineService = require('../services/medicineService');
const { authenticate, optionalAuth } = require('../middleware/auth');
const { validate } = require('../utils/validators');
const ApiResponse = require('../utils/response');

/**
 * GET /api/medicines
 * Search medicines
 */
router.get('/', optionalAuth, async (req, res, next) => {
  try {
    const keyword = req.query.keyword || '';
    const page = parseInt(req.query.page, 10) || 1;
    const pageSize = parseInt(req.query.pageSize, 10) || 20;

    if (!keyword.trim()) {
      return ApiResponse.badRequest(res, '请输入搜索关键词');
    }

    const result = await medicineService.searchMedicines(keyword, page, pageSize);
    return ApiResponse.paginated(res, result.items, result.total, page, pageSize);
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/medicines/:id
 * Get medicine details
 */
router.get('/:id', optionalAuth, async (req, res, next) => {
  try {
    const medicine = await medicineService.getMedicineById(req.params.id);
    return ApiResponse.success(res, medicine);
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/medicines/barcode/:code
 * Get medicine by barcode
 */
router.get('/barcode/:code', optionalAuth, async (req, res, next) => {
  try {
    const medicine = await medicineService.getMedicineByBarcode(req.params.code);
    return ApiResponse.success(res, medicine);
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/medicines/interactions
 * Check drug interactions
 */
router.post('/interactions', authenticate, validate('checkInteractions'), async (req, res, next) => {
  try {
    const result = await medicineService.checkInteractions(req.validatedBody.medicineIds);
    return ApiResponse.success(res, result);
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/medicines/category/:code
 * Get medicines by category
 */
router.get('/category/:code', optionalAuth, async (req, res, next) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const pageSize = parseInt(req.query.pageSize, 10) || 20;
    const result = await medicineService.getMedicinesByCategory(req.params.code, page, pageSize);
    return ApiResponse.paginated(res, result.items, result.total, page, pageSize);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
