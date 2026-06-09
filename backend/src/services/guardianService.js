const { query } = require('../config/database');
const { NotFoundError, ValidationError, ConflictError } = require('../utils/errors');
const logger = require('../utils/logger');
const notificationService = require('./notificationService');

class GuardianService {
  /**
   * Create guardian relationship (send invitation)
   */
  async createGuardian(guardianId, data) {
    const { patientId, relationship, notes } = data;

    // Verify patient exists
    const patientResult = await query(
      `SELECT id, name, phone FROM users WHERE id = $1 AND deleted_at IS NULL`,
      [patientId]
    );

    if (patientResult.rows.length === 0) {
      throw new NotFoundError('被监护人用户不存在');
    }

    // Check if relationship already exists
    const existingResult = await query(
      `SELECT id, status FROM guardians 
       WHERE guardian_id = $1 AND patient_id = $2`,
      [guardianId, patientId]
    );

    if (existingResult.rows.length > 0) {
      const existing = existingResult.rows[0];
      if (existing.status === 'active') {
        throw new ConflictError('监护关系已存在');
      }
      if (existing.status === 'pending') {
        throw new ConflictError('已发送过监护邀请，请等待对方确认');
      }
      // If rejected or cancelled, allow re-creation
      await query('DELETE FROM guardians WHERE id = $1', [existing.id]);
    }

    const result = await query(
      `INSERT INTO guardians (guardian_id, patient_id, relationship, notes)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [guardianId, patientId, relationship, notes || null]
    );

    const guardian = result.rows[0];

    // Notify patient about the guardian invitation
    await notificationService.createNotification(patientId, {
      type: 'system_notification',
      title: '新的监护邀请',
      body: `用户请求成为您的监护人，请前往"家人监护"页面确认。`,
      data: { route: '/family', guardianId },
    });

    return guardian;
  }

  /**
   * Confirm or reject guardian relationship
   */
  async confirmGuardian(guardianId, patientId, action) {
    const result = await query(
      `SELECT * FROM guardians 
       WHERE guardian_id = $1 AND patient_id = $2 AND status = 'pending'`,
      [guardianId, patientId]
    );

    if (result.rows.length === 0) {
      throw new NotFoundError('未找到待确认的监护关系');
    }

    const guardian = result.rows[0];

    if (action === 'accept') {
      await query(
        `UPDATE guardians SET status = 'active', confirmed_at = NOW() WHERE id = $1`,
        [guardian.id]
      );

      // Notify guardian
      await notificationService.createNotification(guardianId, {
        type: 'system_notification',
        title: '监护关系已确认',
        body: '对方已同意您的监护请求，现在您可以查看对方的用药情况。',
        data: { route: '/family' },
      });

      return { status: 'active', message: '监护关系已确认' };
    } else {
      await query(
        `UPDATE guardians SET status = 'rejected' WHERE id = $1`,
        [guardian.id]
      );

      return { status: 'rejected', message: '已拒绝监护请求' };
    }
  }

  /**
   * Cancel guardian relationship
   */
  async cancelGuardian(guardianId, patientId) {
    const result = await query(
      `UPDATE guardians SET status = 'cancelled', cancelled_at = NOW()
       WHERE ((guardian_id = $1 AND patient_id = $2) OR (guardian_id = $2 AND patient_id = $1))
         AND status = 'active'
       RETURNING *`,
      [guardianId, patientId]
    );

    if (result.rows.length === 0) {
      throw new NotFoundError('未找到有效的监护关系');
    }

    return { message: '监护关系已解除' };
  }

  /**
   * Get guardian's list of patients
   */
  async getGuardianPatients(guardianId) {
    const result = await query(
      `SELECT 
         g.id AS guardian_id,
         g.relationship,
         g.created_at AS bound_at,
         u.id AS patient_id,
         u.name AS patient_name,
         u.phone AS patient_phone,
         u.age,
         u.is_elderly_mode
       FROM guardians g
       JOIN users u ON u.id = g.patient_id
       WHERE g.guardian_id = $1 AND g.status = 'active'
       ORDER BY u.name`,
      [guardianId]
    );

    // Get today's medication summary for each patient
    const patients = await Promise.all(
      result.rows.map(async (patient) => {
        const todayResult = await query(
          `SELECT 
             COUNT(*) AS total,
             COUNT(*) FILTER (WHERE status IN ('taken', 'late')) AS completed,
             COUNT(*) FILTER (WHERE status = 'missed') AS missed
           FROM medication_logs
           WHERE user_id = $1 AND scheduled_date = CURRENT_DATE`,
          [patient.patient_id]
        );

        return {
          ...patient,
          todaySummary: todayResult.rows[0],
        };
      })
    );

    return patients;
  }

  /**
   * Get patient's guardians
   */
  async getPatientGuardians(patientId) {
    const result = await query(
      `SELECT 
         g.id AS guardian_id,
         g.relationship,
         g.status,
         g.created_at,
         u.id AS guardian_user_id,
         u.name AS guardian_name,
         u.phone AS guardian_phone
       FROM guardians g
       JOIN users u ON u.id = g.guardian_id
       WHERE g.patient_id = $1 AND g.status IN ('active', 'pending')
       ORDER BY g.created_at DESC`,
      [patientId]
    );

    return result.rows;
  }

  /**
   * Get guardian report for a patient
   */
  async getPatientReport(guardianId, patientId, days = 7) {
    // Verify guardian relationship
    const relationResult = await query(
      `SELECT id, relationship FROM guardians 
       WHERE guardian_id = $1 AND patient_id = $2 AND status = 'active'`,
      [guardianId, patientId]
    );

    if (relationResult.rows.length === 0) {
      throw new NotFoundError('未找到有效的监护关系');
    }

    // Get medication summary
    const summaryResult = await query(
      `SELECT 
         COUNT(*) AS total_doses,
         COUNT(*) FILTER (WHERE status IN ('taken', 'late')) AS completed_doses,
         COUNT(*) FILTER (WHERE status = 'missed') AS missed_doses,
         ROUND(
           COUNT(*) FILTER (WHERE status IN ('taken', 'late'))::DECIMAL / 
           NULLIF(COUNT(*), 0) * 100, 2
         ) AS compliance_rate
       FROM medication_logs
       WHERE user_id = $1 
         AND scheduled_date >= CURRENT_DATE - $2::INTERVAL`,
      [patientId, `${days} days`]
    );

    // Get daily trend
    const trendResult = await query(
      `SELECT 
         scheduled_date,
         COUNT(*) AS total,
         COUNT(*) FILTER (WHERE status IN ('taken', 'late')) AS completed,
         ROUND(
           COUNT(*) FILTER (WHERE status IN ('taken', 'late'))::DECIMAL / 
           NULLIF(COUNT(*), 0) * 100, 2
         ) AS rate
       FROM medication_logs
       WHERE user_id = $1 
         AND scheduled_date >= CURRENT_DATE - $2::INTERVAL
       GROUP BY scheduled_date
       ORDER BY scheduled_date`,
      [patientId, `${days} days`]
    );

    // Get patient info
    const patientResult = await query(
      `SELECT id, name, age, is_elderly_mode FROM users WHERE id = $1`,
      [patientId]
    );

    return {
      patient: patientResult.rows[0],
      relationship: relationResult.rows[0].relationship,
      summary: summaryResult.rows[0],
      trend: trendResult.rows,
      period: days,
    };
  }

  /**
   * Get pending guardian invitations for a user
   */
  async getPendingInvitations(userId) {
    const result = await query(
      `SELECT 
         g.id,
         g.relationship,
         g.notes,
         g.created_at,
         u.id AS guardian_id,
         u.name AS guardian_name,
         u.phone AS guardian_phone
       FROM guardians g
       JOIN users u ON u.id = g.guardian_id
       WHERE g.patient_id = $1 AND g.status = 'pending'
       ORDER BY g.created_at DESC`,
      [userId]
    );

    return result.rows;
  }
}

module.exports = new GuardianService();
