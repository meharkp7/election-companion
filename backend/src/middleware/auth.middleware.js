const admin = require('../config/firebase');

const verifyFirebaseToken = async (req, res, next) => {
  // Development bypass for emulator/local testing without Firebase setup
  if (process.env.NODE_ENV !== 'production' || process.env.DEV_MODE === 'true') {
    const isPlaceholder = req.params?.firebaseUid === 'dev_user_placeholder';
    if (isPlaceholder) {
      req.user = { uid: 'dev_user_placeholder' };
      return next();
    }
  }

  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'No token provided' });
    }
    const token = authHeader.split('Bearer ')[1];
    const decoded = await admin.auth().verifyIdToken(token);
    req.user = decoded; // uid, phone_number, etc.
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
};

module.exports = { verifyFirebaseToken };