# JWT Token Setup - QUICK ACTION GUIDE

## ❓ Why JWT Tokens?

**JWT (JSON Web Token)** is like a digital ID card:
- 🔐 **Secure** - Can't be faked without the secret key
- 🚫 **Stateless** - No need to store session data
- 📱 **Mobile Friendly** - Works perfectly with apps
- 🌍 **Scalable** - Works across multiple servers

### Real-World Example
```
Without JWT (Insecure):
├─ User sends password every request ❌
├─ Server stores password in memory ❌
└─ Password exposed to hackers ❌

With JWT (Secure):
├─ User sends password once (login) ✅
├─ Server returns JWT token
├─ User sends token in every request (not password) ✅
├─ Server verifies token with secret key ✅
└─ Password never sent again ✅
```

---

## ✅ What's Already Done in Your Flutter App

1. ✅ Added `flutter_secure_storage` package
2. ✅ Token automatically saved when you login
3. ✅ Token automatically loaded when app restarts
4. ✅ Token automatically included in all API requests
5. ✅ Token automatically cleared when you logout
6. ✅ Token stored in encrypted secure storage

---

## 🚀 WHAT YOU NEED TO DO (Backend Setup)

### STEP 1: Create `.env` file in backend

Open `D:\gymsasapp\backend` and create a file named `.env`:

```env
JWT_SECRET=my-super-secret-key-change-this-12345
NODE_ENV=development
PORT=3001
API_URL=http://localhost:3001
```

**⚠️ IMPORTANT:** Generate a secure secret key:
```bash
# In PowerShell, run:
[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$(Get-Random -Minimum 1000000000 -Maximum 9999999999)$(Get-Random -Minimum 1000000000 -Maximum 9999999999)"))
```

Or just use this strong secret (minimum for testing):
```
JWT_SECRET=aX9bY8cZ7dW6eV5fU4gT3hS2iR1jQ0kP9oN8mL7kJ6iH5gF4eD3cB2aA1zY0xW
```

---

### STEP 2: Install Dependencies in Backend

```bash
cd D:\gymsasapp\backend
npm install dotenv jsonwebtoken
```

---

### STEP 3: Load .env in Backend

In your backend's main file (`server.js` or `index.js`):

**Add at the VERY TOP:**
```javascript
require('dotenv').config();  // ← Add this FIRST!

const express = require('express');
const app = express();

// Check JWT_SECRET is loaded
if (!process.env.JWT_SECRET) {
  console.error('❌ ERROR: JWT_SECRET not set in .env file!');
  process.exit(1);
}

console.log('✅ JWT_SECRET loaded from .env');
```

---

### STEP 4: Create Login Endpoint (if you don't have one)

In your backend auth routes:

```javascript
const jwt = require('jsonwebtoken');
const express = require('express');
const router = express.Router();

router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    // Find user in database
    const user = await User.findOne({ email });
    
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Check password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // ⭐ GENERATE JWT TOKEN
    const token = jwt.sign(
      { 
        userId: user._id, 
        email: user.email,
        name: user.name 
      },
      process.env.JWT_SECRET,  // ← Uses .env secret!
      { expiresIn: '24h' }      // Token expires in 24 hours
    );

    // ⭐ RETURN TOKEN TO APP
    res.json({
      token,  // ← This is what your Flutter app receives!
      user: {
        id: user._id,
        email: user.email,
        name: user.name
      }
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
```

---

### STEP 5: Create Token Verification Middleware

Create `backend/middleware/auth.js`:

```javascript
const jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {
  // Get token from header
  const authHeader = req.headers.authorization;
  
  if (!authHeader) {
    return res.status(401).json({ error: 'No token provided' });
  }

  // Extract token from "Bearer <token>"
  const token = authHeader.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'Invalid token format' });
  }

  try {
    // ⭐ VERIFY TOKEN
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;  // User info from token
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

module.exports = authMiddleware;
```

---

### STEP 6: Use Middleware on Protected Routes

In your route files:

```javascript
const authMiddleware = require('./middleware/auth');

// Public routes (no token needed)
router.post('/auth/login', loginController);

// Protected routes (token required)
router.get('/members', authMiddleware, getMembersController);
router.post('/members', authMiddleware, createMemberController);
router.get('/dashboard/stats', authMiddleware, getDashboardStatsController);
router.post('/subscriptions', authMiddleware, createSubscriptionController);
```

---

## 🧪 TESTING (After Backend Setup)

### Test 1: Check Backend Starts
```bash
cd D:\gymsasapp\backend
npm start
```

Expected output:
```
✅ JWT_SECRET loaded from .env
Server running on port 3001
```

---

### Test 2: Test Login in Flutter App
```bash
cd D:\fp\gymsas_myapp
flutter pub get
flutter run
```

1. Open app
2. Enter: `owner@demo.com` / `password123` (or your credentials)
3. Click "Sign In"
4. Should see dashboard ✅

---

### Test 3: Verify Token Persists
1. Successfully login to dashboard
2. Close app completely (force stop)
3. Reopen app
4. Should automatically show dashboard ✅
5. (Not login screen)

---

### Test 4: Verify Logout Clears Token
1. Dashboard is showing
2. Click hamburger menu (☰) top left
3. Click "Logout"
4. Should show login screen ✅
5. Close and reopen app
6. Should show login screen (not dashboard) ✅

---

## 📊 How JWT Works Step by Step

```
┌─────────────────────────────────────────────────────────┐
│ STEP 1: User Enters Credentials                         │
├─────────────────────────────────────────────────────────┤
│ Email: owner@demo.com                                   │
│ Password: password123                                   │
└────────────────┬──────────────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────────────┐
│ STEP 2: Flutter App Sends to Backend                    │
├─────────────────────────────────────────────────────────┤
│ POST /api/auth/login                                    │
│ Body: { email, password }                               │
└────────────────┬──────────────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────────────┐
│ STEP 3: Backend Verifies Credentials                    │
├─────────────────────────────────────────────────────────┤
│ Find user with email ✅                                 │
│ Compare password ✅                                     │
│ Both match → Generate token                             │
└────────────────┬──────────────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────────────┐
│ STEP 4: Backend Creates JWT Token                       │
├─────────────────────────────────────────────────────────┤
│ Algorithm: HMAC SHA256                                  │
│ Secret: JWT_SECRET from .env                            │
│ Token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...        │
└────────────────┬──────────────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────────────┐
│ STEP 5: Backend Returns Token                           │
├─────────────────────────────────────────────────────────┤
│ Response: {                                             │
│   "token": "eyJhbGc...",                       │
│   "user": { id, email, name }                   │
│ }                                               │
└────────────────┬──────────────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────────────┐
│ STEP 6: Flutter Receives Token                          │
├─────────────────────────────────────────────────────────┤
│ Calls: apiService.setToken(token)                       │
│ Saves: Secure encrypted storage 🔒                      │
│ Shows: Dashboard screen                                 │
└────────────────┬──────────────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────────────┐
│ STEP 7: Token Used for All Requests                     │
├─────────────────────────────────────────────────────────┤
│ GET /api/members                                        │
│ Header: Authorization: Bearer eyJhbGc...        │
│                                                 │
│ Backend verifies token using JWT_SECRET ✅     │
│ Returns: List of members                        │
└────────────────┬──────────────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────────────┐
│ STEP 8: App Restart - Token Loads Automatically         │
├─────────────────────────────────────────────────────────┤
│ app.dart calls: apiService.loadToken()                  │
│ Loads from secure storage: eyJhbGc...           │
│ User stays logged in ✅                         │
└────────────────┬──────────────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────────────┐
│ STEP 9: User Logout - Token Cleared                     │
├─────────────────────────────────────────────────────────┤
│ Click Logout button                                     │
│ Calls: apiService.logout()                              │
│ Deletes: Token from secure storage                      │
│ Shows: Login screen                                     │
└─────────────────────────────────────────────────────────┘
```

---

## 🔐 Security Checklist

- ✅ Token stored in encrypted secure storage (not plain text)
- ✅ Token NOT logged to console in production
- ✅ Token NOT stored in SharedPreferences
- ✅ JWT_SECRET NOT hardcoded in app
- ✅ JWT_SECRET stored in .env (not in code)
- ✅ HTTPS used in production (not HTTP)
- ✅ Token cleared on logout
- ✅ Token reloaded on app restart

---

## ❓ FAQ

**Q: Why not just store password and login every time?**
A: Because passwords should NEVER be stored on device. Tokens are safer and faster.

**Q: What if token expires?**
A: User needs to login again. Or implement token refresh endpoint.

**Q: Is token visible to user?**
A: No, it's encrypted in secure storage. User can't access it.

**Q: What if JWT_SECRET is wrong?**
A: Backend can't verify tokens. All API calls fail with 401 error.

**Q: How long does token last?**
A: Set in backend: `expiresIn: '24h'` (configurable)

---

## 🎯 Summary

| What | Where | Status |
|------|-------|--------|
| Flutter Secure Storage | ✅ Already added | DONE |
| Token Save on Login | ✅ Already added | DONE |
| Token Load on Restart | ✅ Already added | DONE |
| Token in API Requests | ✅ Already added | DONE |
| Token Clear on Logout | ✅ Already added | DONE |
| Backend .env file | ❌ YOU NEED TO CREATE | **DO THIS FIRST** |
| JWT_SECRET | ❌ YOU NEED TO SET | **DO THIS FIRST** |
| Login endpoint | ⚠️ Verify it exists | Check your backend |
| Auth middleware | ❌ YOU NEED TO CREATE | Optional but recommended |

---

## 🚀 NEXT STEPS

1. **Create `.env` file** in backend directory
2. **Set JWT_SECRET** in .env file
3. **Install dotenv** and jsonwebtoken in backend
4. **Update backend** to load .env
5. **Ensure login endpoint** returns JWT token
6. **Create auth middleware** for protected routes
7. **Run tests** to verify everything works

**Your Flutter app is already ready!** Just set up the backend.


