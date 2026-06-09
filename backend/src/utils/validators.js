const Joi = require('joi');

/**
 * Validation schemas for API requests
 */

const schemas = {
  // Auth schemas
  sendVerificationCode: Joi.object({
    phone: Joi.string().pattern(/^1[3-9]\d{9}$/).required()
      .messages({
        'string.pattern.base': '请输入正确的手机号码',
        'any.required': '手机号不能为空',
      }),
    purpose: Joi.string().valid('login', 'register', 'reset_password', 'bind_phone').required(),
  }),

  login: Joi.object({
    phone: Joi.string().pattern(/^1[3-9]\d{9}$/).required(),
    code: Joi.string().length(6).required(),
  }),

  refreshToken: Joi.object({
    refreshToken: Joi.string().required(),
  }),

  // User schemas
  updateProfile: Joi.object({
    name: Joi.string().min(1).max(100),
    avatarUrl: Joi.string().uri().max(500).allow('', null),
    gender: Joi.string().valid('male', 'female', 'other'),
    birthDate: Joi.date().iso(),
  }),

  updateElderlyPreferences: Joi.object({
    isElderlyMode: Joi.boolean(),
    fontScale: Joi.number().min(0.8).max(2.0),
    highContrast: Joi.boolean(),
    enableVoice: Joi.boolean(),
  }),

  // Medicine schemas
  searchMedicine: Joi.object({
    keyword: Joi.string().min(1).max(200).required(),
    page: Joi.number().integer().min(1).default(1),
    pageSize: Joi.number().integer().min(1).max(100).default(20),
  }),

  checkInteractions: Joi.object({
    medicineIds: Joi.array().items(Joi.string().uuid()).min(2).max(20).required()
      .messages({
        'array.min': '至少需要两种药品进行相互作用检查',
        'any.required': '药品ID列表不能为空',
      }),
  }),

  // Medication plan schemas
  createPlan: Joi.object({
    medicineId: Joi.string().uuid().allow(null),
    medicineName: Joi.string().min(1).max(200).required(),
    medicineSpecification: Joi.string().max(200).allow('', null),
    dosageForm: Joi.string().max(50).allow('', null),
    dosageValue: Joi.number().positive().required(),
    dosageUnit: Joi.string().valid('片', '粒', 'ml', 'mg', 'g', '袋', '支', '瓶').required(),
    dosageDescription: Joi.string().max(200).allow('', null),
    frequencyType: Joi.string().valid('daily', 'every_n_hours', 'specific_days', 'as_needed').required(),
    frequencyInterval: Joi.when('frequencyType', {
      is: 'every_n_hours',
      then: Joi.number().integer().min(1).max(24).required(),
      otherwise: Joi.optional(),
    }),
    frequencyTimesPerDay: Joi.number().integer().min(1).max(10).optional(),
    schedule: Joi.array().items(
      Joi.object({
        time: Joi.string().pattern(/^([01]\d|2[0-3]):[0-5]\d$/).required(),
        daysOfWeek: Joi.array().items(Joi.number().integer().min(0).max(6)).min(1).required(),
      })
    ).min(1).required(),
    startDate: Joi.date().iso().default(() => new Date().toISOString().split('T')[0]),
    endDate: Joi.date().iso().allow(null).min(Joi.ref('startDate')),
    stockQuantity: Joi.number().positive().allow(null),
    stockUnit: Joi.string().max(20).allow('', null),
    notes: Joi.string().max(500).allow('', null),
  }),

  updatePlan: Joi.object({
    medicineId: Joi.string().uuid().allow(null),
    medicineName: Joi.string().min(1).max(200),
    dosageValue: Joi.number().positive(),
    dosageUnit: Joi.string().valid('片', '粒', 'ml', 'mg', 'g', '袋', '支', '瓶'),
    dosageDescription: Joi.string().max(200).allow('', null),
    frequencyType: Joi.string().valid('daily', 'every_n_hours', 'specific_days', 'as_needed'),
    schedule: Joi.array().items(
      Joi.object({
        time: Joi.string().pattern(/^([01]\d|2[0-3]):[0-5]\d$/).required(),
        daysOfWeek: Joi.array().items(Joi.number().integer().min(0).max(6)).min(1).required(),
      })
    ).min(1),
    endDate: Joi.date().iso().allow(null),
    stockQuantity: Joi.number().positive().allow(null),
    isActive: Joi.boolean(),
    notes: Joi.string().max(500).allow('', null),
  }),

  // Check-in schemas
  createCheckin: Joi.object({
    planId: Joi.string().uuid().required(),
    scheduledDate: Joi.date().iso().required(),
    scheduledTime: Joi.string().pattern(/^([01]\d|2[0-3]):[0-5]\d$/).required(),
    status: Joi.string().valid('taken', 'skipped', 'late').required(),
    note: Joi.string().max(500).allow('', null),
    isMakeup: Joi.boolean().default(false),
    makeupNote: Joi.string().max(200).allow('', null),
  }),

  // Prescription schemas
  createPrescription: Joi.object({
    doctorName: Joi.string().max(100).allow('', null),
    doctorTitle: Joi.string().max(100).allow('', null),
    hospitalName: Joi.string().max(200).allow('', null),
    department: Joi.string().max(100).allow('', null),
    prescriptionNumber: Joi.string().max(100).allow('', null),
    issueDate: Joi.date().iso().allow(null),
    expiryDate: Joi.date().iso().allow(null),
    diagnosis: Joi.string().max(500).allow('', null),
    medicines: Joi.array().items(
      Joi.object({
        name: Joi.string().required(),
        dosage: Joi.string().allow('', null),
        frequency: Joi.string().allow('', null),
        duration: Joi.string().allow('', null),
      })
    ).default([]),
    imageUrl: Joi.string().uri().max(500).allow('', null),
    notes: Joi.string().max(500).allow('', null),
  }),

  // Guardian schemas
  createGuardian: Joi.object({
    patientId: Joi.string().uuid().required(),
    relationship: Joi.string().valid('spouse', 'child', 'parent', 'sibling', 'relative', 'caregiver', 'other').required(),
    notes: Joi.string().max(200).allow('', null),
  }),

  confirmGuardian: Joi.object({
    action: Joi.string().valid('accept', 'reject').required(),
  }),

  // Push notification schemas
  registerDevice: Joi.object({
    deviceToken: Joi.string().required(),
    platform: Joi.string().valid('ios', 'android', 'web').required(),
    deviceName: Joi.string().max(200).allow('', null),
  }),
};

/**
 * Validate request body against a schema
 */
function validate(schemaName) {
  return (req, res, next) => {
    const schema = schemas[schemaName];
    if (!schema) {
      return next(new Error(`Validation schema '${schemaName}' not found`));
    }

    const { error, value } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }));
      return res.status(400).json({
        success: false,
        message: '请求参数验证失败',
        errors,
        timestamp: new Date().toISOString(),
      });
    }

    req.validatedBody = value;
    next();
  };
}

module.exports = {
  schemas,
  validate,
};
