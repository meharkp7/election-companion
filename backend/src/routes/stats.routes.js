const express = require('express');
const router = express.Router();
const { getStats, getTurnoutStats, getCacheStats } = require('../controllers/stats.controller');
const { verifyFirebaseToken } = require('../middleware/auth.middleware');

// Overall app stats (cached, auth-protected)
router.get('/', verifyFirebaseToken, getStats);

// BigQuery-backed turnout analytics by state
router.get('/turnout', verifyFirebaseToken, getTurnoutStats);

// Cache health metrics (internal monitoring)
router.get('/cache', getCacheStats);

module.exports = router;
