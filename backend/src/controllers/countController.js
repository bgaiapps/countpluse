const CountRecord = require('../models/CountRecord');

const normalizeDateKey = (value) => {
  const date = value ? new Date(value) : new Date();
  if (Number.isNaN(date.getTime())) {
    return null;
  }
  return date.toISOString().slice(0, 10);
};

// @desc    Create or update a user's count for a date
// @route   POST /api/counts
// @access  Private
const upsertCount = async (req, res) => {
  try {
    const dateKey = normalizeDateKey(req.body.date);
    if (!dateKey) {
      return res.status(400).json({
        success: false,
        message: 'Invalid date format',
      });
    }

    const update = {
      userId: req.userId,
      date: dateKey,
      count: req.body.count,
    };

    if (typeof req.body.targetLabel === 'string') {
      update.targetLabel = req.body.targetLabel.trim();
    }

    const record = await CountRecord.findOneAndUpdate(
      { userId: req.userId, date: dateKey },
      { $set: update },
      { new: true, upsert: true, setDefaultsOnInsert: true }
    ).lean();

    return res.status(200).json({
      success: true,
      message: 'Count saved',
      data: record,
    });
  } catch (error) {
    console.error('Upsert count error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error saving count data',
      error: error.message,
    });
  }
};

// @desc    Get latest count for the user
// @route   GET /api/counts/latest
// @access  Private
const getLatestCount = async (req, res) => {
  try {
    const record = await CountRecord.findOne({ userId: req.userId }).sort({ date: -1 }).lean();

    if (!record) {
      return res.status(404).json({
        success: false,
        message: 'No count data found',
      });
    }

    return res.status(200).json({
      success: true,
      data: record,
    });
  } catch (error) {
    console.error('Get latest count error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error fetching count data',
      error: error.message,
    });
  }
};

// @desc    Get count history for the user
// @route   GET /api/counts
// @access  Private
const getCountHistory = async (req, res) => {
  try {
    const { from, to, limit } = req.query;
    const query = { userId: req.userId };

    if (from || to) {
      const fromKey = from ? normalizeDateKey(from) : null;
      const toKey = to ? normalizeDateKey(to) : null;

      if ((from && !fromKey) || (to && !toKey)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid date range',
        });
      }

      query.date = {};
      if (fromKey) query.date.$gte = fromKey;
      if (toKey) query.date.$lte = toKey;
    }

    const limitValue = limit ? Math.min(parseInt(limit, 10), 366) : 30;

    const records = await CountRecord.find(query).sort({ date: -1 }).limit(limitValue).lean();

    return res.status(200).json({
      success: true,
      data: records,
    });
  } catch (error) {
    console.error('Get count history error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error fetching count history',
      error: error.message,
    });
  }
};

module.exports = {
  upsertCount,
  getLatestCount,
  getCountHistory,
};
