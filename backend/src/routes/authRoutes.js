const express = require('express');
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');
const {
  validateRegister,
  validateLogin,
  validateVerifyOtp,
  handleValidationErrors,
} = require('../validation/authValidation');

const router = express.Router();

// Routes
router.post('/register', validateRegister, handleValidationErrors, authController.register);
router.get('/verify/:token', authController.verifyEmail);
router.post('/login', validateLogin, handleValidationErrors, authController.login);
router.post('/verify-otp', validateVerifyOtp, handleValidationErrors, authController.verifyOtp);
router.get('/me', authMiddleware, authController.getProfile);

module.exports = router;
