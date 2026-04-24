const express = require('express');
const router = express.Router();
const { getElectionInfo } = require('../controllers/election.controller');

router.get('/info', getElectionInfo);

module.exports = router;