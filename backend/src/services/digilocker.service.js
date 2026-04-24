// services/digilocker.service.js
// DigiLocker OAuth 2.0 integration for secure document access
// https://www.digitallocker.gov.in/public/dashboardapi

const { query } = require('../config/postgres');
const crypto = require('crypto');

// DigiLocker Configuration
const DIGILOCKER_CONFIG = {
  authEndpoint: process.env.DIGILOCKER_AUTH_URL || 'https://digilocker.meripehchaan.gov.in/public/oauth2/1/authorize',
  tokenEndpoint: process.env.DIGILOCKER_TOKEN_URL || 'https://digilocker.meripehchaan.gov.in/public/oauth2/1/token',
  apiEndpoint: process.env.DIGILOCKER_API_URL || 'https://digilocker.meripehchaan.gov.in/public/api/1',
  clientId: process.env.DIGILOCKER_CLIENT_ID,
  clientSecret: process.env.DIGILOCKER_CLIENT_SECRET,
  redirectUri: process.env.DIGILOCKER_REDIRECT_URI || 'https://voter-assistant-backend-260506723580.asia-south1.run.app/api/auth/digilocker/callback',
  scope: 'rvcr',
};

// Verification status constants
const DIGILOCKER_STATUS = {
  PENDING: 'pending',
  INITIATED: 'initiated',
  COMPLETED: 'completed',
  FAILED: 'failed',
};

/**
 * Check if DigiLocker is properly configured
 */
const isDigiLockerConfigured = () => {
  return !!(DIGILOCKER_CONFIG.clientId && DIGILOCKER_CONFIG.clientSecret);
};

/**
 * Generate PKCE code verifier and challenge for secure OAuth flow
 */
const generatePKCE = () => {
  const verifier = crypto.randomBytes(32).toString('base64url');
  const challenge = crypto
    .createHash('sha256')
    .update(verifier)
    .digest('base64url');
  return { verifier, challenge };
};

/**
 * Generate state parameter for CSRF protection
 */
const generateState = () => {
  return crypto.randomBytes(16).toString('hex');
};

/**
 * Initiate DigiLocker OAuth flow
 * Returns authorization URL and stores PKCE parameters
 */
async function initiateDigiLockerAuth(userId) {
  if (!isDigiLockerConfigured()) {
    throw new Error('DigiLocker not configured. Set DIGILOCKER_CLIENT_ID and DIGILOCKER_CLIENT_SECRET.');
  }

  const { verifier, challenge } = generatePKCE();
  const state = generateState();

  // Store PKCE parameters in database
  await query(
    `INSERT INTO digilocker_auth_sessions 
     (user_id, code_verifier, state, status, created_at)
     VALUES ($1, $2, $3, $4, NOW())
     ON CONFLICT (user_id) DO UPDATE SET
     code_verifier = $2,
     state = $3,
     status = $4,
     created_at = NOW()`,
    [userId, verifier, state, DIGILOCKER_STATUS.INITIATED]
  );

  // Build authorization URL
  const authUrl = new URL(DIGILOCKER_CONFIG.authEndpoint);
  authUrl.searchParams.append('client_id', DIGILOCKER_CONFIG.clientId);
  authUrl.searchParams.append('redirect_uri', DIGILOCKER_CONFIG.redirectUri);
  authUrl.searchParams.append('response_type', 'code');
  authUrl.searchParams.append('state', state);
  authUrl.searchParams.append('code_challenge', challenge);
  authUrl.searchParams.append('code_challenge_method', 'S256');
  authUrl.searchParams.append('scope', DIGILOCKER_CONFIG.scope);

  return {
    authUrl: authUrl.toString(),
    state,
  };
}

/**
 * Exchange authorization code for access token
 */
async function exchangeCodeForToken(userId, code, state) {
  // Verify state and get code verifier
  const sessionResult = await query(
    `SELECT code_verifier, state, status 
     FROM digilocker_auth_sessions 
     WHERE user_id = $1 
     AND created_at > NOW() - INTERVAL '10 minutes'`,
    [userId]
  );

  if (sessionResult.length === 0) {
    throw new Error('Invalid or expired authorization session');
  }

  const session = sessionResult[0];

  if (session.state !== state) {
    throw new Error('Invalid state parameter - possible CSRF attack');
  }

  // Exchange code for token
  const tokenResponse = await fetch(DIGILOCKER_CONFIG.tokenEndpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      code,
      grant_type: 'authorization_code',
      client_id: DIGILOCKER_CONFIG.clientId,
      client_secret: DIGILOCKER_CONFIG.clientSecret,
      redirect_uri: DIGILOCKER_CONFIG.redirectUri,
      code_verifier: session.code_verifier,
    }),
  });

  if (!tokenResponse.ok) {
    const errorData = await tokenResponse.text();
    throw new Error(`Token exchange failed: ${errorData}`);
  }

  const tokenData = await tokenResponse.json();

  // Store tokens securely
  await query(
    `UPDATE digilocker_auth_sessions 
     SET access_token = $1,
         refresh_token = $2,
         expires_at = NOW() + INTERVAL '${tokenData.expires_in} seconds',
         status = $3,
         updated_at = NOW()
     WHERE user_id = $4`,
    [tokenData.access_token, tokenData.refresh_token, DIGILOCKER_STATUS.COMPLETED, userId]
  );

  // Also update user record
  await query(
    `UPDATE users 
     SET digilocker_linked = TRUE,
         digilocker_linked_at = NOW(),
         updated_at = NOW()
     WHERE id = $1`,
    [userId]
  );

  return {
    success: true,
    accessToken: tokenData.access_token,
    expiresIn: tokenData.expires_in,
  };
}

/**
 * Fetch user profile from DigiLocker
 */
async function fetchDigiLockerProfile(userId) {
  const tokenResult = await query(
    `SELECT access_token 
     FROM digilocker_auth_sessions 
     WHERE user_id = $1 
     AND status = $2
     AND expires_at > NOW()`,
    [userId, DIGILOCKER_STATUS.COMPLETED]
  );

  if (tokenResult.length === 0) {
    throw new Error('DigiLocker not linked or token expired');
  }

  const accessToken = tokenResult[0].access_token;

  const response = await fetch(`${DIGILOCKER_CONFIG.apiEndpoint}/user`, {
    headers: {
      'Authorization': `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    throw new Error('Failed to fetch DigiLocker profile');
  }

  return await response.json();
}

/**
 * Fetch documents list from DigiLocker
 */
async function fetchDigiLockerDocuments(userId) {
  const tokenResult = await query(
    `SELECT access_token 
     FROM digilocker_auth_sessions 
     WHERE user_id = $1 
     AND status = $2
     AND expires_at > NOW()`,
    [userId, DIGILOCKER_STATUS.COMPLETED]
  );

  if (tokenResult.length === 0) {
    throw new Error('DigiLocker not linked or token expired');
  }

  const accessToken = tokenResult[0].access_token;

  const response = await fetch(`${DIGILOCKER_CONFIG.apiEndpoint}/documents`, {
    headers: {
      'Authorization': `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    throw new Error('Failed to fetch documents');
  }

  return await response.json();
}

/**
 * Fetch specific document (e.g., Aadhaar, Voter ID) from DigiLocker
 */
async function fetchDigiLockerDocument(userId, documentId) {
  const tokenResult = await query(
    `SELECT access_token 
     FROM digilocker_auth_sessions 
     WHERE user_id = $1 
     AND status = $2
     AND expires_at > NOW()`,
    [userId, DIGILOCKER_STATUS.COMPLETED]
  );

  if (tokenResult.length === 0) {
    throw new Error('DigiLocker not linked or token expired');
  }

  const accessToken = tokenResult[0].access_token;

  const response = await fetch(
    `${DIGILOCKER_CONFIG.apiEndpoint}/documents/${documentId}`,
    {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    }
  );

  if (!response.ok) {
    throw new Error('Failed to fetch document');
  }

  return await response.json();
}

/**
 * Get eAadhaar from DigiLocker (if available)
 */
async function fetchEAadhaarFromDigiLocker(userId) {
  try {
    const documents = await fetchDigiLockerDocuments(userId);
    
    // Look for Aadhaar document
    const aadhaarDoc = documents.items?.find(
      (doc) => doc.doctype === 'ADHAAR' || doc.name?.toLowerCase().includes('aadhaar')
    );

    if (!aadhaarDoc) {
      return { available: false, message: 'Aadhaar not found in DigiLocker' };
    }

    const aadhaarData = await fetchDigiLockerDocument(userId, aadhaarDoc.id);

    // Store eAadhaar reference
    await query(
      `INSERT INTO digilocker_documents 
       (user_id, document_type, digilocker_doc_id, doc_name, uri, fetched_at)
       VALUES ($1, $2, $3, $4, $5, NOW())
       ON CONFLICT (user_id, document_type) DO UPDATE SET
       digilocker_doc_id = $3,
       doc_name = $4,
       uri = $5,
       fetched_at = NOW()`,
      [userId, 'aadhaar', aadhaarDoc.id, aadhaarDoc.name, aadhaarData.uri]
    );

    return {
      available: true,
      documentId: aadhaarDoc.id,
      name: aadhaarDoc.name,
      uri: aadhaarData.uri,
    };
  } catch (error) {
    console.error('Failed to fetch eAadhaar:', error);
    return { available: false, error: error.message };
  }
}

/**
 * Check DigiLocker connection status
 */
async function getDigiLockerStatus(userId) {
  const result = await query(
    `SELECT status, expires_at, digilocker_linked
     FROM digilocker_auth_sessions 
     LEFT JOIN users ON users.id = digilocker_auth_sessions.user_id
     WHERE digilocker_auth_sessions.user_id = $1`,
    [userId]
  );

  if (result.length === 0) {
    return { linked: false, status: 'not_initiated' };
  }

  const isExpired = new Date(result[0].expires_at) < new Date();

  return {
    linked: result[0].status === DIGILOCKER_STATUS.COMPLETED && !isExpired,
    status: result[0].status,
    expired: isExpired,
  };
}

/**
 * Refresh expired access token
 */
async function refreshDigiLockerToken(userId) {
  const sessionResult = await query(
    `SELECT refresh_token 
     FROM digilocker_auth_sessions 
     WHERE user_id = $1 
     AND status = $2`,
    [userId, DIGILOCKER_STATUS.COMPLETED]
  );

  if (sessionResult.length === 0) {
    throw new Error('No refresh token available');
  }

  const refreshToken = sessionResult[0].refresh_token;

  const response = await fetch(DIGILOCKER_CONFIG.tokenEndpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      client_id: DIGILOCKER_CONFIG.clientId,
      client_secret: DIGILOCKER_CONFIG.clientSecret,
      refresh_token: refreshToken,
    }),
  });

  if (!response.ok) {
    throw new Error('Token refresh failed');
  }

  const tokenData = await response.json();

  await query(
    `UPDATE digilocker_auth_sessions 
     SET access_token = $1,
         refresh_token = $2,
         expires_at = NOW() + INTERVAL '${tokenData.expires_in} seconds',
         updated_at = NOW()
     WHERE user_id = $3`,
    [tokenData.access_token, tokenData.refresh_token, userId]
  );

  return {
    success: true,
    accessToken: tokenData.access_token,
    expiresIn: tokenData.expires_in,
  };
}

/**
 * Unlink DigiLocker from user account
 */
async function unlinkDigiLocker(userId) {
  await query(
    `DELETE FROM digilocker_auth_sessions WHERE user_id = $1`,
    [userId]
  );

  await query(
    `UPDATE users 
     SET digilocker_linked = FALSE,
         digilocker_unlinked_at = NOW(),
         updated_at = NOW()
     WHERE id = $1`,
    [userId]
  );

  return { success: true, message: 'DigiLocker unlinked successfully' };
}

module.exports = {
  // Configuration check
  isDigiLockerConfigured,
  
  // OAuth flow
  initiateDigiLockerAuth,
  exchangeCodeForToken,
  
  // Data fetching
  fetchDigiLockerProfile,
  fetchDigiLockerDocuments,
  fetchDigiLockerDocument,
  fetchEAadhaarFromDigiLocker,
  
  // Token management
  refreshDigiLockerToken,
  getDigiLockerStatus,
  unlinkDigiLocker,
  
  // Constants
  DIGILOCKER_STATUS,
};
