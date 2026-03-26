const mongoose = require('mongoose');

const emailPattern =
  /^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$/;

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Please provide a name'],
      trim: true,
      maxlength: [100, 'Name cannot be more than 100 characters'],
    },
    email: {
      type: String,
      required: [true, 'Please provide an email'],
      unique: true,
      lowercase: true,
      match: [emailPattern, 'Please provide a valid email'],
    },
    phone: {
      type: String,
      required: [true, 'Please provide a phone number'],
      trim: true,
      maxlength: [20, 'Phone number cannot be more than 20 characters'],
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
    verificationToken: {
      type: String,
      default: null,
    },
    verificationTokenExpires: {
      type: Date,
      default: null,
    },
    otpAttemptCount: {
      type: Number,
      default: 0,
      min: 0,
    },
    otpLastSentAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('User', userSchema);
