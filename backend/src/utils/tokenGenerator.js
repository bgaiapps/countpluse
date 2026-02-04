const crypto = require('crypto');
const jwt = require('jsonwebtoken');

// Generate a random verification token
const generateVerificationToken = () => {
  return crypto.randomBytes(32).toString('hex');
};

// Generate a 4-digit OTP code
const generateOtpCode = () => {
  return crypto.randomInt(1000, 10000).toString();
};

// Generate JWT token for authenticated sessions
const generateJWT = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET || 'your_secret_key', {
    expiresIn: process.env.JWT_EXPIRE || '7d',
  });
};

// Verify JWT token
const verifyJWT = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_SECRET || 'your_secret_key');
  } catch (error) {
    return null;
  }
};

module.exports = {
  generateVerificationToken,
  generateOtpCode,
  generateJWT,
  verifyJWT,
};
