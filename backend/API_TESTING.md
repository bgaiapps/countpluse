# Test the Countpluse Backend API

This file contains example API requests to test all endpoints.

## 1. Health Check

```bash
curl -X GET http://localhost:5001/health
```

Expected Response:
```json
{
  "status": "OK",
  "message": "Countpluse backend is running"
}
```

---

## 2. Register User

```bash
curl -X POST http://localhost:5001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890"
  }'
```

Expected Response (201):
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

---

## 3. Verify OTP

Copy the OTP from the email, then:

```bash
curl -X POST http://localhost:5001/api/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "otp": "1234"
  }'
```

Expected Response (200):
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

---

## 4. Login

```bash
curl -X POST http://localhost:5001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com"
  }'
```

Expected Response (200):
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

---

## 5. Get User Profile (Protected)

Use the token from verify response:

```bash
curl -X GET http://localhost:5001/api/auth/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

Expected Response (200):
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

---

## Using Postman or Insomnia

### Setup Collections

1. **Import the following URLs into Postman/Insomnia:**
   - POST `http://localhost:5001/api/auth/register`
   - POST `http://localhost:5001/api/auth/verify-otp`
   - POST `http://localhost:5001/api/auth/login`
   - GET `http://localhost:5001/api/auth/me`

2. **For authenticated requests:**
   - Go to "Auth" or "Headers" tab
   - Add header: `Authorization: Bearer {token}`

3. **Store token in environment variable:**
   - After successful login/verify, save the token to an environment variable
   - Use `{{token}}` in subsequent requests

---

## Error Cases

### Missing Required Fields
```bash
curl -X POST http://localhost:5001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com"
  }'
```

Response (400):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "phone",
      "message": "Phone is required"
    }
  ]
}
```

### Invalid Email
```bash
curl -X POST http://localhost:5001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "invalid-email",
    "phone": "+1234567890"
  }'
```

Response (400):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format"
    }
  ]
}
```

### Email Already Registered
```json
{
  "success": false,
  "message": "Email already registered"
}
```

### Invalid Token
```json
{
  "success": false,
  "message": "Invalid or expired verification token"
}
```

### User Not Verified
```json
{
  "success": false,
  "message": "Email not verified. Please check your email for verification link."
}
```

### Unauthorized Access
```json
{
  "success": false,
  "message": "No token provided"
}
```

---

## Tips

- **Always check email inbox** for verification links during testing
- **Save JWT tokens** from responses for testing protected endpoints
- **Use .env file** to avoid hardcoding configuration
- **Check MongoDB** to verify user data is being stored correctly:
  ```bash
  mongosh
  use countpluse
  db.users.find().pretty()
  ```
