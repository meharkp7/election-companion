const express = require('express');
const router = express.Router();
const { onboardUser, getUser, updateNotifications, updateBooth } = require('../controllers/user.controller');
const { verifyFirebaseToken } = require('../middleware/auth.middleware');

router.post('/onboard', onboardUser);
router.get('/:firebaseUid', verifyFirebaseToken, getUser);
router.patch('/:firebaseUid/notifications', verifyFirebaseToken, updateNotifications);
router.patch('/:firebaseUid/booth', verifyFirebaseToken, updateBooth);

module.exports = router;