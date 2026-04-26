// services/verification.service.js
// Government-grade verification with Aadhaar E-KYC and Voter ID validation

const { query } = require('../config/postgres');
const { generateText } = require('../config/vertexai');
const { enqueueDocumentProcessing } = require('./cloudTasks.service');
const { logVoterEvent } = require('./bigquery.service');

// ==========================================
// VERIFICATION LEVELS
// ==========================================
const VERIFICATION_LEVELS = {
  NONE: 0,      // No verification
  BASIC: 1,     // Phone verified
  DOCUMENT: 2,  // ID documents uploaded
  GOVT: 3,      // Aadhaar E-KYC or Voter ID verified
};

const VERIFICATION_STATUS = {
  UNVERIFIED: 'unverified',
  PENDING: 'pending',
  VERIFIED: 'verified',
  REJECTED: 'rejected',
};

// ==========================================
// DOCUMENT UPLOAD & OCR
// ==========================================

/**
 * Process document upload with AI-powered OCR using Vertex AI
 * Uses Cloud Tasks for async processing to improve response times
 */
async function processDocumentUpload(userId, documentType, imageUrls) {
  try {
    // Create document record with pending status
    const docResult = await query(
      `INSERT INTO verification_documents 
       (user_id, document_type, front_image_url, back_image_url, verification_result)
       VALUES ($1, $2, $3, $4, 'pending')
       RETURNING *`,
      [userId, documentType, imageUrls.front, imageUrls.back]
    );
    
    const document = docResult[0];

    // Get user for analytics
    const userResult = await query('SELECT firebase_uid FROM users WHERE id = $1', [userId]);
    const firebaseUid = userResult[0]?.firebase_uid;

    // Queue document processing asynchronously
    try {
      await enqueueDocumentProcessing(firebaseUid, imageUrls.front, documentType);
      console.log(`📄 Document processing queued for user ${userId}`);
    } catch (err) {
      console.warn('Failed to queue document processing, falling back to sync:', err.message);
      // Fallback to synchronous processing
      const ocrResult = await performOCROnDocument(documentType, imageUrls);
      await updateDocumentWithOCRResults(document.id, ocrResult);
      await updateUserVerificationStatus(userId);
    }

    // Log document upload event
    if (firebaseUid) {
      logVoterEvent(firebaseUid, 'document_uploaded', {
        documentType,
        documentId: document.id,
      }).catch(() => {});
    }
    
    return {
      documentId: document.id,
      status: 'processing',
      message: 'Document uploaded successfully. Processing in background.',
    };
    
  } catch (error) {
    console.error('Document upload processing failed:', error);
    throw error;
  }
}

/**
 * Process document synchronously (called by Cloud Tasks worker)
 */
async function processDocumentSync(firebaseUid, fileUrl, documentType) {
  try {
    // Get user ID from firebase UID
    const userResult = await query('SELECT id FROM users WHERE firebase_uid = $1', [firebaseUid]);
    if (userResult.length === 0) {
      throw new Error('User not found');
    }
    const userId = userResult[0].id;

    // Find the document record
    const docResult = await query(
      'SELECT * FROM verification_documents WHERE user_id = $1 AND document_type = $2 AND front_image_url = $3 ORDER BY created_at DESC LIMIT 1',
      [userId, documentType, fileUrl]
    );

    if (docResult.length === 0) {
      throw new Error('Document record not found');
    }

    const document = docResult[0];

    // Perform OCR
    const ocrResult = await performOCROnDocument(documentType, { front: fileUrl });
    
    // Update document with results
    await updateDocumentWithOCRResults(document.id, ocrResult);
    
    // Update user verification status
    await updateUserVerificationStatus(userId);

    // Log completion
    logVoterEvent(firebaseUid, 'document_processed', {
      documentType,
      documentId: document.id,
      confidence: ocrResult.confidence,
      isValid: ocrResult.confidence > 0.85,
    }).catch(() => {});

    console.log(`✅ Document processing completed for user ${firebaseUid}`);
    
  } catch (error) {
    console.error('Sync document processing failed:', error);
    throw error;
  }
}

/**
 * Update document record with OCR results
 */
async function updateDocumentWithOCRResults(documentId, ocrResult) {
  await query(
    `UPDATE verification_documents 
     SET ocr_raw_data = $1, 
         ocr_confidence = $2,
         verification_result = $3,
         updated_at = NOW()
     WHERE id = $4`,
    [
      JSON.stringify(ocrResult.extractedData),
      ocrResult.confidence,
      ocrResult.confidence > 0.85 ? 'approved' : 'flagged',
      documentId
    ]
  );
}

/**
 * Perform OCR on document using Vertex AI
 */
async function performOCROnDocument(documentType, imageUrls) {
  // Build prompt for Vertex AI Gemini
  const prompt = `
You are an expert OCR system for Indian government documents. 
Extract structured data from this ${documentType} image.

For ${documentType === 'aadhaar' ? 'Aadhaar' : 'Voter ID (EPIC)'} card, extract:
${documentType === 'aadhaar' ? `
- Name
- Aadhaar Number (masked format XXXX-XXXX-1234)
- Date of Birth or Age
- Gender
- Address (if visible)
- QR code data (if visible)
` : `
- EPIC Number
- Name
- Father/Husband Name
- Age
- Gender
- House Number
- Street/Area
- District
- State
- Polling Station Details
`}

Return ONLY a JSON object with this structure:
{
  "documentNumber": "string",
  "name": "string",
  "fatherHusbandName": "string",
  "dateOfBirth": "YYYY-MM-DD",
  "age": number,
  "gender": "MALE|FEMALE|TRANSGENDER",
  "address": {
    "houseNumber": "string",
    "street": "string",
    "area": "string",
    "district": "string",
    "state": "string",
    "pincode": "string"
  },
  "confidence": 0.95
}

Be precise. If a field is not visible, set it to null.
Confidence should be 0.0-1.0 based on clarity and readability.
`;

  try {
    const response = await generateText(prompt);
    
    // Parse the JSON response
    const extractedData = JSON.parse(response);
    const confidence = extractedData.confidence || 0.5;
    
    return {
      extractedData,
      confidence,
    };
    
  } catch (error) {
    console.error('OCR failed:', error);
    return {
      extractedData: {},
      confidence: 0.3,
    };
  }
}

// ==========================================
// AADHAAR E-KYC VERIFICATION
// ==========================================

/**
 * Initiate Aadhaar E-KYC verification (OTP-based)
 */
async function initiateAadhaarEKYC(userId, aadhaarNumber) {
  // Mask and hash the Aadhaar number for privacy
  const maskedNumber = maskAadhaarNumber(aadhaarNumber);
  const hashedNumber = hashAadhaarNumber(aadhaarNumber);
  
  try {
    // Check if already verified
    const existing = await query(
      'SELECT * FROM aadhaar_verifications WHERE user_id = $1 AND ekyc_status = $2',
      [userId, 'success']
    );
    
    if (existing.length > 0) {
      throw new Error('Aadhaar already verified for this user');
    }
    
    // Create verification record
    await query(
      `INSERT INTO aadhaar_verifications 
       (user_id, aadhaar_number_masked, aadhaar_hash, ekyc_status)
       VALUES ($1, $2, $3, 'otp_required')
       ON CONFLICT (user_id) DO UPDATE SET
       aadhaar_number_masked = $2,
       aadhaar_hash = $3,
       ekyc_status = 'otp_required',
       updated_at = NOW()`,
      [userId, maskedNumber, hashedNumber]
    );
    
    // TODO: Integrate with UIDAI E-KYC API
    // For now, return mock OTP transaction
    const mockTransactionId = `UID${Date.now()}`;
    
    await query(
      `UPDATE aadhaar_verifications 
       SET otp_transaction_id = $1,
           updated_at = NOW()
       WHERE user_id = $2`,
      [mockTransactionId, userId]
    );

    // Log Aadhaar initiation event
    const userResult = await query('SELECT firebase_uid FROM users WHERE id = $1', [userId]);
    const firebaseUid = userResult[0]?.firebase_uid;
    if (firebaseUid) {
      logVoterEvent(firebaseUid, 'aadhaar_ekyc_initiated', {
        maskedAadhaar: maskedNumber,
      }).catch(() => {});
    }
    
    return {
      transactionId: mockTransactionId,
      maskedAadhaar: maskedNumber,
      message: 'OTP sent to registered mobile number',
    };
    
  } catch (error) {
    console.error('Aadhaar E-KYC initiation failed:', error);
    throw error;
  }
}

/**
 * Verify Aadhaar OTP and complete E-KYC
 */
async function verifyAadhaarOTP(userId, otp) {
  try {
    // Get verification record
    const verifications = await query(
      'SELECT * FROM aadhaar_verifications WHERE user_id = $1',
      [userId]
    );
    
    if (verifications.length === 0) {
      throw new Error('Aadhaar verification not initiated');
    }
    
    const verification = verifications[0];
    
    // TODO: Call UIDAI API to verify OTP
    // For development, accept any 6-digit OTP
    if (!/^\d{6}$/.test(otp)) {
      throw new Error('Invalid OTP format');
    }
    
    // Mock successful E-KYC response
    const mockDemographicData = {
      name: 'John Doe',
      gender: 'M',
      dob: '1990-01-01',
      address: {
        co: 'S/O: Father Name',
        house: '123',
        street: 'Main Street',
        lm: 'Near Temple',
        loc: 'Area Name',
        vtc: 'City Name',
        dist: 'District',
        state: 'State',
        pc: '123456',
      },
      photo: 'base64_encoded_photo_data',
    };
    
    // Update verification record
    await query(
      `UPDATE aadhaar_verifications 
       SET ekyc_status = 'success',
           demographic_data = $1,
           otp_verified = TRUE,
           otp_verified_at = NOW(),
           consent_given = TRUE,
           consent_given_at = NOW(),
           updated_at = NOW()
       WHERE user_id = $2`,
      [JSON.stringify(mockDemographicData), userId]
    );
    
    // Update user's verification level
    await query(
      `UPDATE users 
       SET verification_status = 'verified',
           verification_level = 3,
           verified_at = NOW(),
           updated_at = NOW()
       WHERE id = $1`,
      [userId]
    );

    // Log successful verification
    const userResult = await query('SELECT firebase_uid FROM users WHERE id = $1', [userId]);
    const firebaseUid = userResult[0]?.firebase_uid;
    if (firebaseUid) {
      logVoterEvent(firebaseUid, 'aadhaar_ekyc_completed', {
        success: true,
        verificationLevel: 3,
      }).catch(() => {});
    }
    
    return {
      success: true,
      demographicData: mockDemographicData,
      message: 'Aadhaar E-KYC completed successfully',
    };
    
  } catch (error) {
    console.error('Aadhaar OTP verification failed:', error);
    throw error;
  }
}

// ==========================================
// VOTER ID (EPIC) VERIFICATION
// ==========================================

/**
 * Verify Voter ID (EPIC) against ECI database
 */
async function verifyVoterID(userId, epicNumber, stateName) {
  const normalizedEpic = epicNumber.toUpperCase().replace(/\s/g, '');
  
  try {
    // Check if EPIC already verified
    const existing = await query(
      'SELECT * FROM voter_id_verifications WHERE epic_number_normalized = $1',
      [normalizedEpic]
    );
    
    if (existing.length > 0 && existing[0].eci_verification_status === 'verified') {
      // Update user with existing verified data
      await query(
        `UPDATE users 
         SET verification_status = 'verified',
             verification_level = 3,
             voter_id_number = $1,
             verified_at = NOW(),
             updated_at = NOW()
         WHERE id = $2`,
        [epicNumber, userId]
      );
      
      return {
        success: true,
        message: 'Voter ID verified',
        data: existing[0],
      };
    }
    
    // TODO: Call ECI API for verification
    // Mock verification for development
    const mockVoterData = {
      epicNumber: normalizedEpic,
      name: 'John Doe',
      fatherHusbandName: 'Father Name',
      age: 30,
      gender: 'MALE',
      houseNumber: '123',
      street: 'Main Street',
      area: 'Area Name',
      district: 'District Name',
      state: stateName,
      pincode: '123456',
      pollingStationName: 'Government School',
      pollingStationNumber: '001',
      pcName: 'Parliamentary Constituency',
      pcNumber: '01',
      acName: 'Assembly Constituency',
      acNumber: '001',
    };
    
    // Create or update voter ID verification record
    await query(
      `INSERT INTO voter_id_verifications 
       (user_id, epic_number, epic_number_normalized, eci_verification_status,
        voter_name, father_husband_name, age, gender,
        house_number, street, area, district, state, pincode,
        polling_station_name, polling_station_number,
        pc_name, pc_number, ac_name, ac_number,
        verified_at, verification_method)
       VALUES ($1, $2, $3, 'verified', $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, NOW(), 'eci_api')
       ON CONFLICT (user_id) DO UPDATE SET
       epic_number = $2,
       epic_number_normalized = $3,
       eci_verification_status = 'verified',
       voter_name = $4,
       voter_name_verified = TRUE,
       age = $6,
       age_verified = TRUE,
       gender = $7,
       gender_verified = TRUE,
       polling_station_name = $14,
       polling_station_number = $15,
       pc_name = $16,
       pc_number = $17,
       ac_name = $18,
       ac_number = $19,
       verified_at = NOW(),
       updated_at = NOW()`,
      [
        userId, epicNumber, normalizedEpic,
        mockVoterData.name, mockVoterData.fatherHusbandName, 
        mockVoterData.age, mockVoterData.gender,
        mockVoterData.houseNumber, mockVoterData.street, mockVoterData.area,
        mockVoterData.district, mockVoterData.state, mockVoterData.pincode,
        mockVoterData.pollingStationName, mockVoterData.pollingStationNumber,
        mockVoterData.pcName, mockVoterData.pcNumber,
        mockVoterData.acName, mockVoterData.acNumber,
      ]
    );
    
    // Update user's booth information
    await query(
      `UPDATE users 
       SET verification_status = 'verified',
           verification_level = 3,
           voter_id_number = $1,
           booth_known = TRUE,
           booth_name = $2,
           booth_address = $3,
           verified_at = NOW(),
           updated_at = NOW()
       WHERE id = $4`,
      [
        epicNumber,
        mockVoterData.pollingStationName,
        `${mockVoterData.houseNumber}, ${mockVoterData.street}, ${mockVoterData.area}, ${mockVoterData.district}`,
        userId,
      ]
    );
    
    return {
      success: true,
      message: 'Voter ID verified successfully',
      voterData: mockVoterData,
    };
    
  } catch (error) {
    console.error('Voter ID verification failed:', error);
    throw error;
  }
}

// ==========================================
// HELPER FUNCTIONS
// ==========================================

function maskAadhaarNumber(number) {
  // Show only last 4 digits: XXXX-XXXX-1234
  const clean = number.replace(/\D/g, '');
  if (clean.length !== 12) throw new Error('Invalid Aadhaar number');
  return `XXXX-XXXX-${clean.slice(-4)}`;
}

function hashAadhaarNumber(number) {
  // SHA-256 hash for secure comparison
  const crypto = require('crypto');
  const clean = number.replace(/\D/g, '');
  return crypto.createHash('sha256').update(clean).digest('hex');
}

async function updateUserVerificationStatus(userId) {
  // Get user's documents
  const docs = await query(
    `SELECT 
       COUNT(*) as total,
       COUNT(CASE WHEN verification_result = 'approved' THEN 1 END) as approved,
       MAX(verification_score) as max_confidence
     FROM verification_documents 
     WHERE user_id = $1`,
    [userId]
  );
  
  const docStats = docs[0];
  
  // Determine verification level
  let level = VERIFICATION_LEVELS.NONE;
  let status = VERIFICATION_STATUS.UNVERIFIED;
  
  if (docStats.approved > 0) {
    level = VERIFICATION_LEVELS.DOCUMENT;
    status = VERIFICATION_STATUS.PENDING;
  }
  
  // Check for Aadhaar or Voter ID verification
  const govtVerifications = await query(
    `SELECT 
       (SELECT COUNT(*) FROM aadhaar_verifications WHERE user_id = $1 AND ekyc_status = 'success') as aadhaar_count,
       (SELECT COUNT(*) FROM voter_id_verifications WHERE user_id = $1 AND eci_verification_status = 'verified') as voter_count`,
    [userId]
  );
  
  if (govtVerifications[0].aadhaar_count > 0 || govtVerifications[0].voter_count > 0) {
    level = VERIFICATION_LEVELS.GOVT;
    status = VERIFICATION_STATUS.VERIFIED;
  }
  
  // Update user
  await query(
    `UPDATE users 
     SET verification_level = $1,
         verification_status = $2,
         updated_at = NOW()
     WHERE id = $3`,
    [level, status, userId]
  );
}

// ==========================================
// MODULE EXPORTS
// ==========================================
module.exports = {
  // Document upload
  processDocumentUpload,
  processDocumentSync,
  performOCROnDocument,
  updateDocumentWithOCRResults,
  
  // Aadhaar E-KYC
  initiateAadhaarEKYC,
  verifyAadhaarOTP,
  
  // Voter ID
  verifyVoterID,
  
  // Helpers
  updateUserVerificationStatus,
  VERIFICATION_LEVELS,
  VERIFICATION_STATUS,
};
