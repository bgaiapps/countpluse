const express = require('express');
const { body, query, validationResult } = require('express-validator');
const countController = require('../controllers/countController');
const authMiddleware = require('../middleware/authMiddleware');
const router = express.Router();
const allowDevAuthBypass =
  process.env.NODE_ENV !== 'production' &&
  process.env.ENABLE_DEV_AUTH_BYPASS === 'true';

const devUserMiddleware = async (req, res, next) => {
  if (!allowDevAuthBypass) {
    return authMiddleware(req, res, next);
  }

  const authHeader = req.headers.authorization;
  if (authHeader) {
    return authMiddleware(req, res, next);
  }

  const userId = req.headers['x-user-id'] || req.query.userId || req.body.userId;
  if (userId) {
    req.userId = userId;
    return next();
  }
  return res.status(401).json({
    success: false,
    message: 'Authentication required',
  });
};

router.use(devUserMiddleware);

const validateUpsert = [
  body('count')
    .notEmpty()
    .withMessage('Count is required')
    .isInt({ min: 0 })
    .withMessage('Count must be a non-negative integer'),
  body('date')
    .optional()
    .isISO8601()
    .withMessage('Date must be a valid ISO-8601 string'),
  body('targetLabel')
    .optional()
    .isString()
    .withMessage('Target label must be a string')
    .isLength({ max: 100 })
    .withMessage('Target label must be less than 100 characters'),
];

const validateHistoryQuery = [
  query('from')
    .optional()
    .isISO8601()
    .withMessage('From date must be a valid ISO-8601 string'),
  query('to')
    .optional()
    .isISO8601()
    .withMessage('To date must be a valid ISO-8601 string'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 366 })
    .withMessage('Limit must be between 1 and 366'),
];

const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map(e => ({ field: e.path || e.param, message: e.msg })),
    });
  }
  next();
};

router.post('/', validateUpsert, handleValidationErrors, countController.upsertCount);
router.get('/latest', countController.getLatestCount);
router.get('/', validateHistoryQuery, handleValidationErrors, countController.getCountHistory);

module.exports = router;
