// backend/routes/auth.js
// Complete login endpoint with hardcoded JWT_SECRET

const express = require('express');
const jwt = require('jsonwebtoken');
const router = express.Router();

// ⭐ HARDCODED JWT_SECRET
const JWT_SECRET = 'your-super-secret-jwt-key-change-this-in-production';

// Login endpoint
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  console.log('Login attempt:', email);

  try {
    // ⭐ DEMO: Accept demo credentials
    // In production, verify against database
    if (email === 'owner@demo.com' && password === 'password123') {

      // Generate JWT token
      const token = jwt.sign(
        {
          userId: '123',
          email: email,
          fullName: 'Demo User',
          role: 'owner'
        },
        JWT_SECRET,
        { expiresIn: '24h' }
      );

      console.log('✅ Login successful, token generated');

      // Return token to Flutter app
      return res.json({
        success: true,
        token,
        user: {
          id: '123',
          email: email,
          fullName: 'Demo User',
          role: 'owner'
        }
      });
    }

    // Invalid credentials
    console.log('❌ Invalid credentials for:', email);
    res.status(401).json({
      error: 'Invalid credentials',
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

// Authentication middleware for protected routes
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({
      error: 'No token provided',
      success: false
    });
  }

  // Extract token from "Bearer <token>"
  if (!authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Invalid token format',
      success: false
    });
  }

  const token = authHeader.slice(7);

  try {
    // ⭐ VERIFY TOKEN with same JWT_SECRET
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    console.log('✅ Token verified for user:', decoded.email);
    next();
  } catch (error) {
    console.error('Token verification failed:', error.message);
    res.status(401).json({
      error: 'Invalid or expired token',
      success: false
    });
  }
}

module.exports = { router, authMiddleware };

