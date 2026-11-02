# Authentication System Documentation

## Overview

The EasyEats backend now includes a complete user authentication system with the following features:
- User registration with email and password
- Secure password hashing using Node.js crypto module
- User login
- Profile management (storing nutrition goals, age, sex, calorie targets)

## Database

User data is stored in a JSON file at `Backend/data/users.json`. This file is automatically created when the server starts.

### User Schema
```json
{
  "id": 1,
  "email": "user@example.com",
  "password_hash": "salt:hash",
  "created_at": "2025-11-24T03:20:00.000Z",
  "goal": "Losing weight",
  "age": 25,
  "sex": "Male",
  "calories": 2000,
  "updated_at": "2025-11-24T03:25:00.000Z"
}
```

## Starting the Server

```bash
cd Backend
node server.js
```

The server will start on `http://localhost:3000`

## API Endpoints

### 1. Register New User
**POST** `/api/auth/register`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (Success - 201):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "message": "User registered successfully"
}
```

**Response (Error - 400):**
```json
{
  "error": "Email already exists"
}
```

### 2. Login User
**POST** `/api/auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (Success - 200):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "goal": "Losing weight",
  "age": 25,
  "sex": "Male",
  "calories": 2000,
  "token": "9f2c...e81a",
  "message": "Login successful"
}
```

Register also returns a `token`, so a new user is signed in straight away.

## Session tokens

Every route under `/api/user/:userId/...` and `/api/recommendations/:userId`
needs the token from login or register in this header:

```
Authorization: Bearer <token>
```

| Response | When |
|---|---|
| `401` `Not signed in` | No `Authorization` header |
| `401` `Session expired. Please sign in again.` | Token is unknown, expired (7 days) or was logged out |
| `403` `You can only access your own account` | Token belongs to a different user than `:userId` in the URL |

How it works:
- The token is 32 random bytes (`crypto.randomBytes`). Only its SHA-256 hash is
  saved in `users.json` (under each user's `sessions`), so the file alone can't
  be used to sign in.
- `requireAuth` in `server.js` checks the token before the route runs.
  It is mounted on `/api/user/:userId`, so new routes under that path are
  protected automatically.
- **Logout** (`POST /api/auth/logout`, with the header) deletes that token.
- **Changing your password** keeps the current device signed in and ends every
  other session.

Menu routes (`/api/dining-halls`, `/api/meal-plan`, `/health`) stay public.

In the app, `lib/services/api_client.dart` adds the header to every per-user
request, and sends the user back to sign-in if the server replies `401`.

**Response (Error - 401):**
```json
{
  "error": "Invalid email or password"
}
```

### 3. Update User Profile
**PUT** `/api/user/:userId/profile`

**Request Body:**
```json
{
  "goal": "Losing weight",
  "age": 25,
  "sex": "Male",
  "calories": 2000
}
```

**Response (Success - 200):**
```json
{
  "message": "Profile updated successfully",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "goal": "Losing weight",
    "age": 25,
    "sex": "Male",
    "calories": 2000
  }
}
```

### 4. Get User Profile
**GET** `/api/user/:userId/profile`

**Response (Success - 200):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "goal": "Losing weight",
  "age": 25,
  "sex": "Male",
  "calories": 2000,
  "created_at": "2025-11-24T03:20:00.000Z"
}
```

## Testing with cURL

### Register a new user:
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### Login:
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```
Copy the `token` from the response:
```bash
TOKEN=paste-token-here
```

### Update profile:
```bash
curl -X PUT http://localhost:3000/api/user/1/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"goal":"Losing weight","age":25,"sex":"Male","calories":2000}'
```

### Get profile:
```bash
curl http://localhost:3000/api/user/1/profile -H "Authorization: Bearer $TOKEN"
```
Without the header this returns `401`. With another user's id it returns `403`.

### Log out:
```bash
curl -X POST http://localhost:3000/api/auth/logout -H "Authorization: Bearer $TOKEN"
```

## Flutter Integration

The Flutter app includes an `AuthService` class at `Frontend/flutter_easyeats/lib/services/auth_service.dart` that handles all API communication.

### Important Configuration

If testing on a physical device, update the `baseUrl` in `auth_service.dart`:
```dart
// Replace localhost with your computer's IP address
static const String baseUrl = 'http://192.168.1.XXX:3000/api';
```

For Android emulator, use:
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

## Security Features

- Passwords are hashed using PBKDF2 with SHA-512
- Each password uses a unique random salt
- Passwords are never stored in plain text
- Email validation on registration
- Minimum password length of 6 characters
- Random session tokens (stored hashed, expire after 7 days) checked on every per-user route
- Users can only read or change their own data (`403` otherwise)
- Logout and password change end sessions on the server

## File Structure

```
Backend/
├── server.js           # Main server with all API endpoints
├── auth.js            # Authentication logic and user management
├── data/
│   └── users.json     # User database (auto-created)
└── AUTH_README.md     # This file
```

## Error Handling

The API returns appropriate HTTP status codes:
- `200` - Success (login, get profile, update profile)
- `201` - Created (registration)
- `400` - Bad Request (validation errors, duplicate email)
- `401` - Unauthorized (invalid credentials, or missing/expired token)
- `403` - Forbidden (token belongs to a different user)
- `404` - Not Found (user doesn't exist)

## Next Steps

To enhance the authentication system, consider:
1. Implementing password reset functionality
2. Adding email verification
3. Migrating from JSON file to a proper database (PostgreSQL, MongoDB)
4. Adding rate limiting to prevent brute force attacks
