const User = require('../models/User');
const { generateOtpCode, generateJWT } = require('../utils/tokenGenerator');
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
    const otpMinutes = env.otpExpireMinutes;
    const verificationTokenExpires = new Date(Date.now() + otpMinutes * 60 * 1000);

    const isExistingUnverified = Boolean(user && !user.isVerified);
    if (isExistingUnverified) {
      user.name = normalizedName;
      user.phone = normalizedPhone;
      user.verificationToken = otpCode;
      user.verificationTokenExpires = verificationTokenExpires;
      await user.save();
    } else {
      user = await User.create({
        name: normalizedName,
        email: normalizedEmail,
        phone: normalizedPhone,
        verificationToken: otpCode,
        verificationTokenExpires,
        isVerified: false,
      });
    }

    // Send OTP email
    try {
      await sendOtpEmail(user, otpCode);
    } catch (emailError) {
      if (isExistingUnverified) {
        user.verificationToken = null;
        user.verificationTokenExpires = null;
        await user.save();
      } else {
        await User.deleteOne({ _id: user._id });
      }
      return res.status(500).json({
        success: false,
        message: 'Failed to send verification email. Please try again.',
        error: !env.isProduction ? emailError.message : undefined,
      });
    }

    res.status(201).json({
      success: true,
      message: 'OTP sent to your email. Please verify to continue.',
      data: {
        userId: user._id,
        email: user.email,
        name: user.name,
        phone: user.phone,
      },
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json(errorBody('Error registering user', error));
  }
};

// @desc    Verify email with token
// @route   GET /api/auth/verify/:token
// @access  Public
const verifyEmail = async (req, res) => {
  try {
    const { token } = req.params;

    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'Verification token is required',
      });
    }

    // Find user with verification token
    const user = await User.findOne({
      verificationToken: token,
      verificationTokenExpires: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired verification token',
      });
    }

    // Mark user as verified
    user.isVerified = true;
    user.verificationToken = null;
    user.verificationTokenExpires = null;
    await user.save();

    // Generate JWT token for login
    const jwtToken = generateJWT(user._id);

    res.status(200).json({
      success: true,
      message: 'Email verified successfully!',
      data: {
        userId: user._id,
        email: user.email,
        name: user.name,
        token: jwtToken,
      },
    });
  } catch (error) {
    console.error('Verify email error:', error);
    res.status(500).json(errorBody('Error verifying email', error));
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
    const otpMinutes = env.otpExpireMinutes;
    user.verificationToken = otpCode;
    user.verificationTokenExpires = new Date(Date.now() + otpMinutes * 60 * 1000);
    await user.save();

    // Send OTP email
    await sendOtpEmail(user, otpCode);

    res.status(200).json({
      success: true,
      message: 'OTP sent to your email.',
      data: {
        userId: user._id,
        email: user.email,
        name: user.name,
        phone: user.phone,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json(errorBody('Error logging in', error));
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

    const user = await User.findOne({
      email: normalizedEmail,
      verificationToken: normalizedOtp,
      verificationTokenExpires: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired OTP',
      });
    }

    user.isVerified = true;
    user.verificationToken = null;
    user.verificationTokenExpires = null;
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
  verifyEmail,
  login,
  getProfile,
  verifyOtp,
};
