const isProduction = process.env.NODE_ENV === 'production';

const parseInteger = (value, fallback) => {
  const parsed = Number.parseInt(value || '', 10);
  return Number.isInteger(parsed) ? parsed : fallback;
};

const getRequiredEnv = (name) => {
  const value = process.env[name];
  if (!value || !value.trim()) {
    throw new Error(`${name} must be set`);
  }
  return value.trim();
};

const env = {
  isProduction,
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInteger(process.env.PORT, 5000),
  mongoUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/countpluse',
  jwtSecret: isProduction
    ? getRequiredEnv('JWT_SECRET')
    : process.env.JWT_SECRET || 'dev_only_insecure_secret_change_me',
  jwtExpire: process.env.JWT_EXPIRE || '7d',
  corsOrigins: (process.env.CORS_ORIGIN || '')
    .split(',')
    .map(origin => origin.trim())
    .filter(Boolean),
  otpExpireMinutes: Math.min(
    Math.max(parseInteger(process.env.OTP_EXPIRE_MINUTES, 10), 1),
    30
  ),
};

module.exports = env;
