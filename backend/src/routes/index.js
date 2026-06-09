const express = require('express');
const router = express.Router();

const authRoutes = require('./auth');
const userRoutes = require('./users');
const medicineRoutes = require('./medicines');
const planRoutes = require('./plans');
const checkinRoutes = require('./checkins');
const prescriptionRoutes = require('./prescriptions');
const guardianRoutes = require('./guardians');
const notificationRoutes = require('./notifications');

// Health check
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: '智能用药App API服务运行正常',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// Mount routes
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/medicines', medicineRoutes);
router.use('/plans', planRoutes);
router.use('/checkins', checkinRoutes);
router.use('/prescriptions', prescriptionRoutes);
router.use('/guardians', guardianRoutes);
router.use('/notifications', notificationRoutes);

module.exports = router;
