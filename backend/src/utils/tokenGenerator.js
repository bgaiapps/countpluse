const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const env = require('../config/env');

// Generate a random verification token
const generateVerificationToken = () => {
  return crypto.randomBytes(32).toString('hex');
};

// Generate a 4-digit OTP code
const generateOtpCode = () => {
  return crypto.randomInt(1000, 10000).toString();
};

const hashOtpCode = (otpCode) => {
  return crypto.createHash('sha256').update(String(otpCode)).digest('hex');
};

// Generate JWT token for authenticated sessions
const generateJWT = (userId) => {
  return jwt.sign({ userId }, env.jwtSecret, {
    expiresIn: env.jwtExpire,
  });
};

// Verify JWT token
const verifyJWT = (token) => {
  try {
    return jwt.verify(token, env.jwtSecret);
  } catch {
    return null;
  }
};

module.exports = {
  generateVerificationToken,
  generateOtpCode,
  hashOtpCode,
  generateJWT,
  verifyJWT,
};
