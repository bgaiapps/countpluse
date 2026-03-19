# Countpluse Backend API

Backend server for Countpluse user registration, OTP-based authentication, and
count history APIs.

## Features

- User registration with name, email, and phone number
- Email OTP verification
- JWT-based authentication
- Protected endpoint for user profile
- MongoDB Atlas for user storage
- SMTP or SendGrid for email delivery
- Input validation and error handling
- Count history APIs for authenticated users

## Prerequisites

- Node.js (v14 or higher)
- MongoDB Atlas
- SMTP credentials or SendGrid account

## Installation

1. **Install dependencies:**
   ```bash
   cd backend
   npm install
   ```

2. **Configure environment (Render or any Node host):**
   ```
   PORT=5051
   MONGODB_URI=mongodb+srv://<user>:<pass>@<cluster>.mongodb.net/countpluse?retryWrites=true&w=majority
   JWT_SECRET=your_real_secret
   JWT_EXPIRE=7d

   # Email Configuration
   EMAIL_PROVIDER=smtp
   EMAIL_FROM=your_sender@example.com

   # SMTP example
   EMAIL_SERVICE=gmail
   EMAIL_USER=your_sender@example.com
   EMAIL_PASSWORD=your_app_password

   # Or SendGrid example
   # EMAIL_PROVIDER=sendgrid
   # SENDGRID_API_KEY=your_sendgrid_api_key

   OTP_EXPIRE_MINUTES=10
   OTP_MAX_ATTEMPTS=5
   OTP_RESEND_COOLDOWN_SECONDS=30
   CORS_ORIGIN=https://your-frontend.example.com
   NODE_ENV=production
   ```

   A tracked template is available at `backend/.env.example`.

## Running the Server

Development:

```bash
npm start
```

Checks:

```bash
npm run lint
npm test
```

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
  "message": "OTP sent to your email. Please verify to continue.",
  "data": {
    "userId": "507f1f77bcf86cd799439011",
    "email": "john@example.com",
    "name": "John Doe",
    "phone": "+1234567890"
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

### 2. Verify OTP
**Endpoint:** `POST /api/auth/verify-otp`

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "OTP verified successfully",
  "data": {
    "userId": "507f1f77bcf86cd799439011",
    "email": "john@example.com",
    "name": "John Doe",
    "phone": "+1234567890",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "message": "Invalid or expired OTP"
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
  "message": "OTP sent to your email.",
  "data": {
    "userId": "507f1f77bcf86cd799439011",
    "email": "john@example.com",
    "name": "John Doe",
    "phone": "+1234567890"
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

## User Flow

1. **User Registration**
   - User enters name, email, and phone
   - Backend creates user record (unverified)
   - OTP email sent
   - User verifies OTP

2. **User Login**
   - User enters email to login
   - OTP email sent
   - User verifies OTP

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
  otpAttemptCount: Number,
  otpLastSentAt: Date | null,
  password: String | null,
  createdAt: Date,
  updatedAt: Date
}
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `PORT` | Server port | `5051` |
| `MONGODB_URI` | MongoDB connection string | `mongodb+srv://...` |
| `JWT_SECRET` | JWT signing secret | `change_me` |
| `JWT_EXPIRE` | JWT lifetime | `7d` |
| `EMAIL_PROVIDER` | `smtp` or `sendgrid` | `smtp` |
| `EMAIL_FROM` | Sender email | `noreply@example.com` |
| `EMAIL_SERVICE` | SMTP service name | `gmail` |
| `EMAIL_USER` | SMTP username | `noreply@example.com` |
| `EMAIL_PASSWORD` | SMTP password/app password | `...` |
| `SENDGRID_API_KEY` | SendGrid API key | `SG.xxxxx` |
| `OTP_EXPIRE_MINUTES` | OTP lifetime in minutes | `10` |
| `OTP_MAX_ATTEMPTS` | Max invalid OTP attempts | `5` |
| `OTP_RESEND_COOLDOWN_SECONDS` | Cooldown before new OTP | `30` |
| `CORS_ORIGIN` | Allowed frontend origins | `https://app.example.com` |
| `JWT_SECRET` | Secret key for JWT | `your_secret_key` |
| `JWT_EXPIRE` | JWT token expiration | `7d` |
| `EMAIL_PROVIDER` | Email provider (`sendgrid` or `smtp`) | `sendgrid` |
| `SENDGRID_API_KEY` | SendGrid API key | `SG...` |
| `EMAIL_FROM` | From email address | `noreply@countpluse.com` |
| `OTP_EXPIRE_MINUTES` | OTP expiry in minutes | `10` |
| `NODE_ENV` | Environment | `production` |

## Troubleshooting

**MongoDB Connection Error:**
- Check MONGODB_URI in your host environment
- Ensure Atlas IP allowlist includes your host

**Email Not Sending:**
- Check SENDGRID_API_KEY
- Verify sender identity in SendGrid

**JWT Token Expired:**
- Update JWT_EXPIRE to increase token lifetime
- Default is 7 days

## License

MIT

## Support

For issues or questions, please create an issue in the repository.
