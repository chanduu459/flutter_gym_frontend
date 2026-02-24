# JWT Token Setup & Implementation - COMPLETE GUIDE

## ✅ WHAT HAS BEEN DONE

### 1. **Added Secure Token Storage**
- ✅ Added `flutter_secure_storage` to pubspec.yaml
- ✅ Updated `ApiService` with secure storage methods:
  - `loadToken()` - Load token on app start
  - `setToken()` - Save token securely (called after login)
  - `getToken()` - Get current token (for testing)
  - `logout()` - Clear token from secure storage

### 2. **Updated Main App Initialization**
- ✅ Modified `main.dart` to:
  - Call `WidgetsFlutterBinding.ensureInitialized()`
  - Load saved token from secure storage on startup
  - Token persists across app restarts

### 3. **Enhanced Logout Functionality**
- ✅ Updated `DrawerViewModel` to:
  - Receive `ApiService` instance
  - Call `apiService.logout()` to clear token
  - Reset drawer state

### 4. **JWT Token Flow**
```
User Login
    ↓
POST /api/auth/login (email + password)
    ↓
Backend generates JWT token
    ↓
Response contains: { token: "eyJhbGc..." }
    ↓
ApiService.setToken(token)
    ↓
Token saved to secure storage (encrypted)
    ↓
Token loaded on app restart
    ↓
All API requests include: Authorization: Bearer <token>
    ↓
Backend verifies token using JWT_SECRET from .env
```

---

## 🔧 BACKEND SETUP (Required)

### Step 1: Create `.env` file
Create `D:\gymsasapp\backend\.env`:

```env
# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
NODE_ENV=development

# Server Configuration
PORT=3001
API_URL=http://localhost:3001

# Database (if applicable)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=gymsas_db
DB_USER=postgres
DB_PASSWORD=your-password
```

### Step 2: Install Dependencies
```bash
cd D:\gymsasapp\backend
npm install dotenv jsonwebtoken
```

### Step 3: Load Environment Variables
In your backend main file (server.js / index.js):

```javascript
// At the very top!
require('dotenv').config();

const express = require('express');
const app = express();

// Verify JWT_SECRET is loaded
if (!process.env.JWT_SECRET) {
  console.error('❌ ERROR: JWT_SECRET not found in .env file!');
  process.exit(1);
}

console.log('✅ JWT_SECRET loaded successfully');
```

### Step 4: Create JWT Utility
Create `backend/utils/jwt.js`:

```javascript
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;

function signToken(payload, expiresIn = '24h') {
  return jwt.sign(payload, JWT_SECRET, { expiresIn });
}

function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    throw new Error('Invalid or expired token');
  }
}

function decodeToken(token) {
  return jwt.decode(token);
}

module.exports = { signToken, verifyToken, decodeToken };
```

### Step 5: Update Login Endpoint
In your auth routes (backend/routes/auth.js):

```javascript
const express = require('express');
const { signToken } = require('../utils/jwt');
const router = express.Router();

router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Verify password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = signToken({
      userId: user._id,
      email: user.email,
      role: user.role,
    });

    // Return token
    res.json({
      token,
      user: {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
```

### Step 6: Create Authentication Middleware
Create `backend/middleware/auth.js`:

```javascript
const { verifyToken } = require('../utils/jwt');

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  // Check if header exists
  if (!authHeader) {
    return res.status(401).json({ error: 'No token provided' });
  }

  // Extract token from "Bearer <token>"
  if (!authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Invalid token format' });
  }

  const token = authHeader.slice(7);

  try {
    // Verify and decode token
    const decoded = verifyToken(token);
    req.user = decoded;  // Store user info in request
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

module.exports = authMiddleware;
```

### Step 7: Protect Your Routes
```javascript
const authMiddleware = require('../middleware/auth');

// Unprotected routes
router.post('/auth/login', loginController);
router.post('/auth/register', registerController);

// Protected routes
router.get('/members', authMiddleware, getMembersController);
router.post('/members', authMiddleware, createMemberController);
router.get('/dashboard/stats', authMiddleware, getDashboardStatsController);
```

---

## 📱 FLUTTER SETUP (Already Done!)

### ✅ Changes Made

**1. pubspec.yaml**
```yaml
dependencies:
  flutter_secure_storage: ^9.0.0  # ← Added
```

**2. lib/main.dart**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load token from secure storage
  final apiService = ApiService();
  await apiService.loadToken();
  
  runApp(const ProviderScope(child: MyApp()));
}
```

**3. lib/services/api_service.dart**
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _token;

  // Load token on app start
  Future<void> loadToken() async {
    try {
      _token = await _secureStorage.read(key: 'jwt_token');
    } catch (e) {
      print('Error loading token: $e');
    }
  }

  // Save token after login
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

**4. lib/viewmodels/drawer_viewmodel.dart**
```dart
class DrawerViewModel extends StateNotifier<DrawerState> {
  final ApiService _apiService;

  DrawerViewModel(this._apiService) : super(DrawerState());

  Future<void> logout() async {
    await _apiService.logout();  // Clear token
    state = DrawerState();
  }
}
```

---

## 🧪 TESTING JWT IMPLEMENTATION

### Test 1: Login & Token Storage
```
1. Run backend: npm start (from backend directory)
2. Run app: flutter run
3. Enter credentials: owner@demo.com / password123
4. Click Sign In
5. Should navigate to dashboard ✅
6. Check console: Token should be stored securely
```

### Test 2: App Restart with Token
```
1. Login successfully
2. Close app completely
3. Reopen app
4. Should automatically be logged in ✅
5. Token loaded from secure storage
6. Can access dashboard without re-entering credentials
```

### Test 3: Logout Clears Token
```
1. Login successfully
2. Click hamburger menu (top left)
3. Click "Logout" button
4. Should return to login screen ✅
5. Token cleared from secure storage
6. Close and reopen app
7. Should show login screen (not dashboard)
```

### Test 4: Token in API Requests
Enable debug logging in api_service.dart:
```dart
if (_token != null) {
  requestHeaders['Authorization'] = 'Bearer $_token';
  print('✅ Token added to request: Bearer ${_token?.substring(0, 20)}...');
}
```

Output should show:
```
✅ Token added to request: Bearer eyJhbGciOiJIUzI1NiIs...
```

### Test 5: Expired Token Error
```
1. Login and get token
2. Manually set JWT_SECRET to wrong value in backend
3. Try to access any protected endpoint
4. Should get 401 Unauthorized error ✅
5. Fix JWT_SECRET back
6. App should work again
```

---

## 🚀 NEXT STEPS

### 1. Immediate (Required)
- [ ] Create `.env` file in backend with JWT_SECRET
- [ ] Verify backend is using JWT_SECRET from .env
- [ ] Test login flow

### 2. Short Term
- [ ] Add token refresh logic (token expires after 24h)
- [ ] Implement "Remember Me" checkbox
- [ ] Add password reset functionality

### 3. Medium Term
- [ ] Add role-based access control
- [ ] Implement token blacklist on logout
- [ ] Add automatic token refresh
- [ ] Implement two-factor authentication

---

## 🔐 SECURITY BEST PRACTICES

### ✅ Already Implemented
- Token stored in encrypted secure storage (not SharedPreferences)
- Token sent with Authorization header (not in URL)
- JWT_SECRET never exposed in code
- Logout clears token completely

### ⚠️ Production Checklist
- [ ] Use strong JWT_SECRET (32+ characters)
- [ ] Enable HTTPS only in production
- [ ] Set shorter token expiration (1-2 hours)
- [ ] Implement token refresh endpoint
- [ ] Monitor token usage for suspicious activity
- [ ] Rotate JWT_SECRET periodically
- [ ] Add rate limiting to login endpoint
- [ ] Log all authentication attempts

---

## 📞 TROUBLESHOOTING

### Token Not Persisting
**Problem:** App logs out after restart
**Solution:**
- Check secure storage permissions in AndroidManifest.xml
- Clear app data and try again
- Verify flutter_secure_storage is properly installed

### 401 Unauthorized Errors
**Problem:** All API requests fail with 401
**Solution:**
- Verify backend JWT_SECRET matches what's being used
- Check token is being added to request header
- Login again to get fresh token
- Check token hasn't expired

### Backend Can't Read .env
**Problem:** JWT_SECRET is undefined
**Solution:**
```bash
# Verify dotenv is installed
npm install dotenv

# Check .env file exists and has correct format
cat .env

# Restart backend
npm start
```

### Secure Storage Errors on iOS
**Problem:** FlutterSecureStorage fails on iOS
**Solution:**
- Update iOS deployment target to 12.0+
- Run: pod install from ios folder
- Check Keychain entitlements

---

## 📚 JWT TOKEN STRUCTURE

Your JWT token contains 3 parts:

```
Header.Payload.Signature

eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.
SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

**Part 1: Header**
```json
{"alg":"HS256","typ":"JWT"}
```
- Algorithm: HMAC SHA256
- Type: JWT

**Part 2: Payload**
```json
{"userId":"123","email":"user@example.com","iat":1516239022}
```
- User information
- Issued at timestamp
- Expiration time (optional)

**Part 3: Signature**
- Created using: HMAC(Header + Payload, JWT_SECRET)
- Prevents token tampering
- Backend uses JWT_SECRET to verify signature

---

## ✨ YOU'RE ALL SET!

Your Flutter app now has:
- ✅ Secure JWT token storage
- ✅ Automatic token loading on app start
- ✅ Token sent with all API requests
- ✅ Token clearing on logout
- ✅ Integration with backend authentication

**Next: Set up your backend .env file and test the complete flow!**


