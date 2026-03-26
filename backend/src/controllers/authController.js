const User = require('../models/User');
const {
  generateOtpCode,
  generateJWT,
  hashOtpCode,
} = require('../utils/tokenGenerator');
const { sendOtpEmail } = require('../utils/emailService');
const env = require('../config/env');

const normalizeEmail = value =>
  typeof value === 'string' ? value.trim().toLowerCase() : '';
const normalizeText = value => (typeof value === 'string' ? value.trim() : '');
const normalizeOtp = value =>
  typeof value === 'string' ? value.replace(/\s+/g, '').trim() : '';
const errorBody = (message, error) => ({
  success: false,
  message,
  error: !env.isProduction && error ? error.message : undefined,
});
const otpCooldownMessage = cooldownSeconds =>
  `OTP already sent. Please wait ${cooldownSeconds} seconds before requesting a new code.`;
const isOtpExpired = user =>
  !user?.verificationTokenExpires ||
  user.verificationTokenExpires.getTime() <= Date.now();
const getOtpCooldownSeconds = user => {
  if (!user?.otpLastSentAt) return 0;
  const elapsedMs = Date.now() - user.otpLastSentAt.getTime();
  const remainingMs = env.otpResendCooldownSeconds * 1000 - elapsedMs;
  return remainingMs > 0 ? Math.ceil(remainingMs / 1000) : 0;
};
const assignOtp = (user, otpCode) => {
  user.verificationToken = hashOtpCode(otpCode);
  user.verificationTokenExpires = new Date(
    Date.now() + env.otpExpireMinutes * 60 * 1000
  );
  user.otpAttemptCount = 0;
  user.otpLastSentAt = new Date();
};
const clearOtp = user => {
  user.verificationToken = null;
  user.verificationTokenExpires = null;
  user.otpAttemptCount = 0;
};
const matchesStoredOtp = (storedValue, enteredOtp) => {
  if (!storedValue || !enteredOtp) return false;
  const hashedOtp = hashOtpCode(enteredOtp);
  return storedValue === hashedOtp || storedValue === enteredOtp;
};
const sendOtpSuccess = (res, statusCode, message, user) =>
  res.status(statusCode).json({
    success: true,
    message,
    data: {
      userId: user._id,
      email: user.email,
      name: user.name,
      phone: user.phone,
    },
  });
const sendOtpFailure = async (res, user, emailError, rollback) => {
  await rollback();
  return res.status(500).json({
    success: false,
    message: 'Failed to send verification email. Please try again.',
    error: !env.isProduction ? emailError.message : undefined,
  });
};
const rejectIfOtpCooldownActive = (res, user) => {
  const cooldownSeconds = getOtpCooldownSeconds(user);
  if (!isOtpExpired(user) && cooldownSeconds > 0) {
    res.status(429).json({
      success: false,
      message: otpCooldownMessage(cooldownSeconds),
    });
    return true;
  }
  return false;
};

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
const register = async (req, res) => {
  try {
    const { name, email, phone } = req.body;
    const normalizedEmail = normalizeEmail(email);
    const normalizedName = normalizeText(name);
    const normalizedPhone = normalizeText(phone);

    // Validation
    if (!normalizedName || !normalizedEmail || !normalizedPhone) {
      return res.status(400).json({
        success: false,
        message: 'Please provide all required fields: name, email, phone',
      });
    }

    // Check if user already exists
    let user = await User.findOne({ email: normalizedEmail });
    if (user && user.isVerified) {
      return res.status(400).json({
        success: false,
        message: 'Email already registered',
      });
    }

    // Generate OTP (10 minutes by default)
    const otpCode = generateOtpCode();

    const isExistingUnverified = Boolean(user && !user.isVerified);
    if (isExistingUnverified) {
      if (rejectIfOtpCooldownActive(res, user)) {
        return;
      }
      user.name = normalizedName;
      user.phone = normalizedPhone;
      assignOtp(user, otpCode);
      await user.save();
    } else {
      user = await User.create({
        name: normalizedName,
        email: normalizedEmail,
        phone: normalizedPhone,
        isVerified: false,
      });
      assignOtp(user, otpCode);
      await user.save();
    }

    // Send OTP email
    try {
      await sendOtpEmail(user, otpCode);
    } catch (emailError) {
      return sendOtpFailure(
        res,
        user,
        emailError,
        async () => {
          if (isExistingUnverified) {
            clearOtp(user);
            await user.save();
          } else {
            await User.deleteOne({ _id: user._id });
          }
        }
      );
    }

    return sendOtpSuccess(
      res,
      201,
      'OTP sent to your email. Please verify to continue.',
      user
    );
  } catch (error) {
    console.error('Register error:', error);
    return res.status(500).json(errorBody('Error registering user', error));
  }
};

// @desc    Login user (for verified accounts)
// @route   POST /api/auth/login
// @access  Public
const login = async (req, res) => {
  try {
    const { email } = req.body;
    const normalizedEmail = normalizeEmail(email);

    if (!normalizedEmail) {
      return res.status(400).json({
        success: false,
        message: 'Please provide an email',
      });
    }

    // Find user
    const user = await User.findOne({ email: normalizedEmail });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found. Please register first.',
      });
    }

    // Generate OTP
    const otpCode = generateOtpCode();
    if (rejectIfOtpCooldownActive(res, user)) {
      return;
    }
    assignOtp(user, otpCode);
    await user.save();

    // Send OTP email
    await sendOtpEmail(user, otpCode);

    return sendOtpSuccess(res, 200, 'OTP sent to your email.', user);
  } catch (error) {
    console.error('Login error:', error);
    return res.status(500).json(errorBody('Error logging in', error));
  }
};

// @desc    Get user profile (protected)
// @route   GET /api/auth/me
// @access  Private
const getProfile = async (req, res) => {
  try {
    // User ID comes from JWT middleware
    const user = await User.findById(req.userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    res.status(200).json({
      success: true,
      data: {
        userId: user._id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        isVerified: user.isVerified,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json(errorBody('Error fetching profile', error));
  }
};

// @desc    Verify OTP
// @route   POST /api/auth/verify-otp
// @access  Public
const verifyOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;
    const normalizedEmail = normalizeEmail(email);
    const normalizedOtp = normalizeOtp(otp);

    if (!normalizedEmail || !normalizedOtp) {
      return res.status(400).json({
        success: false,
        message: 'Email and OTP are required',
      });
    }
    if (!/^\d{4,6}$/.test(normalizedOtp)) {
      return res.status(400).json({
        success: false,
        message: 'OTP must be 4 to 6 digits',
      });
    }

    const user = await User.findOne({ email: normalizedEmail });

    if (!user || isOtpExpired(user) || !user.verificationToken) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired OTP',
      });
    }

    if (!matchesStoredOtp(user.verificationToken, normalizedOtp)) {
      user.otpAttemptCount = (user.otpAttemptCount || 0) + 1;
      if (user.otpAttemptCount >= env.otpMaxAttempts) {
        clearOtp(user);
        await user.save();
        return res.status(429).json({
          success: false,
          message: 'Too many invalid OTP attempts. Please request a new code.',
        });
      }
      await user.save();
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired OTP',
      });
    }

    user.isVerified = true;
    clearOtp(user);
    await user.save();

    const token = generateJWT(user._id);

    res.status(200).json({
      success: true,
      message: 'OTP verified successfully',
      data: {
        userId: user._id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        token,
      },
    });
  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json(errorBody('Error verifying OTP', error));
  }
};

module.exports = {
  register,
  login,
  getProfile,
  verifyOtp,
};
