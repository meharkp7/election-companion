/**
 * Firebase App Check middleware
 * Verifies that requests come from genuine app instances,
 * protecting backend APIs from abuse.
 *
 * Docs: https://firebase.google.com/docs/app-check/custom-resource-backend
 */

const admin = require('../config/firebase');

/**
 * Verify Firebase App Check token from the X-Firebase-AppCheck header.
 * In development / test mode the check is skipped so local dev still works.
 */
const verifyAppCheck = async (req, res, next) => {
  // Skip in non-production environments
  if (process.env.NODE_ENV !== 'production') {
    return next();
  }

  const appCheckToken = req.headers['x-firebase-appcheck'];

  if (!appCheckToken) {
    return res.status(401).json({
      error: 'App Check token missing',
      code: 'APP_CHECK_REQUIRED',
    });
  }

  try {
    const appCheckClaims = await admin.appCheck().verifyToken(appCheckToken);
    // Attach claims to request for downstream use
    req.appCheckClaims = appCheckClaims;
    next();
  } catch (err) {
    console.warn('App Check verification failed:', err.message);
    return res.status(401).json({
      error: 'Invalid App Check token',
      code: 'APP_CHECK_INVALID',
    });
  }
};

module.exports = { verifyAppCheck };
