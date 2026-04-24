const express = require('express');
const router = express.Router();
const { nextStep, getCurrentStep } = require('../controllers/assistant.controller');
const { verifyFirebaseToken } = require('../middleware/auth.middleware');

router.post('/next-step', nextStep);
router.get('/current-step/:firebaseUid', verifyFirebaseToken, getCurrentStep);

module.exports = router;