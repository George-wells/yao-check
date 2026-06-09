const express = require('express');
const router = express.Router();
const guardianService = require('../services/guardianService');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../utils/validators');
const ApiResponse = require('../utils/response');

/**
 * GET /api/guardians/patients
 * Get guardian's list of patients
 */
router.get('/patients', authenticate, async (req, res, next) => {
  try {
    const patients = await guardianService.getGuardianPatients(req.user.id);
    return ApiResponse.success(res, patients);
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/guardians/my-guardians
 * Get patient's guardians
 */
router.get('/my-guardians', authenticate, async (req, res, next) => {
  try {
    const guardians = await guardianService.getPatientGuardians(req.user.id);
    return ApiResponse.success(res, guardians);
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/guardians/invitations
 * Get pending guardian invitations
 */
router.get('/invitations', authenticate, async (req, res, next) => {
  try {
    const invitations = await guardianService.getPendingInvitations(req.user.id);
    return ApiResponse.success(res, invitations);
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/guardians
 * Create guardian relationship (send invitation)
 */
router.post('/', authenticate, validate('createGuardian'), async (req, res, next) => {
  try {
    const guardian = await guardianService.createGuardian(req.user.id, req.validatedBody);
    return ApiResponse.created(res, guardian, '监护邀请已发送');
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/guardians/:patientId/confirm
 * Confirm or reject guardian relationship
 */
router.put('/:patientId/confirm', authenticate, validate('confirmGuardian'), async (req, res, next) => {
  try {
    const result = await guardianService.confirmGuardian(
      req.params.patientId,
      req.user.id,
      req.validatedBody.action
    );
    return ApiResponse.success(res, result);
  } catch (error) {
    next(error);
  }
});

/**
 * DELETE /api/guardians/:patientId
 * Cancel guardian relationship
 */
router.delete('/:patientId', authenticate, async (req, res, next) => {
  try {
    const result = await guardianService.cancelGuardian(req.user.id, req.params.patientId);
    return ApiResponse.success(res, result);
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/guardians/:patientId/report
 * Get guardian report for a patient
 */
router.get('/:patientId/report', authenticate, async (req, res, next) => {
  try {
    const days = parseInt(req.query.days, 10) || 7;
    const report = await guardianService.getPatientReport(req.user.id, req.params.patientId, days);
    return ApiResponse.success(res, report);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
