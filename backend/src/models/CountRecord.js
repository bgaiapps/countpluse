const mongoose = require('mongoose');

const countRecordSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    date: {
      type: String,
      required: true,
    },
    count: {
      type: Number,
      required: true,
      min: 0,
    },
    targetLabel: {
      type: String,
      trim: true,
      maxlength: 100,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

countRecordSchema.index({ userId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('CountRecord', countRecordSchema);
