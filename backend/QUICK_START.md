# Quick Start Guide for Countpluse Backend

## 1. Prerequisites Setup

### Install Node.js & MongoDB (or MongoDB Atlas)

**macOS:**
```bash
# Using Homebrew
brew install node
brew install mongodb-community

# Start MongoDB (✓ Verified Working)
brew services start mongodb-community
```

**Windows:**
- Download Node.js from https://nodejs.org/
- Download MongoDB from https://www.mongodb.com/try/download/community

**Linux:**
```bash
# Ubuntu/Debian
sudo apt-get install nodejs npm
sudo apt-get install mongodb
sudo systemctl start mongodb
```

---

## 2. Backend Setup (5 minutes)

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your Gmail credentials and MongoDB Atlas URI
# (See README.md for Gmail setup instructions)
nano .env
```

---

## 3. Gmail Configuration

1. Go to https://myaccount.google.com/apppasswords
2. Select "Mail" and "Windows Computer"
3. Copy the 16-character password
4. Paste into `.env` as `EMAIL_PASSWORD`

---

## 4. Start the Backend

```bash
# Development mode (auto-reload on changes)
npm run dev

# Or production mode
npm start
```

You should see:
```
Server running on port 5000
Environment: development
MongoDB Connected: localhost
```

---

## 5. Test the API

Open a new terminal and test:

```bash
# Health check
curl http://localhost:5000/health

# Register user (OTP sent to email)
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "phone": "1234567890"
  }'
```

See `API_TESTING.md` for complete test examples.

---

## 6. Connect Flutter App

In your Flutter `lib/services/` directory, create `auth_service.dart`:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const String baseUrl = 'http://localhost:5000/api/auth';

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String phone,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
```

---

## 7. Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| MongoDB connection failed | Ensure MongoDB is running: `mongosh` |
| Email not sending | Check EMAIL_USER/PASSWORD in .env, verify Gmail app password |
| CORS error | Backend should allow all origins by default |
| Port already in use | Change PORT in .env or kill process: `lsof -i :5000` |
| Node modules missing | Run `npm install` in backend directory |

---

## 8. File Structure

```
backend/
├── src/
│   ├── server.js                 # Main server entry point
│   ├── config/
│   │   └── database.js          # MongoDB connection
│   ├── models/
│   │   └── User.js              # User schema
│   ├── controllers/
│   │   └── authController.js    # Auth logic
│   ├── routes/
│   │   └── authRoutes.js        # API endpoints
│   ├── middleware/
│   │   └── authMiddleware.js    # JWT verification
│   └── utils/
│       ├── emailService.js      # Nodemailer config
│       └── tokenGenerator.js    # JWT & token utilities
├── package.json
├── .env.example
├── .gitignore
├── README.md
├── API_TESTING.md
└── QUICK_START.md              # This file
```

---

## 9. API Summary

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/auth/register` | Register new user |
| GET | `/api/auth/verify/:token` | Verify email with token |
| POST | `/api/auth/login` | Login verified user |
| GET | `/api/auth/me` | Get user profile (protected) |

---

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
