const { query } = require('../config/database');
const logger = require('../utils/logger');

class NotificationService {
  /**
   * Create a push notification record
   */
  async createNotification(userId, { type, title, body, data, relatedPlanId, relatedLogId }) {
    const result = await query(
      `INSERT INTO push_notifications (
         user_id, notification_type, title, body, data, is_sent,
         related_plan_id, related_log_id
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        userId,
        type,
        title,
        body,
        data ? JSON.stringify(data) : null,
        false, // is_sent - actual push will be handled by push service
        relatedPlanId || null,
        relatedLogId || null,
      ]
    );

    // Attempt to send push notification
    await this._sendPush(userId, title, body, data).catch((err) => {
      logger.warn('Failed to send push notification', { userId, error: err.message });
    });

    return result.rows[0];
  }

  /**
   * Get user's notifications
   */
  async getUserNotifications(userId, page = 1, pageSize = 50, unreadOnly = false) {
    const offset = (page - 1) * pageSize;

    let whereClause = 'user_id = $1';
    const params = [userId];

    if (unreadOnly) {
      whereClause += ' AND is_read = FALSE';
    }

    const result = await query(
      `SELECT id, notification_type, title, body, data, is_read, created_at
       FROM push_notifications
       WHERE ${whereClause}
       ORDER BY created_at DESC
       LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
      [...params, pageSize, offset]
    );

    const countResult = await query(
      `SELECT COUNT(*) as total FROM push_notifications WHERE ${whereClause}`,
      params
    );

    return {
      items: result.rows,
      total: parseInt(countResult.rows[0].total, 10),
      page,
      pageSize,
    };
  }

  /**
   * Mark notification as read
   */
  async markAsRead(notificationId, userId) {
    await query(
      `UPDATE push_notifications SET is_read = TRUE, read_at = NOW()
       WHERE id = $1 AND user_id = $2`,
      [notificationId, userId]
    );
  }

  /**
   * Mark all notifications as read
   */
  async markAllAsRead(userId) {
    await query(
      `UPDATE push_notifications SET is_read = TRUE, read_at = NOW()
       WHERE user_id = $1 AND is_read = FALSE`,
      [userId]
    );
  }

  /**
   * Get unread count
   */
  async getUnreadCount(userId) {
    const result = await query(
      `SELECT COUNT(*) as count FROM push_notifications 
       WHERE user_id = $1 AND is_read = FALSE`,
      [userId]
    );

    return parseInt(result.rows[0].count, 10);
  }

  /**
   * Send push notification via push service
   */
  async _sendPush(userId, title, body, data) {
    // Get user's device tokens
    const deviceResult = await query(
      `SELECT device_token, platform FROM device_tokens 
       WHERE user_id = $1 AND is_active = TRUE`,
      [userId]
    );

    if (deviceResult.rows.length === 0) {
      logger.debug('No device tokens found for user', { userId });
      return;
    }

    // TODO: Integrate with JPush / Getui / Firebase Cloud Messaging
    // For development, log the notification
    logger.info(`[DEV] Push notification to user ${userId}:`, {
      title,
      body,
      data,
      devices: deviceResult.rows.length,
    });

    // Mark as sent
    await query(
      `UPDATE push_notifications SET is_sent = TRUE, sent_at = NOW()
       WHERE user_id = $1 AND notification_type = $2 AND is_sent = FALSE
       ORDER BY created_at DESC LIMIT 1`,
      [userId, data?.type || 'system_notification']
    );
  }

  /**
   * Generate medication reminder notifications for all users
   * Called by cron job
   */
  async generateMedicationReminders() {
    const now = new Date();
    const currentTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
    const dayOfWeek = now.getDay();

    // Find all pending medication logs for current time
    const result = await query(
      `SELECT ml.id AS log_id, ml.plan_id, ml.user_id, ml.medicine_name, 
              ml.dosage_description, ml.scheduled_time
       FROM medication_logs ml
       JOIN medication_plans mp ON mp.id = ml.plan_id
       WHERE ml.scheduled_date = CURRENT_DATE
         AND ml.status = 'pending'
         AND ml.scheduled_time = $1::TIME
         AND mp.deleted_at IS NULL`,
      [currentTime]
    );

    for (const log of result.rows) {
      await this.createNotification(log.user_id, {
        type: 'medication_reminder',
        title: '服药提醒',
        body: `该服用 ${log.medicine_name} 了（${log.dosage_description || ''}）`,
        data: { route: `/checkin/${log.plan_id}`, logId: log.log_id },
        relatedPlanId: log.plan_id,
        relatedLogId: log.log_id,
      });
    }

    return result.rows.length;
  }

  /**
   * Detect missed doses and send notifications
   */
  async detectMissedDoses() {
    const result = await query(
      `SELECT ml.id AS log_id, ml.plan_id, ml.user_id, ml.medicine_name,
              ml.dosage_description, ml.scheduled_time
       FROM medication_logs ml
       JOIN medication_plans mp ON mp.id = ml.plan_id
       WHERE ml.scheduled_date = CURRENT_DATE
         AND ml.status = 'pending'
         AND (ml.scheduled_time::TIME + INTERVAL '30 minutes') <= CURRENT_TIME
         AND mp.deleted_at IS NULL`,
      []
    );

    // Mark as missed
    for (const log of result.rows) {
      await query(
        `UPDATE medication_logs SET status = 'missed' WHERE id = $1 AND status = 'pending'`,
        [log.log_id]
      );

      // Notify user
      await this.createNotification(log.user_id, {
        type: 'missed_dose',
        title: '漏服提醒',
        body: `您错过了 ${log.medicine_name} 的服药时间（${log.dosage_description || ''}），请尽快补服`,
        data: { route: `/checkin/${log.plan_id}`, logId: log.log_id },
        relatedPlanId: log.plan_id,
        relatedLogId: log.log_id,
      });

      // Notify guardians
      const guardians = await query(
        `SELECT guardian_id FROM guardians 
         WHERE patient_id = $1 AND status = 'active' AND can_receive_notifications = TRUE`,
        [log.user_id]
      );

      for (const guardian of guardians.rows) {
        await this.createNotification(guardian.guardian_id, {
          type: 'guardian_missed_dose',
          title: '家人漏服提醒',
          body: `您监护的用户错过了 ${log.medicine_name} 的服药时间`,
          data: { route: `/family/${log.user_id}`, logId: log.log_id },
          relatedPlanId: log.plan_id,
          relatedLogId: log.log_id,
        });
      }
    }

    return result.rows.length;
  }
}

module.exports = new NotificationService();
