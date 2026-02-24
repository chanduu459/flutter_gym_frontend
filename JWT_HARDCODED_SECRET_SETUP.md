# JWT Implementation with Hardcoded JWT_SECRET

## 🔑 JWT_SECRET Configuration

**Your JWT_SECRET:**
```
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
```

This is used for:
- Creating JWT tokens on login
- Verifying JWT tokens on API requests
- Must be the SAME on both frontend and backend

---

## 📱 Flutter/Dart Side (Already Done!)

Your Flutter app already handles JWT tokens:

1. ✅ User enters email/password
2. ✅ App sends credentials to backend `/api/auth/login`
3. ✅ Backend generates JWT token using JWT_SECRET
4. ✅ App receives token and stores securely
5. ✅ All future API calls include token in header: `Authorization: Bearer <token>`
6. ✅ Backend verifies token using same JWT_SECRET

### How Token is Stored (lib/services/api_service.dart)
```dart
// After login, token is saved
await apiService.setToken(token);

// Token stored in encrypted secure storage
// Sent with every API request:
headers['Authorization'] = 'Bearer $token';

// On logout, token is cleared
await apiService.logout();
```

---

## 🖥️ Backend Setup (Node.js/Express)

### Step 1: Install Dependencies
```bash
cd D:\gymsasapp\backend
npm install express cors jsonwebtoken
```

### Step 2: Create Backend Files

Copy the example files into your backend directory:

1. **backend/server.js** - Main server file
   - Use: `BACKEND_SERVER_EXAMPLE.js` as template
   - Replace `server.js` with this code

2. **backend/utils/jwt.js** - JWT utilities
   - Use: `BACKEND_JWT_UTILS_EXAMPLE.js` as template
   - Create this new file

3. **backend/routes/auth.js** - Auth routes
   - Use: `BACKEND_AUTH_ROUTE_EXAMPLE.js` as template
   - Create this new file

### Step 3: Update package.json

```json
{
  "name": "gymsas-backend",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "jsonwebtoken": "^9.1.0"
  }
}
```

### Step 4: Start Backend Server
```bash
cd D:\gymsasapp\backend
npm start
```

Expected output:
```
==================================================
✅ Server started successfully!
==================================================
📍 Running on: http://localhost:3001
✅ JWT_SECRET configured
📝 Demo credentials: owner@demo.com / password123
==================================================
```

---

## 🧪 Testing the JWT Implementation

### Test 1: Check Backend is Running
```bash
# Open browser and go to:
http://localhost:3001/health

# Should see:
{
  "status": "ok",
  "message": "Server is running",
  "timestamp": "2024-02-23T10:30:00.000Z"
}
```

### Test 2: Test Login Endpoint
```bash
# Using curl or Postman
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@demo.com","password":"password123"}'

# Should return:
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "123",
    "email": "owner@demo.com",
    "fullName": "Demo Owner",
    "role": "owner"
  }
}
```

### Test 3: Test Protected Endpoint (with token)
```bash
# Get token from login response above, then:
curl -X GET http://localhost:3001/api/members \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Should return members list
{
  "success": true,
  "data": [...]
}
```

### Test 4: Test Protected Endpoint (without token)
```bash
# Without token header:
curl -X GET http://localhost:3001/api/members

# Should fail:
{
  "error": "No token provided",
  "success": false
}
```

### Test 5: Test in Flutter App
```bash
# Terminal 1: Start backend
cd D:\gymsasapp\backend
npm start

# Terminal 2: Start Flutter app
cd D:\fp\gymsas_myapp
flutter pub get
flutter run

# In app:
1. Enter: owner@demo.com / password123
2. Click Sign In
3. Should see dashboard ✅
4. Token is automatically handled
```

---

## 📊 How JWT Token Works

```
┌─────────────────────────────────────────────────┐
│ 1. USER ENTERS CREDENTIALS                      │
├─────────────────────────────────────────────────┤
│ Email: owner@demo.com                           │
│ Password: password123                           │
└────────────────┬────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────┐
│ 2. FLUTTER APP SENDS TO BACKEND                 │
├─────────────────────────────────────────────────┤
│ POST /api/auth/login                            │
│ Body: {email, password}                         │
└────────────────┬────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────┐
│ 3. BACKEND VERIFIES CREDENTIALS                 │
├─────────────────────────────────────────────────┤
│ Check: email === 'owner@demo.com' ✅            │
│ Check: password === 'password123' ✅            │
└────────────────┬────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────┐
│ 4. BACKEND CREATES JWT TOKEN                    │
├─────────────────────────────────────────────────┤
│ jwt.sign(                                       │
│   {userId, email, role},                        │
│   JWT_SECRET,  ← Uses hardcoded secret          │
│   {expiresIn: '24h'}                            │
│ )                                               │
│ Result: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..│
└────────────────┬────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────┐
│ 5. BACKEND RETURNS TOKEN                        │
├─────────────────────────────────────────────────┤
│ Response: {                                     │
│   token: "eyJhbGc...",                          │
│   user: {id, email, fullName, role}             │
│ }                                               │
└────────────────┬────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────┐
│ 6. FLUTTER RECEIVES & STORES TOKEN              │
├─────────────────────────────────────────────────┤
│ apiService.setToken(token)                      │
│ ↓                                               │
│ Saved to encrypted secure storage 🔒            │
└────────────────┬────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────┐
│ 7. FLUTTER USES TOKEN FOR ALL REQUESTS          │
├─────────────────────────────────────────────────┤
│ GET /api/members                                │
│ Header: Authorization: Bearer eyJhbGc...        │
│                                                 │
│ GET /api/dashboard/stats                        │
│ Header: Authorization: Bearer eyJhbGc...        │
│                                                 │
│ POST /api/subscriptions                         │
│ Header: Authorization: Bearer eyJhbGc...        │
└────────────────┬────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────┐
│ 8. BACKEND VERIFIES TOKEN                       │
├─────────────────────────────────────────────────┤
│ Extract: token from "Bearer ..." header         │
│ Verify: jwt.verify(token, JWT_SECRET)           │
│ ✅ Valid? → Process request                     │
│ ❌ Invalid? → Return 401 error                  │
└─────────────────────────────────────────────────┘
```

---

## 📝 The JWT Token Structure

Your JWT token has 3 parts separated by `.`:

```
Header.Payload.Signature

eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIn0.
SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

### Part 1: Header
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```
- Algorithm: HMAC SHA256
- Type: JSON Web Token

### Part 2: Payload (Your Data)
```json
{
  "userId": "123",
  "email": "owner@demo.com",
  "fullName": "Demo Owner",
  "role": "owner",
  "iat": 1708679400,
  "exp": 1708765800
}
```
- User information
- iat: Issued at (timestamp)
- exp: Expiration time (24 hours from now)

### Part 3: Signature
```
HMAC256(
  Base64(Header) + "." + Base64(Payload),
  JWT_SECRET
)
```
- Created using the JWT_SECRET
- Prevents tampering with token

**Important:** If anyone tries to modify the token, the signature becomes invalid!

---

## 🔐 Security Notes

### ✅ Good (Your Implementation)
- JWT_SECRET same on backend (in code)
- Token stored securely on app
- Token sent in Authorization header
- Token verified on every request
- Token expires after 24 hours

### ⚠️ Future Improvements
- Use strong random JWT_SECRET (64+ characters)
- Move JWT_SECRET to environment variables (when in production)
- Implement token refresh endpoint
- Add rate limiting to login endpoint
- Log all authentication attempts
- Implement HTTPS in production

---

## 🚀 QUICK START CHECKLIST

- [ ] Copy backend example files to `D:\gymsasapp\backend\`
- [ ] Run: `npm install` in backend directory
- [ ] Update `package.json` with start script
- [ ] Start backend: `npm start`
- [ ] See "✅ Server started successfully!"
- [ ] Run Flutter app: `flutter run`
- [ ] Login with: owner@demo.com / password123
- [ ] See dashboard ✅
- [ ] Test logout - returns to login ✅

---

## 📞 Troubleshooting

### Backend won't start
```bash
# Check Node.js is installed
node --version

# Check npm is installed
npm --version

# Check port 3001 is free (not in use)
netstat -ano | findstr :3001
```

### Login fails with "Cannot reach server"
- Make sure backend is running: `npm start`
- Check backend URL: `http://localhost:3001` (or your IP)
- Check in `lib/services/api_service.dart` line 18:
  ```dart
  defaultValue: 'http://10.198.164.90:3001'
  ```
  Update IP to your machine's IP if needed

### Token verification fails
- Check JWT_SECRET is same on backend and in token generation
- Current: `your-super-secret-jwt-key-change-this-in-production`
- Verify token hasn't expired (24 hours)
- Check token format: `Authorization: Bearer <token>`

### Cannot find modules
```bash
# Ensure you're in backend directory
cd D:\gymsasapp\backend

# Delete and reinstall
rm -r node_modules
npm install
```

---

## ✅ YOU'RE READY!

Your Flutter app is ready to work with JWT tokens!

Just:
1. Set up the backend files
2. Run backend
3. Run Flutter app
4. Login and enjoy! 🎉


