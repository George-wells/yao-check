const { query } = require('../config/database');
const { NotFoundError } = require('../utils/errors');
const cache = require('../config/redis');

class UserService {
  /**
   * Get user profile
   */
  async getUserProfile(userId) {
    const result = await query(
      `SELECT id, phone, name, avatar_url, gender, birth_date, age,
              is_elderly_mode, font_scale, high_contrast, enable_voice,
              push_enabled, sms_enabled,
              created_at, last_login_at
       FROM users 
       WHERE id = $1 AND deleted_at IS NULL`,
      [userId]
    );

    if (result.rows.length === 0) {
      throw new NotFoundError('用户不存在');
    }

    return result.rows[0];
  }

  /**
   * Update user profile
   */
  async updateProfile(userId, updates) {
    const fields = [];
    const values = [];
    let paramIndex = 1;

    const allowedFields = ['name', 'avatar_url', 'gender', 'birth_date'];

    for (const [key, value] of Object.entries(updates)) {
      if (allowedFields.includes(key) && value !== undefined) {
        fields.push(`${key} = $${paramIndex}`);
        values.push(value);
        paramIndex++;
      }
    }

    if (fields.length === 0) {
      throw new NotFoundError('没有需要更新的字段');
    }

    values.push(userId);

    const result = await query(
      `UPDATE users SET ${fields.join(', ')} WHERE id = $${paramIndex} AND deleted_at IS NULL RETURNING id, phone, name, avatar_url, gender, birth_date, age, is_elderly_mode, created_at`,
      values
    );

    if (result.rows.length === 0) {
      throw new NotFoundError('用户不存在');
    }

    return result.rows[0];
  }

  /**
   * Update elderly mode preferences
   */
  async updateElderlyPreferences(userId, preferences) {
    const fields = [];
    const values = [];
    let paramIndex = 1;

    const allowedFields = ['is_elderly_mode', 'font_scale', 'high_contrast', 'enable_voice'];

    for (const [key, value] of Object.entries(preferences)) {
      if (allowedFields.includes(key) && value !== undefined) {
        fields.push(`${key} = $${paramIndex}`);
        values.push(value);
        paramIndex++;
      }
    }

    if (fields.length === 0) {
      throw new NotFoundError('没有需要更新的字段');
    }

    values.push(userId);

    const result = await query(
      `UPDATE users SET ${fields.join(', ')} WHERE id = $${paramIndex} AND deleted_at IS NULL RETURNING id, is_elderly_mode, font_scale, high_contrast, enable_voice`,
      values
    );

    if (result.rows.length === 0) {
      throw new NotFoundError('用户不存在');
    }

    return result.rows[0];
  }

  /**
   * Get medication statistics for a user
   */
  async getMedicationStats(userId, days = 30) {
    const cacheKey = `stats:${userId}:${days}`;
    const cached = await cache.getCache(cacheKey);
    if (cached) return cached;

    const result = await query(
      `SELECT 
         COUNT(*) AS total_doses,
         COUNT(*) FILTER (WHERE status IN ('taken', 'late')) AS completed_doses,
         COUNT(*) FILTER (WHERE status = 'missed') AS missed_doses,
         COUNT(*) FILTER (WHERE status = 'skipped') AS skipped_doses,
         ROUND(
           COUNT(*) FILTER (WHERE status IN ('taken', 'late'))::DECIMAL / 
           NULLIF(COUNT(*), 0) * 100, 2
         ) AS compliance_rate,
         COUNT(DISTINCT scheduled_date) AS active_days,
         COUNT(DISTINCT medicine_name) AS medicine_count
       FROM medication_logs
       WHERE user_id = $1 
         AND scheduled_date >= CURRENT_DATE - $2::INTERVAL
         AND scheduled_date <= CURRENT_DATE`,
      [userId, `${days} days`]
    );

    const stats = result.rows[0];

    // Get daily compliance trend
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
      [userId, `${days} days`]
    );

    const resultData = {
      summary: stats,
      trend: trendResult.rows,
      period: days,
    };

    // Cache for 5 minutes
    await cache.setCache(cacheKey, resultData, 300);

    return resultData;
  }
}

module.exports = new UserService();
