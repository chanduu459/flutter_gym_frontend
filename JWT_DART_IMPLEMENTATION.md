# JWT Implementation in Dart (No Node.js Required!)

## ✅ Why Dart Instead of JavaScript?

**Pure Dart Implementation Benefits:**
- ✅ Everything in one language (Dart)
- ✅ No need for separate Node.js backend
- ✅ Easier to maintain
- ✅ Same JWT_SECRET everywhere
- ✅ Can run backend logic on device if needed
- ✅ Better performance (compiled)
- ✅ Full type safety

**Your Setup:**
```
Frontend (Flutter/Dart) ←→ Backend (Dart) ←→ Database
  ↑                          ↑
  All in Dart!
```

---

## 📦 What's Been Created

### 1. **JWT Service** (`lib/services/jwt_service.dart`)
Pure Dart JWT implementation that:
- ✅ Generates JWT tokens
- ✅ Verifies JWT tokens
- ✅ Decodes JWT tokens
- ✅ Handles token expiration
- ✅ Extracts claims
- ✅ Refreshes tokens

### 2. **Mock Backend Server** (`lib/services/mock_backend_server.dart`)
Dart backend that:
- ✅ Handles login requests
- ✅ Generates JWT tokens
- ✅ Verifies tokens on protected endpoints
- ✅ Manages members, plans, subscriptions
- ✅ Returns proper API responses

---

## 🚀 Quick Start

### Step 1: Add Package
```bash
cd D:\fp\gymsas_myapp
flutter pub get
```

The `dart_jsonwebtoken: ^2.13.0` package is now installed!

### Step 2: Use JWT Service in Your App

#### Generate Token (After Login)
```dart
import 'package:gymsas_myapp/services/jwt_service.dart';

// Generate token
final token = JwtService.generateToken(
  userId: '123',
  email: 'user@example.com',
  fullName: 'John Doe',
  role: 'owner',
  expiresInHours: 24,
);

print('Token: $token');
// Output: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### Verify Token
```dart
try {
  // Verify and get claims
  final claims = JwtService.verifyToken(token);
  
  print('Token is valid!');
  print('User: ${claims['email']}');
  print('Role: ${claims['role']}');
} catch (e) {
  print('Token invalid: $e');
}
```

#### Check Token Expiration
```dart
if (JwtService.isTokenExpired(token)) {
  print('Token has expired');
} else {
  final remaining = JwtService.getTokenExpirationTime(token);
  print('Token expires in: ${remaining!.inHours} hours');
}
```

#### Get Specific Claim
```dart
final email = JwtService.getClaim(token, 'email');
final userId = JwtService.getClaim(token, 'userId');
```

#### Refresh Token
```dart
final newToken = JwtService.refreshToken(oldToken);
// Generates new token with same claims but new expiration
```

---

## 🔑 JWT_SECRET Configuration

**Location:** Both Flutter and Mock Backend use the same secret:
```dart
// lib/services/jwt_service.dart
static const String JWT_SECRET = 'your-super-secret-jwt-key-change-this-in-production';
```

**This JWT_SECRET is:**
- Used to SIGN tokens (when generating)
- Used to VERIFY tokens (when checking)
- Must be the SAME on all devices
- Must be kept SECRET (don't commit to git)

---

## 📊 Complete JWT Flow in Dart

```
┌──────────────────────────────────────────────┐
│ 1. USER ENTERS CREDENTIALS                   │
├──────────────────────────────────────────────┤
│ Email: owner@demo.com                        │
│ Password: password123                        │
└────────────────┬─────────────────────────────┘
                 ▼
┌──────────────────────────────────────────────┐
│ 2. FLUTTER APP SENDS LOGIN REQUEST           │
├──────────────────────────────────────────────┤
│ POST /api/auth/login                         │
│ Body: {email, password}                      │
└────────────────┬─────────────────────────────┘
                 ▼
┌──────────────────────────────────────────────┐
│ 3. MOCK BACKEND RECEIVES REQUEST             │
├──────────────────────────────────────────────┤
│ MockBackendServer.handleLogin()              │
│ Validates email & password ✅                │
└────────────────┬─────────────────────────────┘
                 ▼
┌──────────────────────────────────────────────┐
│ 4. BACKEND GENERATES JWT TOKEN               │
├──────────────────────────────────────────────┤
│ JwtService.generateToken({...})              │
│ Uses JWT_SECRET to sign token                │
│ token = eyJhbGc...                           │
└────────────────┬─────────────────────────────┘
                 ▼
┌──────────────────────────────────────────────┐
│ 5. BACKEND RETURNS TOKEN                     │
├──────────────────────────────────────────────┤
│ Response: {                                  │
│   token: "eyJhbGc...",                       │
│   user: {id, email, fullName, role}          │
│ }                                            │
└────────────────┬─────────────────────────────┘
                 ▼
┌──────────────────────────────────────────────┐
│ 6. FLUTTER STORES TOKEN                      │
├──────────────────────────────────────────────┤
│ apiService.setToken(token)                   │
│ → Saved to secure storage 🔒                 │
└────────────────┬─────────────────────────────┘
                 ▼
┌──────────────────────────────────────────────┐
│ 7. FLUTTER USES TOKEN FOR ALL REQUESTS       │
├──────────────────────────────────────────────┤
│ GET /api/members                             │
│ Header: Authorization: Bearer eyJhbGc...     │
│                                              │
│ POST /api/subscriptions                      │
│ Header: Authorization: Bearer eyJhbGc...     │
└────────────────┬─────────────────────────────┘
                 ▼
┌──────────────────────────────────────────────┐
│ 8. BACKEND VERIFIES TOKEN                    │
├──────────────────────────────────────────────┤
│ Extract: token from header                   │
│ Verify: JwtService.verifyToken(token)        │
│ Uses same JWT_SECRET to verify ✅            │
│                                              │
│ ✅ Valid? → Process request                  │
│ ❌ Invalid? → Return 401 error               │
└──────────────────────────────────────────────┘
```

---

## 💡 JWT Service Methods

### 1. Generate Token
```dart
final token = JwtService.generateToken(
  userId: '123',
  email: 'user@example.com',
  fullName: 'John Doe',
  role: 'owner',
  expiresInHours: 24, // Default: 24 hours
);
```

### 2. Verify Token (Throws if invalid)
```dart
try {
  final claims = JwtService.verifyToken(token);
  // claims: {userId, email, fullName, role, iat, exp}
} catch (e) {
  // Token is invalid or expired
}
```

### 3. Decode Token (No verification)
```dart
final claims = JwtService.decodeToken(token);
// WARNING: No signature verification!
// Only for inspection
```

### 4. Check Expiration
```dart
final isExpired = JwtService.isTokenExpired(token);
final remaining = JwtService.getTokenExpirationTime(token);
// remaining: Duration(hours: 20, minutes: 30, ...)
```

### 5. Get Specific Claim
```dart
final email = JwtService.getClaim(token, 'email');
final userId = JwtService.getClaim(token, 'userId');
final role = JwtService.getClaim(token, 'role');
```

### 6. Get All Claims
```dart
final allClaims = JwtService.getAllClaims(token);
print(allClaims); // {userId, email, fullName, role, iat, exp}
```

### 7. Refresh Token
```dart
final newToken = JwtService.refreshToken(oldToken);
// New token with same claims but fresh expiration
```

---

## 🧪 Testing JWT in Dart

### Test 1: Generate and Verify Token
```dart
void main() {
  // Generate token
  final token = JwtService.generateToken(
    userId: '123',
    email: 'test@example.com',
    fullName: 'Test User',
    role: 'user',
  );
  
  print('✅ Token generated: ${token.substring(0, 50)}...');
  
  // Verify token
  try {
    final claims = JwtService.verifyToken(token);
    print('✅ Token verified');
    print('Email: ${claims['email']}');
    print('Role: ${claims['role']}');
  } catch (e) {
    print('❌ Verification failed: $e');
  }
}
```

### Test 2: Check Expiration
```dart
void main() {
  final token = JwtService.generateToken(
    userId: '123',
    email: 'test@example.com',
    fullName: 'Test User',
    role: 'user',
    expiresInHours: 1, // Expires in 1 hour
  );
  
  final isExpired = JwtService.isTokenExpired(token);
  print('Expired: $isExpired'); // false
  
  final remaining = JwtService.getTokenExpirationTime(token);
  print('Expires in: ${remaining!.inMinutes} minutes');
}
```

### Test 3: Mock Backend Login
```dart
import 'services/mock_backend_server.dart';

void main() {
  // Simulate login request
  final response = MockBackendServer.handleRequest(
    'POST',
    '/api/auth/login',
    null,
    body: '{"email":"owner@demo.com","password":"password123"}',
  );
  
  if (response.success) {
    print('✅ Login successful');
    print('Token: ${response.data['token'].substring(0, 50)}...');
  } else {
    print('❌ Login failed: ${response.error}');
  }
}
```

### Test 4: Mock Backend Protected Endpoint
```dart
void main() {
  // First, login to get token
  final loginResponse = MockBackendServer.handleRequest(
    'POST',
    '/api/auth/login',
    null,
    body: '{"email":"owner@demo.com","password":"password123"}',
  );
  
  final token = loginResponse.data['token'];
  
  // Now use token to access protected endpoint
  final membersResponse = MockBackendServer.handleRequest(
    'GET',
    '/api/members',
    'Bearer $token', // Token in Authorization header
  );
  
  if (membersResponse.success) {
    print('✅ Members fetched: ${membersResponse.data}');
  } else {
    print('❌ Error: ${membersResponse.error}');
  }
}
```

---

## 📝 JWT Token Structure

Your token looks like this:
```
Header.Payload.Signature

eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.
SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

### Part 1: Header
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

### Part 2: Payload (Your Data)
```json
{
  "userId": "123",
  "email": "user@example.com",
  "fullName": "John Doe",
  "role": "owner",
  "iat": 1708679400,
  "exp": 1708765800
}
```
- `iat`: Issued at (timestamp)
- `exp`: Expires at (timestamp)

### Part 3: Signature
```
HMAC256(
  Base64(Header.Payload),
  JWT_SECRET
)
```

**Key Point:** If anyone modifies the token, the signature becomes invalid! ✅

---

## 🔐 Security Best Practices

### ✅ Good (Your Implementation)
- Same JWT_SECRET in Dart
- Token stored securely on device
- Token sent in Authorization header
- Token verified on each request
- Token expires automatically (24h)

### ⚠️ Production Improvements
- [ ] Use strong JWT_SECRET (64+ characters)
- [ ] Store JWT_SECRET in environment variables
- [ ] Implement token refresh endpoint
- [ ] Add rate limiting to login
- [ ] Log authentication attempts
- [ ] Monitor token usage
- [ ] Use HTTPS in production
- [ ] Rotate JWT_SECRET periodically

---

## 🎯 Integration with Your App

### Step 1: Login with JWT
In `login_viewmodel.dart`:
```dart
Future<void> signIn() async {
  try {
    final response = await _api.login(
      email: state.email,
      password: state.password,
    );

    final token = response['token']?.toString();
    if (token != null) {
      // Token is already a valid JWT from backend
      _api.setToken(token);
      
      // Optionally verify it
      try {
        final claims = JwtService.verifyToken(token);
        print('✅ Token is valid: ${claims['email']}');
      } catch (e) {
        print('⚠️ Token verification issue: $e');
      }
      
      state = state.copyWith(
        isLoggedIn: true,
        token: token,
        isLoginSuccessful: true,
      );
    }
  } catch (e) {
    print('❌ Login error: $e');
  }
}
```

### Step 2: Verify Token Periodically
```dart
// In dashboard or main screen
@override
void initState() {
  super.initState();
  _verifyToken();
}

void _verifyToken() {
  final token = apiService.getToken();
  if (token != null) {
    try {
      JwtService.verifyToken(token);
      print('✅ Token is still valid');
    } catch (e) {
      print('❌ Token expired or invalid');
      // Logout user
      logout();
    }
  }
}
```

### Step 3: Auto-Refresh Token Before Expiration
```dart
void _setupTokenRefresh() {
  final token = apiService.getToken();
  if (token != null) {
    final remaining = JwtService.getTokenExpirationTime(token);
    
    if (remaining != null && remaining.inMinutes < 5) {
      // Less than 5 minutes left, refresh token
      try {
        final newToken = JwtService.refreshToken(token);
        apiService.setToken(newToken);
        print('✅ Token refreshed');
      } catch (e) {
        print('❌ Token refresh failed: $e');
      }
    }
  }
}
```

---

## ✨ Summary

| Feature | Status | Where |
|---------|--------|-------|
| JWT Generation | ✅ Done | `JwtService.generateToken()` |
| JWT Verification | ✅ Done | `JwtService.verifyToken()` |
| Token Expiration | ✅ Done | `JwtService.isTokenExpired()` |
| Mock Backend | ✅ Done | `MockBackendServer` |
| Token Storage | ✅ Done | Secure storage via ApiService |
| Token in Headers | ✅ Done | ApiService adds Bearer token |
| Login Integration | ✅ Done | LoginViewModel |
| Logout | ✅ Done | DrawerViewModel |

---

## 🚀 You're Ready!

Your Flutter app now has:
- ✅ Pure Dart JWT implementation
- ✅ Token generation & verification
- ✅ Mock backend server in Dart
- ✅ Secure token storage
- ✅ Automatic token expiration handling
- ✅ No Node.js required! 🎉

**Everything is in Dart. Everything works together seamlessly.**


