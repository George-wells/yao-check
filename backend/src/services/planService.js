const { query, getClient } = require('../config/database');
const { NotFoundError, ValidationError } = require('../utils/errors');
const logger = require('../utils/logger');

class PlanService {
  /**
   * Create medication plan
   */
  async createPlan(userId, planData) {
    const client = await getClient();
    try {
      await client.query('BEGIN');

      const result = await client.query(
        `INSERT INTO medication_plans (
           user_id, medicine_id, medicine_name, medicine_specification, dosage_form,
           dosage_value, dosage_unit, dosage_description,
           frequency_type, frequency_interval, frequency_times_per_day,
           schedule, start_date, end_date,
           stock_quantity, stock_unit, notes
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
         RETURNING *`,
        [
          userId,
          planData.medicineId || null,
          planData.medicineName,
          planData.medicineSpecification || null,
          planData.dosageForm || null,
          planData.dosageValue,
          planData.dosageUnit,
          planData.dosageDescription || null,
          planData.frequencyType,
          planData.frequencyInterval || null,
          planData.frequencyTimesPerDay || null,
          JSON.stringify(planData.schedule),
          planData.startDate,
          planData.endDate || null,
          planData.stockQuantity || null,
          planData.stockUnit || null,
          planData.notes || null,
        ]
      );

      const plan = result.rows[0];

      // Generate initial medication logs
      await this._generateLogs(client, plan);

      await client.query('COMMIT');
      return plan;
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Failed to create medication plan', { error: error.message, userId });
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Generate medication logs for a plan
   */
  async _generateLogs(client, plan) {
    const schedule = typeof plan.schedule === 'string'
      ? JSON.parse(plan.schedule)
      : plan.schedule;

    const startDate = new Date(plan.start_date);
    const endDate = plan.end_date
      ? new Date(plan.end_date)
      : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days from now

    const values = [];
    const paramSets = [];
    let paramIndex = 1;

    for (const sched of schedule) {
      const timeStr = sched.time;
      const daysOfWeek = sched.days_of_week || sched.daysOfWeek;

      const current = new Date(startDate);
      while (current <= endDate) {
        const dayOfWeek = current.getDay(); // 0=Sunday, 1=Monday, ...
        if (daysOfWeek.includes(dayOfWeek)) {
          const dateStr = current.toISOString().split('T')[0];
          values.push(
            plan.id, plan.user_id, plan.medicine_id, plan.medicine_name,
            plan.dosage_description, timeStr, dateStr, 'pending'
          );
          paramSets.push(
            `($${paramIndex}, $${paramIndex + 1}, $${paramIndex + 2}, $${paramIndex + 3}, $${paramIndex + 4}, $${paramIndex + 5}, $${paramIndex + 6}, $${paramIndex + 7})`
          );
          paramIndex += 8;
        }
        current.setDate(current.getDate() + 1);
      }
    }

    if (paramSets.length > 0) {
      await client.query(
        `INSERT INTO medication_logs (plan_id, user_id, medicine_id, medicine_name, dosage_description, scheduled_time, scheduled_date, status) VALUES ${paramSets.join(', ')}`,
        values
      );
    }
  }

  /**
   * Get plans for a user
   */
  async getUserPlans(userId, includeInactive = false) {
    const result = await query(
      `SELECT mp.*, 
              (SELECT COUNT(*) FROM medication_logs ml 
               WHERE ml.plan_id = mp.id AND ml.scheduled_date = CURRENT_DATE 
               AND ml.status = 'pending') AS pending_today
       FROM medication_plans mp
       WHERE mp.user_id = $1 
         AND mp.deleted_at IS NULL
         ${includeInactive ? '' : 'AND mp.is_active = TRUE'}
       ORDER BY mp.created_at DESC`,
      [userId]
    );

    return result.rows;
  }

  /**
   * Get plan by ID
   */
  async getPlanById(planId, userId) {
    const result = await query(
      `SELECT * FROM medication_plans 
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [planId, userId]
    );

    if (result.rows.length === 0) {
      throw new NotFoundError('用药计划不存在');
    }

    return result.rows[0];
  }

  /**
   * Update medication plan
   */
  async updatePlan(planId, userId, updates) {
    const plan = await this.getPlanById(planId, userId);

    const allowedFields = [
      'medicine_name', 'dosage_value', 'dosage_unit', 'dosage_description',
      'frequency_type', 'frequency_interval', 'frequency_times_per_day',
      'schedule', 'end_date', 'stock_quantity', 'is_active', 'notes',
    ];

    const setClauses = [];
    const values = [];
    let paramIndex = 1;

    for (const [key, value] of Object.entries(updates)) {
      const dbField = key.replace(/([A-Z])/g, '_$1').toLowerCase();
      if (allowedFields.includes(dbField) && value !== undefined) {
        if (key === 'schedule') {
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

    values.push(planId);

    const result = await query(
      `UPDATE medication_plans SET ${setClauses.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );

    return result.rows[0];
  }

  /**
   * Delete medication plan (soft delete)
   */
  async deletePlan(planId, userId) {
    const plan = await this.getPlanById(planId, userId);

    await query(
      `UPDATE medication_plans SET deleted_at = NOW(), is_active = FALSE WHERE id = $1`,
      [planId]
    );

    // Also mark pending logs as skipped
    await query(
      `UPDATE medication_logs SET status = 'skipped' 
       WHERE plan_id = $1 AND status = 'pending' AND scheduled_date >= CURRENT_DATE`,
      [planId]
    );
  }

  /**
   * Get today's pending medications for a user
   */
  async getTodaySchedule(userId) {
    const result = await query(
      `SELECT 
         ml.id AS log_id,
         ml.plan_id,
         ml.medicine_name,
         ml.dosage_description,
         ml.scheduled_time,
         ml.status,
         ml.is_makeup,
         mp.medicine_specification,
         mp.dosage_form
       FROM medication_logs ml
       JOIN medication_plans mp ON mp.id = ml.plan_id
       WHERE ml.user_id = $1 
         AND ml.scheduled_date = CURRENT_DATE
         AND mp.deleted_at IS NULL
       ORDER BY ml.scheduled_time`,
      [userId]
    );

    const pending = result.rows.filter((r) => r.status === 'pending');
    const completed = result.rows.filter((r) => ['taken', 'late'].includes(r.status));
    const missed = result.rows.filter((r) => r.status === 'missed');

    return {
      total: result.rows.length,
      pending,
      completed,
      missed,
      progress: result.rows.length > 0
        ? Math.round((completed.length / result.rows.length) * 100)
        : 0,
    };
  }
}

module.exports = new PlanService();
