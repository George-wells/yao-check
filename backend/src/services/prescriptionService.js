const { query } = require('../config/database');
const { NotFoundError, ValidationError } = require('../utils/errors');
const logger = require('../utils/logger');

class PrescriptionService {
  /**
   * Create a prescription
   */
  async createPrescription(userId, data) {
    const result = await query(
      `INSERT INTO prescriptions (
         user_id, doctor_name, doctor_title, hospital_name, department,
         prescription_number, issue_date, expiry_date, diagnosis,
         medicines, image_url, notes
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
       RETURNING *`,
      [
        userId,
        data.doctorName || null,
        data.doctorTitle || null,
        data.hospitalName || null,
        data.department || null,
        data.prescriptionNumber || null,
        data.issueDate || null,
        data.expiryDate || null,
        data.diagnosis || null,
        JSON.stringify(data.medicines || []),
        data.imageUrl || null,
        data.notes || null,
      ]
    );

    return result.rows[0];
  }

  /**
   * Get user's prescriptions
   */
  async getUserPrescriptions(userId, page = 1, pageSize = 20) {
    const offset = (page - 1) * pageSize;

    const result = await query(
      `SELECT id, doctor_name, hospital_name, department, issue_date, expiry_date,
              diagnosis, status, ocr_status, created_at
       FROM prescriptions
       WHERE user_id = $1 AND deleted_at IS NULL
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, pageSize, offset]
    );

    const countResult = await query(
      `SELECT COUNT(*) as total FROM prescriptions 
       WHERE user_id = $1 AND deleted_at IS NULL`,
      [userId]
    );

    return {
      items: result.rows,
      total: parseInt(countResult.rows[0].total, 10),
      page,
      pageSize,
    };
  }

  /**
   * Get prescription by ID
   */
  async getPrescriptionById(id, userId) {
    const result = await query(
      `SELECT * FROM prescriptions WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [id, userId]
    );

    if (result.rows.length === 0) {
      throw new NotFoundError('处方不存在');
    }

    return result.rows[0];
  }

  /**
   * Update prescription
   */
  async updatePrescription(id, userId, updates) {
    await this.getPrescriptionById(id, userId);

    const allowedFields = [
      'doctor_name', 'doctor_title', 'hospital_name', 'department',
      'prescription_number', 'issue_date', 'expiry_date', 'diagnosis',
      'medicines', 'notes', 'status',
    ];

    const setClauses = [];
    const values = [];
    let paramIndex = 1;

    for (const [key, value] of Object.entries(updates)) {
      const dbField = key.replace(/([A-Z])/g, '_$1').toLowerCase();
      if (allowedFields.includes(dbField) && value !== undefined) {
        if (key === 'medicines') {
          setClauses.push(`${dbField} = $${paramIndex}::jsonb`);
          values.push(JSON.stringify(value));
        } else {
          setClauses.push(`${dbField} = $${paramIndex}`);
          values.push(value);
        }
        paramIndex++;
      }
    }

    if (setClauses.length === 0) {
      throw new ValidationError('没有需要更新的字段');
    }

    values.push(id);

    const result = await query(
      `UPDATE prescriptions SET ${setClauses.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );

    return result.rows[0];
  }

  /**
   * Delete prescription (soft delete)
   */
  async deletePrescription(id, userId) {
    await this.getPrescriptionById(id, userId);
    await query('UPDATE prescriptions SET deleted_at = NOW() WHERE id = $1', [id]);
  }

  /**
   * Submit OCR task for prescription image
   */
  async submitOCR(prescriptionId, userId, imageUrl) {
    const prescription = await this.getPrescriptionById(prescriptionId, userId);

    await query(
      `UPDATE prescriptions SET image_url = $1, ocr_status = 'processing' WHERE id = $2`,
      [imageUrl, prescriptionId]
    );

    // TODO: Integrate with OCR service
    // For now, simulate OCR processing
    logger.info(`[DEV] OCR submitted for prescription ${prescriptionId}`);

    return { message: 'OCR识别任务已提交', prescriptionId };
  }

  /**
   * Update OCR result (called by OCR callback or internal processing)
   */
  async updateOCRResult(prescriptionId, ocrResult, confidence) {
    // Parse OCR result and extract medicine info
    const medicines = this._parseOCRResult(ocrResult);

    await query(
      `UPDATE prescriptions 
       SET ocr_raw_result = $1, ocr_confidence = $2, 
           medicines = $3::jsonb, ocr_status = 'completed'
       WHERE id = $4`,
      [ocrResult, confidence, JSON.stringify(medicines), prescriptionId]
    );

    return { medicines, confidence };
  }

  /**
   * Parse OCR result to extract medicine information
   */
  _parseOCRResult(ocrText) {
    // Basic parsing logic - in production, use NLP/ML
    const lines = ocrText.split('\n').filter((l) => l.trim());
    const medicines = [];

    for (const line of lines) {
      // Simple heuristic: look for common medicine patterns
      if (line.includes('片') || line.includes('胶囊') || line.includes('口服')) {
        medicines.push({
          name: line.trim(),
          dosage: '',
          frequency: '',
          duration: '',
        });
      }
    }

    return medicines;
  }

  /**
   * Check for expiring prescriptions and send reminders
   */
  async checkExpiringPrescriptions() {
    const result = await query(
      `SELECT p.id, p.user_id, p.medicine_names, p.expiry_date, u.phone
       FROM prescriptions p
       JOIN users u ON u.id = p.user_id
       WHERE p.status = 'active' 
         AND p.expiry_date IS NOT NULL
         AND p.expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
         AND p.deleted_at IS NULL`,
      []
    );

    return result.rows;
  }
}

module.exports = new PrescriptionService();
