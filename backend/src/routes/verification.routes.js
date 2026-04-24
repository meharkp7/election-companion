// routes/verification.routes.js
// Government-grade verification API endpoints

const express = require('express');
const router = express.Router();
const {
  processDocumentUpload,
  initiateAadhaarEKYC,
  verifyAadhaarOTP,
  verifyVoterID,
} = require('../services/verification.service');
const { logAudit } = require('../middleware/audit.middleware');

// ==========================================
// DOCUMENT UPLOAD & OCR
// ==========================================

/**
 * POST /api/verification/document
 * Upload and OCR a government ID document
 */
router.post('/document', async (req, res) => {
  try {
    const { userId, documentType, imageUrls } = req.body;
    
    if (!userId || !documentType || !imageUrls?.front) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: userId, documentType, imageUrls.front',
      });
    }
    
    const result = await processDocumentUpload(userId, documentType, imageUrls);
    
    // Log audit
    await logAudit(userId, 'document_upload', {
      documentType,
      documentId: result.documentId,
      confidence: result.confidence,
    });
    
    res.json({
      success: true,
      data: result,
    });
    
  } catch (error) {
    console.error('Document upload error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ==========================================
// AADHAAR E-KYC
// ==========================================

/**
 * POST /api/verification/aadhaar/initiate
 * Initiate Aadhaar E-KYC (sends OTP)
 */
router.post('/aadhaar/initiate', async (req, res) => {
  try {
    const { userId, aadhaarNumber } = req.body;
    
    if (!userId || !aadhaarNumber) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: userId, aadhaarNumber',
      });
    }
    
    // Validate Aadhaar format (12 digits)
    if (!/^\d{12}$/.test(aadhaarNumber.replace(/\s/g, ''))) {
      return res.status(400).json({
        success: false,
        error: 'Invalid Aadhaar number format',
      });
    }
    
    const result = await initiateAadhaarEKYC(userId, aadhaarNumber);
    
    // Log audit
    await logAudit(userId, 'aadhaar_initiate', {
      maskedAadhaar: result.maskedAadhaar,
    });
    
    res.json({
      success: true,
      data: result,
    });
    
  } catch (error) {
    console.error('Aadhaar initiation error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /api/verification/aadhaar/verify-otp
 * Verify Aadhaar OTP and complete E-KYC
 */
router.post('/aadhaar/verify-otp', async (req, res) => {
  try {
    const { userId, otp } = req.body;
    
    if (!userId || !otp) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: userId, otp',
      });
    }
    
    const result = await verifyAadhaarOTP(userId, otp);
    
    // Log audit
    await logAudit(userId, 'aadhaar_verify', {
      success: result.success,
    });
    
    res.json(result);
    
  } catch (error) {
    console.error('Aadhaar OTP verification error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ==========================================
// VOTER ID (EPIC) VERIFICATION
// ==========================================

/**
 * POST /api/verification/voter-id
 * Verify Voter ID (EPIC) against ECI database
 */
router.post('/voter-id', async (req, res) => {
  try {
    const { userId, epicNumber, state } = req.body;
    
    if (!userId || !epicNumber || !state) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: userId, epicNumber, state',
      });
    }
    
    const result = await verifyVoterID(userId, epicNumber, state);
    
    // Log audit
    await logAudit(userId, 'voter_id_verify', {
      epicNumber,
      state,
      success: result.success,
    });
    
    res.json(result);
    
  } catch (error) {
    console.error('Voter ID verification error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ==========================================
// VERIFICATION STATUS
// ==========================================

/**
 * GET /api/verification/status/:userId
 * Get user's verification status
 */
router.get('/status/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { query } = require('../config/postgres');
    
    const status = await query(
      `SELECT 
         u.verification_status,
         u.verification_level,
         u.verified_at,
         (SELECT COUNT(*) FROM verification_documents WHERE user_id = u.id) as documents_uploaded,
         (SELECT ekyc_status FROM aadhaar_verifications WHERE user_id = u.id LIMIT 1) as aadhaar_status,
         (SELECT eci_verification_status FROM voter_id_verifications WHERE user_id = u.id LIMIT 1) as voter_id_status
       FROM users u
       WHERE u.id = $1`,
      [userId]
    );
    
    if (status.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }
    
    res.json({
      success: true,
      data: status[0],
    });
    
  } catch (error) {
    console.error('Verification status error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
