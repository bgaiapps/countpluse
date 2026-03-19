const test = require('node:test');
const assert = require('node:assert/strict');

const User = require('../src/models/User');
const {
  validateRegister,
  validateLogin,
  validateVerifyOtp,
  collectValidationErrors,
} = require('../src/validation/authValidation');

const runValidation = async (chains, body) => {
  const req = { body };
  for (const chain of chains) {
    await chain.run(req);
  }
  return collectValidationErrors(req);
};

test('user schema accepts plus-address emails', () => {
  const user = new User({
    name: 'Braj',
    email: 'brajtapapp+11@gmail.com',
    phone: '1234567890',
  });

  const validationError = user.validateSync();
  assert.equal(validationError, undefined);
});

test('register validation rejects malformed email', async () => {
  const errors = await runValidation(validateRegister, {
    name: 'Braj',
    email: 'not-an-email',
    phone: '1234567890',
  });

  assert.ok(errors.some(error => error.field === 'email'));
});

test('register validation accepts plus email format', async () => {
  const errors = await runValidation(validateRegister, {
    name: 'Braj',
    email: 'brajtapapp+11@gmail.com',
    phone: '',
  });

  assert.ok(errors.some(error => error.field === 'phone'));
  assert.ok(!errors.some(error => error.field === 'email'));
});

test('login validation rejects malformed email', async () => {
  const errors = await runValidation(validateLogin, {
    email: 'invalid-email',
  });

  assert.ok(errors.some(error => error.field === 'email'));
});

test('verify-otp validation rejects malformed otp', async () => {
  const errors = await runValidation(validateVerifyOtp, {
    email: 'braj@example.com',
    otp: '12',
  });

  assert.ok(errors.some(error => error.field === 'otp'));
});
