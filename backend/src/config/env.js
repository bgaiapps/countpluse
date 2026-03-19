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
  otpMaxAttempts: Math.min(
    Math.max(parseInteger(process.env.OTP_MAX_ATTEMPTS, 5), 1),
    10
  ),
  otpResendCooldownSeconds: Math.min(
    Math.max(parseInteger(process.env.OTP_RESEND_COOLDOWN_SECONDS, 30), 0),
    300
  ),
};

env.emailProvider = (process.env.EMAIL_PROVIDER || 'smtp').trim().toLowerCase();
env.emailFrom = process.env.EMAIL_FROM?.trim() || '';
env.emailService = process.env.EMAIL_SERVICE?.trim() || 'gmail';
env.emailUser = process.env.EMAIL_USER?.trim() || '';
env.emailPassword = process.env.EMAIL_PASSWORD?.trim() || '';
env.sendgridApiKey = process.env.SENDGRID_API_KEY?.trim() || '';

if (env.isProduction) {
  if (!env.emailFrom) {
    throw new Error('EMAIL_FROM must be set');
  }

  if (env.emailProvider === 'smtp') {
    if (!env.emailUser) {
      throw new Error('EMAIL_USER must be set for SMTP');
    }
    if (!env.emailPassword) {
      throw new Error('EMAIL_PASSWORD must be set for SMTP');
    }
  } else if (env.emailProvider === 'sendgrid') {
    if (!env.sendgridApiKey) {
      throw new Error('SENDGRID_API_KEY must be set for SendGrid');
    }
  } else {
    throw new Error(`Unsupported EMAIL_PROVIDER: ${env.emailProvider}`);
  }
}

module.exports = env;
