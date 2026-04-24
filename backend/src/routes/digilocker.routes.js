// routes/digilocker.routes.js
// DigiLocker OAuth and API endpoints

const express = require('express');
const router = express.Router();
const {
  initiateDigiLockerAuth,
  exchangeCodeForToken,
  fetchDigiLockerProfile,
  fetchDigiLockerDocuments,
  fetchEAadhaarFromDigiLocker,
  getDigiLockerStatus,
  unlinkDigiLocker,
  isDigiLockerConfigured,
} = require('../services/digilocker.service');
const { logAudit } = require('../middleware/audit.middleware');

// ==========================================
// DIGILOCKER OAUTH
// ==========================================

/**
 * GET /api/digilocker/auth-url
 * Get DigiLocker authorization URL
 */
router.get('/auth-url/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    if (!isDigiLockerConfigured()) {
      return res.status(503).json({
        success: false,
        error: 'DigiLocker integration not configured',
        message: 'Please contact support to enable DigiLocker integration',
      });
    }

    const result = await initiateDigiLockerAuth(userId);

    await logAudit(userId, 'digilocker_auth_initiated', {
      state: result.state,
    });

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error('DigiLocker auth URL error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /api/digilocker/callback
 * Handle DigiLocker OAuth callback
 */
router.post('/callback', async (req, res) => {
  try {
    const { userId, code, state } = req.body;

    if (!userId || !code || !state) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: userId, code, state',
      });
    }

    const result = await exchangeCodeForToken(userId, code, state);

    await logAudit(userId, 'digilocker_linked', {
      success: true,
    });

    res.json({
      success: true,
      message: 'DigiLocker linked successfully',
      data: result,
    });
  } catch (error) {
    console.error('DigiLocker callback error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ==========================================
// DIGILOCKER STATUS & PROFILE
// ==========================================

/**
 * GET /api/digilocker/status/:userId
 * Check DigiLocker connection status
 */
router.get('/status/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const status = await getDigiLockerStatus(userId);

    res.json({
      success: true,
      data: status,
    });
  } catch (error) {
    console.error('DigiLocker status error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/digilocker/profile/:userId
 * Fetch user profile from DigiLocker
 */
router.get('/profile/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const profile = await fetchDigiLockerProfile(userId);

    res.json({
      success: true,
      data: profile,
    });
  } catch (error) {
    console.error('DigiLocker profile error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/digilocker/documents/:userId
 * List documents from DigiLocker
 */
router.get('/documents/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const documents = await fetchDigiLockerDocuments(userId);

    res.json({
      success: true,
      data: documents,
    });
  } catch (error) {
    console.error('DigiLocker documents error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ==========================================
// DOCUMENT FETCHING
// ==========================================

/**
 * GET /api/digilocker/eaadhaar/:userId
 * Fetch eAadhaar from DigiLocker
 */
router.get('/eaadhaar/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const result = await fetchEAadhaarFromDigiLocker(userId);

    await logAudit(userId, 'digilocker_eaadhaar_fetched', {
      available: result.available,
    });

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error('DigiLocker eAadhaar error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ==========================================
// ACCOUNT MANAGEMENT
// ==========================================

/**
 * POST /api/digilocker/unlink
 * Unlink DigiLocker from user account
 */
router.post('/unlink', async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'Missing required field: userId',
      });
    }

    const result = await unlinkDigiLocker(userId);

    await logAudit(userId, 'digilocker_unlinked', {
      success: true,
    });

    res.json({
      success: true,
      message: result.message,
    });
  } catch (error) {
    console.error('DigiLocker unlink error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
