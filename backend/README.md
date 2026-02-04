# Countpluse Backend API

Backend server for Countpluse user registration, email verification, and authentication system.

## Features

- User registration with name, email, and phone number
- Email verification via secure token
- JWT-based authentication
- Protected endpoints for user profile
- MongoDB database for user storage
- Nodemailer for email delivery
- Input validation and error handling

## Prerequisites

- Node.js (v14 or higher)
- MongoDB (local or cloud instance)
- Gmail account with app-specific password (for email sending)

## Installation

1. **Clone or navigate to the backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Create .env file:**
   ```bash
   cp .env.example .env
   ```

4. **Configure .env file:**
   ```
   PORT=5000
   MONGODB_URI=mongodb://localhost:27017/countpluse
   JWT_SECRET=your_super_secret_key_change_this
   JWT_EXPIRE=7d
   
   # Email Configuration (Gmail)
   EMAIL_PROVIDER=sendgrid
   SENDGRID_API_KEY=your_sendgrid_api_key
   EMAIL_FROM=noreply@countpluse.com
   
   FRONTEND_URL=http://localhost:3000
   NODE_ENV=development
   ```

### Setting up Gmail for Email Sending

1. Enable 2-factor authentication on your Gmail account
2. Generate an App Password: https://myaccount.google.com/apppasswords
3. Select "Mail" and "Windows Computer" (or your device)
4. Copy the SendGrid API key to `SENDGRID_API_KEY` in `.env`

### MongoDB Setup

**Option 1: Local MongoDB**
```bash
# Install MongoDB locally
# Start MongoDB service
mongod
```

**Option 2: MongoDB Atlas (Cloud)**
```
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/countpluse?retryWrites=true&w=majority
```

## Running the Server

**Development (with auto-reload):**
```bash
npm run dev
```

**Production:**
```bash
npm start
```

Server will run on `http://localhost:5000` by default.

## Seeding Test Data (10 Users + 1 Year of Counts)

```bash
npm run seed
```

This seeds 10 demo users and daily count records for the past year. The script prints usable demo user IDs.

## Dev-Only Public Counts

When `NODE_ENV` is not `production`, `/api/counts` accepts a `userId` query parameter (or `x-user-id` header) without auth for local testing.

## API Endpoints

### 1. Register User
**Endpoint:** `POST /api/auth/register`

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890"
}
```

**Response (Success - 201):**
```json
{
  "success": true,
  "message": "User registered successfully. Please check your email to verify your account.",
  "data": {
    "userId": "507f1f77bcf86cd799439011",
    "email": "john@example.com",
    "name": "John Doe"
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "message": "Email already registered"
}
```

---

### 2. Verify Email
**Endpoint:** `GET /api/auth/verify/:token`

**URL:** `http://localhost:5000/api/auth/verify/abc123def456...`

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Email verified successfully!",
  "data": {
    "userId": "507f1f77bcf86cd799439011",
    "email": "john@example.com",
    "name": "John Doe",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "message": "Invalid or expired verification token"
}
```

---

### 3. Login User
**Endpoint:** `POST /api/auth/login`

**Request Body:**
```json
{
  "email": "john@example.com"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "userId": "507f1f77bcf86cd799439011",
    "email": "john@example.com",
    "name": "John Doe",
    "phone": "+1234567890",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Response (Error - 404):**
```json
{
  "success": false,
  "message": "User not found. Please register first."
}
```

**Response (Error - 403):**
```json
{
  "success": false,
  "message": "Email not verified. Please check your email for verification link."
}
```

---

### 4. Get User Profile (Protected)
**Endpoint:** `GET /api/auth/me`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "userId": "507f1f77bcf86cd799439011",
    "email": "john@example.com",
    "name": "John Doe",
    "phone": "+1234567890",
    "isVerified": true,
    "createdAt": "2026-02-03T10:00:00.000Z"
  }
}
```

**Response (Error - 401):**
```json
{
  "success": false,
  "message": "No token provided"
}
```

---

### 5. Save User Count (Protected)
**Endpoint:** `POST /api/counts`

**Request Body:**
```json
{
  "count": 42,
  "date": "2026-02-04",
  "targetLabel": "Radha"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Count saved",
  "data": {
    "userId": "507f1f77bcf86cd799439011",
    "date": "2026-02-04",
    "count": 42,
    "targetLabel": "Radha"
  }
}
```

---

### 6. Get Latest Count (Protected)
**Endpoint:** `GET /api/counts/latest`

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "userId": "507f1f77bcf86cd799439011",
    "date": "2026-02-04",
    "count": 42,
    "targetLabel": "Radha"
  }
}
```

---

### 7. Get Count History (Protected)
**Endpoint:** `GET /api/counts`

**Query Parameters (optional):**
```
from=2026-02-01&to=2026-02-04&limit=30
```

**Response (Success - 200):**
```json
{
  "success": true,
  "data": [
    {
      "userId": "507f1f77bcf86cd799439011",
      "date": "2026-02-04",
      "count": 42,
      "targetLabel": "Radha"
    }
  ]
}
```

---

## Integration with Flutter App

In your Flutter app, create a service to call these endpoints:

```dart
// Example: lib/services/auth_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const String baseUrl = 'http://localhost:5000/api/auth';

  static Future<bool> register(String name, String email, String phone) async {
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
      return response.statusCode == 201;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> login(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'];
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }
}
```

## User Flow

1. **User Registration**
   - User enters name, email, and phone
   - Backend creates user record (unverified)
   - Verification email sent with token link
   - Token valid for 24 hours

2. **Email Verification**
   - User clicks link in email: `{FRONTEND_URL}/verify?token={TOKEN}`
   - Frontend calls `/api/auth/verify/{TOKEN}`
   - Backend verifies token and marks user as verified
   - JWT token returned for immediate login

3. **User Login**
   - User enters email to login
   - Backend checks if email is verified
   - JWT token issued for authenticated requests

## Database Schema

**User Collection:**
```javascript
{
  _id: ObjectId,
  name: String,
  email: String (unique),
  phone: String,
  isVerified: Boolean,
  verificationToken: String | null,
  verificationTokenExpires: Date | null,
  password: String | null,
  createdAt: Date,
  updatedAt: Date
}
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `PORT` | Server port | `5000` |
| `MONGODB_URI` | MongoDB connection string | `mongodb://localhost:27017/countpluse` |
| `JWT_SECRET` | Secret key for JWT | `your_secret_key` |
| `JWT_EXPIRE` | JWT token expiration | `7d` |
| `EMAIL_PROVIDER` | Email provider (`sendgrid` or `smtp`) | `sendgrid` |
| `SENDGRID_API_KEY` | SendGrid API key | `SG...` |
| `EMAIL_FROM` | From email address | `noreply@countpluse.com` |
| `FRONTEND_URL` | Frontend base URL | `http://localhost:3000` |
| `NODE_ENV` | Environment | `development` or `production` |

## Troubleshooting

**MongoDB Connection Error:**
- Ensure MongoDB is running
- Check MONGODB_URI in .env
- Verify MongoDB credentials if using Atlas

**Email Not Sending:**
- Check SENDGRID_API_KEY
- Verify Gmail app password (not regular password)
- Ensure "Less secure apps" is enabled (if not using app password)

**CORS Issues:**
- Update FRONTEND_URL in .env
- Check CORS configuration in server.js

**JWT Token Expired:**
- Update JWT_EXPIRE to increase token lifetime
- Default is 7 days

## License

MIT

## Support

For issues or questions, please create an issue in the repository.
