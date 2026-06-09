require('dotenv').config();

const config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT, 10) || 3000,

  db: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 5432,
    database: process.env.DB_NAME || 'smart_medication',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '',
    pool: {
      min: parseInt(process.env.DB_POOL_MIN, 10) || 2,
      max: parseInt(process.env.DB_POOL_MAX, 10) || 10,
    },
  },

  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT, 10) || 6379,
    password: process.env.REDIS_PASSWORD || '',
    db: parseInt(process.env.REDIS_DB, 10) || 0,
  },

  jwt: {
    secret: process.env.JWT_SECRET || 'dev-secret-change-in-production',
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  },

  sms: {
    accessKeyId: process.env.SMS_ACCESS_KEY_ID,
    accessKeySecret: process.env.SMS_ACCESS_KEY_SECRET,
    signName: process.env.SMS_SIGN_NAME || '智能用药',
    templateCode: process.env.SMS_TEMPLATE_CODE,
  },

  push: {
    appKey: process.env.JPUSH_APP_KEY,
    masterSecret: process.env.JPUSH_MASTER_SECRET,
  },

  ocr: {
    apiKey: process.env.OCR_API_KEY,
    apiUrl: process.env.OCR_API_URL,
  },

  log: {
    level: process.env.LOG_LEVEL || 'info',
    filePath: process.env.LOG_FILE_PATH || 'logs/app.log',
  },

  cors: {
    origin: process.env.CORS_ORIGIN || '*',
  },
};

module.exports = config;
