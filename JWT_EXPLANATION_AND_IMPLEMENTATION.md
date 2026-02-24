# JWT Token - Complete Explanation & Your Implementation

## ❓ Why JWT Tokens Are Used?

### 1. **Security (Authentication)**
- Proves the user is who they claim to be
- Backend verifies the token using a secret key
- User credentials (email/password) are only sent ONCE during login
- After login, only the token is sent (much safer)

### 2. **Stateless Sessions**
- Server doesn't need to store session data in a database
- Token contains all necessary user info
- Reduces server memory usage
- Works great for mobile apps and distributed systems

### 3. **API Communication**
```
Traditional (Dangerous):
  ├─ User → Server: "I'm john@email.com with password123"
  ├─ Server stores session in memory
  └─ User: [sesionID] ← Used in all requests

JWT (Secure):
  ├─ User → Server: "I'm john@email.com with password123"
  ├─ Server → User: "Here's your token: eyJhbGc..."
  └─ User: [JWT Token] ← Used in all requests
           Bearer eyJhbGc... (Much safer!)
```

### 4. **Cross-Platform & Scalable**
- Works with Flutter (mobile), Web, Desktop
- Works across multiple servers
- No session data to sync between servers

---

## ✅ How JWT Is Currently Implemented In Your Project

### Step 1: **Login** (lib/viewmodels/login_viewmodel.dart)

```dart
Future<void> signIn() async {
  // ... validation ...
  
  try {
    // Send credentials to backend
    final response = await _api.login(
      email: state.email,
      password: state.password,
    );

    // Get the token from response
    final token = response['token']?.toString();
    
    if (token != null) {
      // IMPORTANT: Store token in ApiService
      _api.setToken(token);
      
      // Update UI
      state = state.copyWith(
        isLoggedIn: true,
        token: token,
        isLoginSuccessful: true,
      );
    }
  } catch (e) {
    // Handle error
  }
}
```

**What happens:**
1. User enters email & password
2. Sent to backend `/api/auth/login`
3. Backend validates credentials
4. Backend returns JWT token
5. Token is stored in `ApiService._token`
6. User is logged in ✅

---

### Step 2: **Token Storage** (lib/services/api_service.dart)

```dart
class ApiService {
  String? _token;  // Token stored here

  void setToken(String? token) {
    _token = token;  // Set after login
  }
}
```

---

### Step 3: **Using Token in All API Calls** (lib/services/api_service.dart)

```dart
Future<dynamic> _request(
  String endpoint, {
  String method = 'GET',
  Map<String, String>? headers,
  Object? body,
}) async {
  final uri = Uri.parse('$_baseUrl$endpoint');
  final requestHeaders = <String, String>{...?headers};
  
  // ⭐ HERE: Add token to every request
  if (_token != null) {
    requestHeaders['Authorization'] = 'Bearer $_token';
  }

  // Send request with token
  http.Response response;
  if (method == 'GET') {
    response = await _client.get(uri, headers: requestHeaders);
  } else if (method == 'POST') {
    response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        ...requestHeaders,  // ⭐ Token goes here
      },
      body: body,
    );
  }
  // ... etc
}
```

**What happens for every API call:**
```
Request Header:
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
```

Backend receives this header and:
1. Extracts the token from "Bearer eyJhbGc..."
2. Verifies signature using JWT_SECRET
3. If valid → process request
4. If invalid → return 401 Unauthorized error

---

## 🔄 Complete Flow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                      YOUR FLUTTER APP                         │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │   Login Screen      │
                    │ (email + password)  │
                    └────────────┬────────┘
                                 │
                                 ▼
              ┌──────────────────────────────────────┐
              │  ApiService.login(email, password)   │
              │  POST /api/auth/login                │
              └──────────┬───────────────────────────┘
                         │
        ┌────────────────▼────────────────┐
        │       YOUR BACKEND SERVER       │
        │  (Node.js + Express + JWT)      │
        └────────────┬───────────────────┘
                     │
                     ▼
        ┌──────────────────────────────┐
        │ Verify email + password      │
        │ ✅ Valid → Generate JWT      │
        │ ❌ Invalid → Return error    │
        └────────────┬─────────────────┘
                     │
                     ▼
        ┌─────────────────────────────────────┐
        │ Response:                           │
        │ {                                   │
        │   "token": "eyJhbGc...",     │
        │   "user": {...}               │
        │ }                             │
        └────────────┬────────────────────┘
                     │
        ┌────────────▼──────────────────┐
        │   Flutter App Receives Token   │
        │   _api.setToken(token)        │
        │   state.token = token         │
        └────────────┬───────────────────┘
                     │
                     ▼
        ┌──────────────────────────────────┐
        │  All Future API Calls Include:   │
        │  Authorization: Bearer <token>   │
        └──────────────────────────────────┘
                     │
    ┌────────────────┼────────────────┐
    │                │                │
    ▼                ▼                ▼
GET /members    POST /plans    PUT /subscriptions
    │                │                │
    └────────────────┼────────────────┘
                     │
                     ▼
        ┌──────────────────────────────────┐
        │   Backend Verifies Token         │
        │   JWT_SECRET in .env file        │
        │   ✅ Valid → Process Request    │
        │   ❌ Expired → 401 Error        │
        └──────────────────────────────────┘
```

---

## 🚀 Backend Setup (Node.js + Express)

### 1. Install dependencies
```bash
npm install jsonwebtoken dotenv
```

### 2. Create `.env` file in backend directory
```env
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
NODE_ENV=development
API_URL=http://localhost:3001
PORT=3001
```

### 3. Create JWT utility file (`backend/utils/jwt.js`)
```javascript
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;

// Sign a token
function signToken(userId, email) {
  return jwt.sign(
    { userId, email },
    JWT_SECRET,
    { expiresIn: '24h' }  // Token expires in 24 hours
  );
}

// Verify a token
function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    throw new Error('Invalid token');
  }
}

module.exports = { signToken, verifyToken };
```

### 4. Login endpoint (`backend/routes/auth.js`)
```javascript
const express = require('express');
const { signToken } = require('../utils/jwt');
const router = express.Router();

router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  // 1. Find user in database
  const user = await User.findOne({ email });

  // 2. Verify password
  if (!user || !await user.verifyPassword(password)) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  // 3. Generate JWT token
  const token = signToken(user.id, user.email);

  // 4. Return token to Flutter app
  res.json({
    token,
    user: {
      id: user.id,
      email: user.email,
      fullName: user.fullName
    }
  });
});

module.exports = router;
```

### 5. Protected routes middleware
```javascript
const { verifyToken } = require('../utils/jwt');

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  
  // Header format: "Bearer <token>"
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const token = authHeader.slice(7);  // Remove "Bearer "

  try {
    const decoded = verifyToken(token);
    req.user = decoded;  // Store user info in request
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
}

// Use middleware on protected routes
router.get('/members', authMiddleware, (req, res) => {
  // Only accessible with valid token
  // req.user contains the user info from token
});
```

---

## 📱 Your Flutter Implementation Summary

### ✅ **Already Implemented:**
- [x] Login endpoint that returns JWT token
- [x] Token stored in `ApiService._token`
- [x] Token automatically added to all requests
- [x] Authorization header format: `Bearer <token>`
- [x] Error handling for invalid tokens

### 🔧 **Already Working:**
1. User logs in → Gets JWT token
2. Token stored in memory
3. All subsequent requests include token
4. Backend verifies token on each request
5. If token invalid/expired → 401 error

### ⚠️ **Issue: Token Lost on App Restart**
When user closes and reopens the app:
- Token is lost (stored in memory only)
- Need to add **secure persistent storage**

---

## 🛠️ What You Need to Do

### 1. Add Secure Token Storage (RECOMMENDED)
```bash
flutter pub add flutter_secure_storage
```

Update `lib/services/api_service.dart`:
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final _secureStorage = const FlutterSecureStorage();
  String? _token;

  // Load token from secure storage on app start
  Future<void> loadToken() async {
    _token = await _secureStorage.read(key: 'jwt_token');
  }

  // Save token to secure storage
  Future<void> setToken(String? token) async {
    _token = token;
    if (token != null) {
      await _secureStorage.write(key: 'jwt_token', value: token);
    } else {
      await _secureStorage.delete(key: 'jwt_token');
    }
  }

  // Clear token on logout
  Future<void> logout() async {
    _token = null;
    await _secureStorage.delete(key: 'jwt_token');
  }
}
```

### 2. Load Token on App Start
Update `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load saved token
  await apiService.loadToken();
  
  runApp(const ProviderScope(child: MyApp()));
}
```

### 3. Verify Backend Uses JWT_SECRET from .env
Update backend main file:
```javascript
require('dotenv').config();

const app = express();

// Verify JWT_SECRET exists
if (!process.env.JWT_SECRET) {
  console.error('ERROR: JWT_SECRET not set in .env file!');
  process.exit(1);
}

console.log('✅ JWT_SECRET loaded from .env');
```

---

## 🧪 Testing JWT Implementation

### 1. Test Login
```
1. Run backend: npm start
2. Run Flutter app: flutter run
3. Enter credentials: owner@demo.com / password123
4. Check if token is stored
```

### 2. Test Token in Requests
Enable logging in `api_service.dart`:
```dart
print('Request Headers: $requestHeaders');
print('Token: $_token');
```

Output should show:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3. Test Token Validation
- Manually delete token from secure storage
- Try to access protected endpoints
- Should return 401 error

---

## 📚 JWT Token Structure

A JWT token has 3 parts separated by `.`:

```
Header.Payload.Signature

eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c

├─ Header: {"alg":"HS256","typ":"JWT"}
├─ Payload: {"sub":"1234567890","name":"John Doe","iat":1516239022}
└─ Signature: Verification hash created with JWT_SECRET
```

Backend uses `JWT_SECRET` to:
1. **Create signature** when issuing token
2. **Verify signature** when receiving token

If JWT_SECRET is wrong or token is modified → Token is invalid! ❌

---

## 🎯 Summary

| Question | Answer |
|----------|--------|
| **Why JWT?** | Security + Stateless + Scalable |
| **Where is it used?** | Every API request after login |
| **How does it work?** | Login → Get token → Include in headers |
| **Is it in your project?** | ✅ YES! Already implemented |
| **What's missing?** | Persistent storage + Logout function |

Your Flutter app is **correctly using JWT tokens**! You just need to:
1. ✅ Set JWT_SECRET in backend `.env` file
2. ✅ Add secure token storage
3. ✅ Implement logout functionality


