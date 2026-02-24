// backend/server.js
// Main server file with hardcoded JWT_SECRET

const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = process.env.PORT || 3001;

// ⭐ HARDCODED JWT_SECRET
const JWT_SECRET = 'your-super-secret-jwt-key-change-this-in-production';

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

console.log('✅ Server initializing...');
console.log('✅ JWT_SECRET loaded');

// ============================================
// AUTHENTICATION MIDDLEWARE
// ============================================

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({
      error: 'No token provided',
      success: false
    });
  }

  if (!authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Invalid token format',
      success: false
    });
  }

  const token = authHeader.slice(7);

  try {
    // Verify token with same JWT_SECRET
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    console.log('✅ Token verified for:', decoded.email);
    next();
  } catch (error) {
    console.error('❌ Token verification failed:', error.message);
    res.status(401).json({
      error: 'Invalid or expired token',
      success: false
    });
  }
}

// ============================================
// LOGIN ENDPOINT (PUBLIC)
// ============================================

app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;

  console.log(`📝 Login request from: ${email}`);

  try {
    // Demo: Accept demo credentials
    if (email === 'owner@demo.com' && password === 'password123') {

      // Generate JWT token
      const token = jwt.sign(
        {
          userId: '123',
          email: email,
          fullName: 'Demo Owner',
          role: 'owner'
        },
        JWT_SECRET,
        { expiresIn: '24h' }
      );

      console.log('✅ Login successful');

      return res.json({
        success: true,
        token,
        user: {
          id: '123',
          email: email,
          fullName: 'Demo Owner',
          role: 'owner'
        }
      });
    }

    // Invalid credentials
    console.log('❌ Invalid credentials');
    res.status(401).json({
      error: 'Invalid email or password',
      success: false
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      error: error.message,
      success: false
    });
  }
});

// ============================================
// PROTECTED ENDPOINTS
// ============================================

app.get('/api/members', authMiddleware, (req, res) => {
  console.log('📋 Fetching members for:', req.user.email);

  // Demo data
  res.json({
    success: true,
    data: [
      {
        id: '1',
        fullName: 'John Doe',
        email: 'john@example.com',
        phone: '1234567890',
        joinDate: '2024-01-15'
      },
      {
        id: '2',
        fullName: 'Jane Smith',
        email: 'jane@example.com',
        phone: '0987654321',
        joinDate: '2024-02-01'
      }
    ]
  });
});

app.post('/api/members', authMiddleware, (req, res) => {
  const { fullName, email, phone } = req.body;

  console.log('➕ Creating member:', fullName);

  if (!fullName || !email || !phone) {
    return res.status(400).json({
      success: false,
      error: 'Missing required fields'
    });
  }

  res.json({
    success: true,
    data: {
      id: Date.now().toString(),
      fullName,
      email,
      phone,
      joinDate: new Date().toISOString().split('T')[0]
    }
  });
});

app.get('/api/dashboard/stats', authMiddleware, (req, res) => {
  console.log('📊 Fetching dashboard stats for:', req.user.email);

  res.json({
    success: true,
    data: {
      totalMembers: 150,
      activeSubscriptions: 120,
      expiringIn7Days: 8,
      monthlyRevenue: 15000,
      revenueGrowth: 12.5
    }
  });
});

app.get('/api/plans', authMiddleware, (req, res) => {
  console.log('📋 Fetching plans');

  res.json({
    success: true,
    data: [
      {
        id: '1',
        name: 'Basic',
        price: 50,
        durationDays: 30,
        description: 'Basic gym membership'
      },
      {
        id: '2',
        name: 'Premium',
        price: 100,
        durationDays: 30,
        description: 'Premium gym membership'
      }
    ]
  });
});

app.get('/api/subscriptions', authMiddleware, (req, res) => {
  console.log('📋 Fetching subscriptions');

  res.json({
    success: true,
    data: [
      {
        id: '1',
        userId: '1',
        planId: '1',
        memberName: 'John Doe',
        email: 'john@example.com',
        phone: '1234567890',
        planName: 'Basic',
        planPrice: 50,
        startDate: '2024-01-15',
        expiryDate: '2024-02-15',
        status: 'active',
        daysRemaining: 10
      }
    ]
  });
});

// ============================================
// HEALTH CHECK (PUBLIC)
// ============================================

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Server is running',
    timestamp: new Date().toISOString()
  });
});

// ============================================
// ERROR HANDLING
// ============================================

app.use((err, req, res, next) => {
  console.error('🔴 Server error:', err);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: err.message
  });
});

// ============================================
// START SERVER
// ============================================

app.listen(PORT, () => {
  console.log('\n' + '='.repeat(50));
  console.log('✅ Server started successfully!');
  console.log('='.repeat(50));
  console.log(`📍 Running on: http://localhost:${PORT}`);
  console.log(`✅ JWT_SECRET configured`);
  console.log(`📝 Demo credentials: owner@demo.com / password123`);
  console.log('='.repeat(50) + '\n');
});

