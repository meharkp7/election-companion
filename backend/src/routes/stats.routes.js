const express = require('express');
const router = express.Router();
const { getStats } = require('../controllers/stats.controller');
const { verifyFirebaseToken } = require('../middleware/auth.middleware');

router.get('/', verifyFirebaseToken, getStats);

module.exports = router;