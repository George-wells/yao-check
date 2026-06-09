const { query } = require('../config/database');
const { NotFoundError, ValidationError } = require('../utils/errors');
const logger = require('../utils/logger');
const notificationService = require('./notificationService');

class CheckinService {
  /**
   * Create a check-in record
   */
  async createCheckin(userId, checkinData) {
    const { planId, scheduledDate, scheduledTime, status, note, isMakeup, makeupNote } = checkinData;

    // Verify plan belongs to user
    const planResult = await query(
      `SELECT id, medicine_name, dosage_description FROM medication_plans 
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [planId, userId]
    );

    if (planResult.rows.length === 0) {
      throw new NotFoundError('用药计划不存在');
    }

    const plan = planResult.rows[0];

    // Check if log exists
    const existingResult = await query(
      `SELECT id, status FROM medication_logs 
       WHERE plan_id = $1 AND scheduled_date = $2 AND scheduled_time = $3`,
      [planId, scheduledDate, scheduledTime]
    );

    let log;

    if (existingResult.rows.length > 0) {
      const existing = existingResult.rows[0];

      // If already taken, prevent duplicate
      if (existing.status === 'taken') {
        throw new ValidationError('该次服药已完成打卡');
      }

      // Update existing log
      const result = await query(
        `UPDATE medication_logs 
         SET status = $1, actual_time = NOW(), note = $2, 
             is_makeup = $3, makeup_note = $4,
             delay_minutes = CASE 
               WHEN $5::TIME < scheduled_time THEN 
                 EXTRACT(EPOCH FROM (NOW()::TIME - scheduled_time)) / 60
               ELSE 0
             END::INTEGER
         WHERE id = $6
         RETURNING *`,
        [status, note || null, isMakeup || false, makeupNote || null, scheduledTime, existing.id]
      );
      log = result.rows[0];
    } else {
      // Create new log
      const result = await query(
        `INSERT INTO medication_logs (
           plan_id, user_id, medicine_id, medicine_name, dosage_description,
           scheduled_time, scheduled_date, actual_time, status, note, is_makeup, makeup_note
         ) VALUES (
           $1, $2, $3, $4, $5, $6, $7, NOW(), $8, $9, $10, $11
         ) RETURNING *`,
        [
          planId, userId, null, plan.medicine_name, plan.dosage_description,
          scheduledTime, scheduledDate, status, note || null,
          isMakeup || false, makeupNote || null,
        ]
      );
      log = result.rows[0];
    }

    // Check for missed dose streak
    if (status === 'taken' || status === 'late') {
      await this._checkMissedStreak(userId);
    }

    return log;
  }

  /**
   * Undo a check-in (within 5 minutes)
   */
  async undoCheckin(logId, userId) {
    const result = await query(
      `SELECT id, status, actual_time FROM medication_logs 
       WHERE id = $1 AND user_id = $2`,
      [logId, userId]
    );

    if (result.rows.length === 0) {
      throw new NotFoundError('打卡记录不存在');
    }

    const log = result.rows[0];

    // Check if within 5 minutes
    const elapsed = Date.now() - new Date(log.actual_time).getTime();
    if (elapsed > 5 * 60 * 1000) {
      throw new ValidationError('已超过撤销时间（5分钟）');
    }

    await query(
      `UPDATE medication_logs SET status = 'pending', actual_time = NULL, note = NULL WHERE id = $1`,
      [logId]
    );

    return { message: '打卡已撤销' };
  }

  /**
   * Get check-in records for a date range
   */
  async getCheckins(userId, startDate, endDate, page = 1, pageSize = 50) {
    const offset = (page - 1) * pageSize;

    const result = await query(
      `SELECT ml.*, mp.medicine_specification, mp.dosage_form
       FROM medication_logs ml
       LEFT JOIN medication_plans mp ON mp.id = ml.plan_id
       WHERE ml.user_id = $1 
         AND ml.scheduled_date >= $2
         AND ml.scheduled_date <= $3
       ORDER BY ml.scheduled_date DESC, ml.scheduled_time ASC
       LIMIT $4 OFFSET $5`,
      [userId, startDate, endDate, pageSize, offset]
    );

    const countResult = await query(
      `SELECT COUNT(*) as total FROM medication_logs 
       WHERE user_id = $1 AND scheduled_date >= $2 AND scheduled_date <= $3`,
      [userId, startDate, endDate]
    );

    return {
      items: result.rows,
      total: parseInt(countResult.rows[0].total, 10),
      page,
      pageSize,
    };
  }

  /**
   * Get calendar view data
   */
  async getCalendarView(userId, year, month) {
    const startDate = `${year}-${String(month).padStart(2, '0')}-01`;
    const endDate = new Date(year, month, 0).toISOString().split('T')[0];

    const result = await query(
      `SELECT 
         scheduled_date,
         COUNT(*) AS total,
         COUNT(*) FILTER (WHERE status IN ('taken', 'late')) AS completed,
         COUNT(*) FILTER (WHERE status = 'missed') AS missed,
         COUNT(*) FILTER (WHERE status = 'skipped') AS skipped
       FROM medication_logs
       WHERE user_id = $1 AND scheduled_date >= $2 AND scheduled_date <= $3
       GROUP BY scheduled_date
       ORDER BY scheduled_date`,
      [userId, startDate, endDate]
    );

    return result.rows;
  }

  /**
   * Check for missed dose streak and send care message
   */
  async _checkMissedStreak(userId) {
    // Check if user has 3+ consecutive missed doses
    const result = await query(
      `SELECT COUNT(*) AS streak FROM (
         SELECT scheduled_date, status,
                scheduled_date - ROW_NUMBER() OVER (ORDER BY scheduled_date) AS grp
         FROM medication_logs
         WHERE user_id = $1 AND status = 'missed'
           AND scheduled_date >= CURRENT_DATE - INTERVAL '7 days'
         GROUP BY scheduled_date, status
       ) sub
       GROUP BY grp
       ORDER BY COUNT(*) DESC
       LIMIT 1`,
      [userId]
    );

    if (result.rows.length > 0 && parseInt(result.rows[0].streak, 10) >= 3) {
      // Send care notification
      await notificationService.createNotification(userId, {
        type: 'care_message',
        title: '用药关怀提醒',
        body: '您最近连续漏服次数较多，建议咨询医生或调整用药方案。如有需要，可联系您的家人获取帮助。',
        data: { route: '/records' },
      });
    }
  }
}

module.exports = new CheckinService();
