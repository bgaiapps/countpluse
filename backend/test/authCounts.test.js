const request = require('supertest');
const app = require('../src/app');
const User = require('../src/models/User');

jest.mock('../src/utils/emailService', () => ({
  sendVerificationEmail: jest.fn().mockResolvedValue(true),
  sendLoginLinkEmail: jest.fn().mockResolvedValue(true),
}));

describe('Auth and count data', () => {
  it('registers, verifies, logs in, and saves count data', async () => {
    const registerRes = await request(app).post('/api/auth/register').send({
      name: 'Test User',
      email: 'test@example.com',
      phone: '+15551234567',
    });

    expect(registerRes.statusCode).toBe(201);
    expect(registerRes.body.success).toBe(true);

    const user = await User.findOne({ email: 'test@example.com' });
    expect(user).toBeTruthy();

    const verifyRes = await request(app).get(`/api/auth/verify/${user.verificationToken}`);
    expect(verifyRes.statusCode).toBe(200);
    expect(verifyRes.body.data.token).toBeTruthy();

    const loginRes = await request(app).post('/api/auth/login').send({
      email: 'test@example.com',
    });

    expect(loginRes.statusCode).toBe(200);
    const token = loginRes.body.data.token;

    const saveCountRes = await request(app)
      .post('/api/counts')
      .set('Authorization', `Bearer ${token}`)
      .send({
        count: 42,
        targetLabel: 'Radha',
      });

    expect(saveCountRes.statusCode).toBe(200);
    expect(saveCountRes.body.data.count).toBe(42);

    const latestRes = await request(app).get('/api/counts/latest').set('Authorization', `Bearer ${token}`);
    expect(latestRes.statusCode).toBe(200);
    expect(latestRes.body.data.count).toBe(42);

    const historyRes = await request(app)
      .get('/api/counts?limit=7')
      .set('Authorization', `Bearer ${token}`);

    expect(historyRes.statusCode).toBe(200);
    expect(historyRes.body.data.length).toBeGreaterThan(0);
  });

  it('validates register payload', async () => {
    const res = await request(app).post('/api/auth/register').send({
      name: 'Test User',
      phone: '+15551234567',
    });

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('returns error for invalid verification token', async () => {
    const res = await request(app).get('/api/auth/verify/bad-token');

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('validates login payload', async () => {
    const res = await request(app).post('/api/auth/login').send({});

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('requires auth for profile', async () => {
    const res = await request(app).get('/api/auth/me');

    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('returns profile for authenticated user', async () => {
    await request(app).post('/api/auth/register').send({
      name: 'Profile User',
      email: 'profile@example.com',
      phone: '+15551230000',
    });

    const user = await User.findOne({ email: 'profile@example.com' });
    const verifyRes = await request(app).get(`/api/auth/verify/${user.verificationToken}`);
    const token = verifyRes.body.data.token;

    const meRes = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${token}`);

    expect(meRes.statusCode).toBe(200);
    expect(meRes.body.data.email).toBe('profile@example.com');
  });
});
