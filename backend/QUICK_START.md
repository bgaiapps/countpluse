# Quick Start Guide for Countpluse Backend

## 1. Prerequisites Setup

### Install Node.js

- Download Node.js from https://nodejs.org/

---

## 2. Backend Setup (5 minutes)

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Set Render environment variables (see README.md)
```

---

## 3. Start the Backend (Production)

```bash
npm start
```
---

## 4. API Summary

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/auth/register` | Register new user (OTP) |
| POST | `/api/auth/verify-otp` | Verify OTP |
| POST | `/api/auth/login` | Login (OTP) |
| GET | `/api/auth/me` | Get user profile (protected) |

## 10. Next Steps

1. ✅ Backend running on port 5000
2. ✅ Database setup complete
3. ✅ Email verification configured
4. Next: Connect Flutter app to backend
   - Update baseUrl in auth_service.dart if needed
   - Add http package to pubspec.yaml
   - Create registration & login screens

---

## 11. Production Deployment

When deploying to production:

1. **Update environment variables:**
   - Change `NODE_ENV=production`
   - Use MongoDB Atlas or managed database
   - Use real domain for `FRONTEND_URL`
   - Generate strong `JWT_SECRET`

2. **Security checklist:**
   - ✅ Never commit .env file
   - ✅ Use environment variables for sensitive data
   - ✅ Enable HTTPS
   - ✅ Add rate limiting
   - ✅ Validate all inputs

3. **Hosting options:**
   - Heroku
   - AWS (EC2, ECS)
   - DigitalOcean
   - Railway
   - Render

---

Need help? Check `README.md` for detailed documentation.
