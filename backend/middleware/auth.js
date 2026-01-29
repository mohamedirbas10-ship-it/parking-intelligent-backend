const jwt = require("jsonwebtoken");
const User = require("../models/User");

// This will be set by server.js
let useFallbackStorage = false;
let memoryUsers = [];

// Function to set fallback storage mode (called from server.js)
const setFallbackStorage = (useFallback, users) => {
  useFallbackStorage = useFallback;
  memoryUsers = users;
};

// Middleware to verify JWT token
const authenticate = async (req, res, next) => {
  try {
    // Get token from header
    const token = req.header("Authorization")?.replace("Bearer ", "");

    if (!token) {
      return res.status(401).json({
        success: false,
        error: "Authentication required. Please provide a token.",
      });
    }

    // Verify token
    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET || "your-secret-key",
    );

    // Find user based on storage mode
    let user;

    if (useFallbackStorage) {
      // Use memory storage
      user = memoryUsers.find((u) => u.id === decoded.userId);

      if (!user) {
        return res.status(401).json({
          success: false,
          error: "User not found. Token may be invalid.",
        });
      }

      // Attach user to request (memory storage format)
      req.user = user;
      req.userId = user.id;
      req.token = token;
    } else {
      // Use MongoDB
      user = await User.findById(decoded.userId);

      if (!user) {
        return res.status(401).json({
          success: false,
          error: "User not found. Token may be invalid.",
        });
      }

      // Attach user to request (MongoDB format)
      req.user = user;
      req.userId = user._id;
      req.token = token;
    }

    next();
  } catch (error) {
    console.error("❌ Authentication error:", error.message);

    if (error.name === "JsonWebTokenError") {
      return res.status(401).json({
        success: false,
        error: "Invalid token. Please log in again.",
      });
    }

    if (error.name === "TokenExpiredError") {
      return res.status(401).json({
        success: false,
        error: "Token expired. Please log in again.",
      });
    }

    return res.status(500).json({
      success: false,
      error: "Authentication failed.",
    });
  }
};

// Optional authentication (doesn't fail if no token)
const optionalAuth = async (req, res, next) => {
  try {
    const token = req.header("Authorization")?.replace("Bearer ", "");

    if (token) {
      const decoded = jwt.verify(
        token,
        process.env.JWT_SECRET || "your-secret-key",
      );

      if (useFallbackStorage) {
        // Use memory storage
        const user = memoryUsers.find((u) => u.id === decoded.userId);

        if (user) {
          req.user = user;
          req.userId = user.id;
          req.token = token;
        }
      } else {
        // Use MongoDB
        const user = await User.findById(decoded.userId);

        if (user) {
          req.user = user;
          req.userId = user._id;
          req.token = token;
        }
      }
    }

    next();
  } catch (error) {
    // If optional auth fails, just continue without user
    next();
  }
};

// Generate JWT token
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET || "your-secret-key", {
    expiresIn: process.env.JWT_EXPIRES_IN || "7d",
  });
};

module.exports = {
  authenticate,
  optionalAuth,
  generateToken,
  setFallbackStorage,
};
