const { body, validationResult } = require('express-validator');

const validateRegister = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ max: 100 })
    .withMessage('Name must be less than 100 characters'),
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Invalid email format'),
  body('phone')
    .trim()
    .notEmpty()
    .withMessage('Phone is required')
    .isLength({ min: 7, max: 20 })
    .withMessage('Phone must be between 7 and 20 characters'),
];

const validateLogin = [
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Invalid email format'),
];

const validateVerifyOtp = [
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Invalid email format'),
  body('otp')
    .trim()
    .notEmpty()
    .withMessage('OTP is required')
    .isLength({ min: 4, max: 6 })
    .withMessage('OTP must be 4-6 digits'),
];

const collectValidationErrors = (req) => {
  const errors = validationResult(req);
  if (errors.isEmpty()) {
    return [];
  }
  return errors.array().map(e => ({
    field: e.path || e.param,
    message: e.msg,
  }));
};

const handleValidationErrors = (req, res, next) => {
  const errors = collectValidationErrors(req);
  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors,
    });
  }
  next();
};

module.exports = {
  validateRegister,
  validateLogin,
  validateVerifyOtp,
  collectValidationErrors,
  handleValidationErrors,
};
