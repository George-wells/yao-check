const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { query, getClient } = require('../config/database');
const config = require('../config');
const logger = require('../utils/logger');
const { AuthenticationError, ConflictError, NotFoundError } = require('../utils/errors');

class AuthService {
  /**
   * Send SMS verification code
   */
  async sendVerificationCode(phone, purpose) {
    // Generate 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();

    // Store code in database
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

    await query(
      `INSERT INTO verification_codes (phone, code, purpose, expires_at)
       VALUES ($1, $2, $3, $4)`,
      [phone, code, purpose, expiresAt]
    );

    // TODO: Integrate with SMS service provider
    // For development, log the code
    logger.info(`[DEV] Verification code for ${phone}: ${code}`);

    return { code }; // In production, don't return the code
  }

  /**
   * Verify code and login/register
   */
  async loginWithCode(phone, code) {
    // Verify code
    const result = await query(
      `SELECT id, code, expires_at, is_used 
       FROM verification_codes 
       WHERE phone = $1 AND purpose = 'login' AND is_used = FALSE
       ORDER BY created_at DESC 
       LIMIT 1`,
      [phone]
    );

    if (result.rows.length === 0) {
      throw new AuthenticationError('请先获取验证码');
    }

    const record = result.rows[0];

    if (new Date() > record.expires_at) {
      throw new AuthenticationError('验证码已过期，请重新获取');
    }

    if (record.code !== code) {
      throw new AuthenticationError('验证码错误');
    }

    // Mark code as used
    await query('UPDATE verification_codes SET is_used = TRUE, used_at = NOW() WHERE id = $1', [record.id]);

    // Find or create user
    let user = await this.findUserByPhone(phone);
    let isNewUser = false;

    if (!user) {
      user = await this.createUser(phone);
      isNewUser = true;
    }

    // Update last login
    await query('UPDATE users SET last_login_at = NOW() WHERE id = $1', [user.id]);

    // Generate tokens
    const tokens = this.generateTokens(user);

    return {
      user: this.sanitizeUser(user),
      tokens,
      isNewUser,
    };
  }

  /**
   * Find user by phone
   */
  async findUserByPhone(phone) {
    const result = await query(
      'SELECT * FROM users WHERE phone = $1 AND deleted_at IS NULL',
      [phone]
    );
    return result.rows[0] || null;
  }

  /**
   * Create a new user
   */
  async createUser(phone) {
    const result = await query(
      `INSERT INTO users (phone, name) VALUES ($1, $2) RETURNING *`,
      [phone, `用户${phone.slice(-4)}`]
    );
    return result.rows[0];
  }

  /**
   * Generate JWT tokens
   */
  generateTokens(user) {
    const accessToken = jwt.sign(
      {
        sub: user.id,
        phone: user.phone,
      },
      config.jwt.secret,
      { expiresIn: config.jwt.accessExpiresIn }
    );

    const refreshToken = crypto.randomBytes(40).toString('hex');
    const refreshTokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
    const refreshExpiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    // Store refresh token
    query(
      `INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
       VALUES ($1, $2, $3)`,
      [user.id, refreshTokenHash, refreshExpiresAt]
    ).catch((err) => logger.error('Failed to store refresh token', { error: err.message }));

    return {
      accessToken,
      refreshToken,
      expiresIn: 900, // 15 minutes in seconds
    };
  }

  /**
   * Refresh access token
   */
  async refreshAccessToken(refreshToken) {
    const tokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');

    const result = await query(
      `SELECT rt.id, rt.user_id, u.phone, u.name
       FROM refresh_tokens rt
       JOIN users u ON u.id = rt.user_id
       WHERE rt.token_hash = $1 
         AND rt.is_revoked = FALSE 
         AND rt.expires_at > NOW()
         AND u.deleted_at IS NULL`,
      [tokenHash]
    );

    if (result.rows.length === 0) {
      throw new AuthenticationError('刷新令牌无效或已过期');
    }

    const record = result.rows[0];

    // Revoke old refresh token
    await query('UPDATE refresh_tokens SET is_revoked = TRUE WHERE id = $1', [record.id]);

    // Generate new tokens
    const user = { id: record.user_id, phone: record.phone, name: record.name };
    return this.generateTokens(user);
  }

  /**
   * Revoke all refresh tokens for a user
   */
  async revokeAllTokens(userId) {
    await query(
      'UPDATE refresh_tokens SET is_revoked = TRUE WHERE user_id = $1',
      [userId]
    );
  }

  /**
   * Remove sensitive fields from user object
   */
  sanitizeUser(user) {
    const { password_hash, deleted_at, ...safeUser } = user;
    return safeUser;
  }
}

module.exports = new AuthService();
