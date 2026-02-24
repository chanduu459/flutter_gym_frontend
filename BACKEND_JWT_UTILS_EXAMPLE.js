// backend/utils/jwt.js
// Using hardcoded JWT_SECRET directly in code

const jwt = require('jsonwebtoken');

// ⭐ HARDCODED JWT_SECRET
const JWT_SECRET = 'your-super-secret-jwt-key-change-this-in-production';

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

