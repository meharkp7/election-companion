// routes/features.routes.js
// API Routes for all new features

const express = require('express');
const router = express.Router();
const documentAIService = require('../services/documentAI.service');
const candidateService = require('../services/candidate.service');
const complaintService = require('../services/complaint.service');
const boothCrowdsourceService = require('../services/boothCrowdsource.service');

// ==========================================
// DOCUMENT AI ROUTES
// ==========================================

// POST /api/features/document/analyze
// Analyze uploaded document with AI
router.post('/document/analyze', async (req, res, next) => {
  try {
    const { fileUrl, documentType } = req.body;
    
    if (!fileUrl || !documentType) {
      return res.status(400).json({ 
        message: 'fileUrl and documentType required' 
      });
    }
    
    const result = await documentAIService.analyzeDocument(fileUrl, documentType);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// POST /api/features/document/validate-for-booth
// Check if documents are valid before booth visit
router.post('/document/validate-for-booth', async (req, res, next) => {
  try {
    const { firebaseUid, documentType } = req.body;
    
    // Get user
    const UserModel = require('../models/user.model');
    const user = await UserModel.findByFirebaseUid(firebaseUid);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    const result = await documentAIService.validateForBoothVisit(user.id, documentType);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// POST /api/features/document/validate-all
// Validate all user documents
router.post('/document/validate-all', async (req, res, next) => {
  try {
    const { firebaseUid } = req.body;
    
    const UserModel = require('../models/user.model');
    const user = await UserModel.findByFirebaseUid(firebaseUid);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    const result = await documentAIService.validateAllDocuments(user.id);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// ==========================================
// CANDIDATE INTELLIGENCE ROUTES
// ==========================================

// GET /api/features/candidates/my-constituency
// Get candidates for user's constituency
router.get('/candidates/my-constituency/:firebaseUid', async (req, res, next) => {
  try {
    const result = await candidateService.getCandidatesForUser(req.params.firebaseUid);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/candidates/constituency
// Get candidates by constituency
router.get('/candidates/constituency', async (req, res, next) => {
  try {
    const { state, constituency } = req.query;
    
    if (!state || !constituency) {
      return res.status(400).json({ message: 'state and constituency required' });
    }
    
    const result = await candidateService.getCandidatesByConstituency(state, constituency);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// POST /api/features/candidates/compare
// Compare multiple candidates
router.post('/candidates/compare', async (req, res, next) => {
  try {
    const { candidateIds } = req.body;
    
    if (!candidateIds || candidateIds.length < 2) {
      return res.status(400).json({ message: 'At least 2 candidateIds required' });
    }
    
    const result = await candidateService.compareCandidates(candidateIds);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/candidates/:id
// Get detailed candidate profile
router.get('/candidates/:id', async (req, res, next) => {
  try {
    const result = await candidateService.getCandidateDetails(req.params.id);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// POST /api/features/candidates/recommendations
// Get candidate recommendations based on priorities
router.post('/candidates/recommendations', async (req, res, next) => {
  try {
    const { firebaseUid, priorities } = req.body;
    
    if (!firebaseUid || !priorities) {
      return res.status(400).json({ message: 'firebaseUid and priorities required' });
    }
    
    const result = await candidateService.getRecommendations(firebaseUid, priorities);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/candidates/search
// Search candidates
router.get('/candidates/search', async (req, res, next) => {
  try {
    const { q, state } = req.query;
    
    if (!q) {
      return res.status(400).json({ message: 'Query parameter q required' });
    }
    
    const result = await candidateService.searchCandidates(q, state);
    res.json({ candidates: result });
  } catch (err) {
    next(err);
  }
});

// ==========================================
// COMPLAINT/ESCALATION ROUTES
// ==========================================

// POST /api/features/complaints/file
// File a new complaint (one-tap)
router.post('/complaints/file', async (req, res, next) => {
  try {
    const { firebaseUid, complaintData } = req.body;
    
    if (!firebaseUid || !complaintData) {
      return res.status(400).json({ message: 'firebaseUid and complaintData required' });
    }
    
    const result = await complaintService.fileComplaint(firebaseUid, complaintData);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/complaints/my-complaints/:firebaseUid
// Get user's complaints
router.get('/complaints/my-complaints/:firebaseUid', async (req, res, next) => {
  try {
    const result = await complaintService.getUserComplaints(req.params.firebaseUid);
    res.json({ complaints: result });
  } catch (err) {
    next(err);
  }
});

// GET /api/features/complaints/:id
// Get complaint details
router.get('/complaints/:id', async (req, res, next) => {
  try {
    const { firebaseUid } = req.query;
    
    if (!firebaseUid) {
      return res.status(400).json({ message: 'firebaseUid query parameter required' });
    }
    
    const result = await complaintService.getComplaintDetails(req.params.id, firebaseUid);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/complaints/templates/:firebaseUid
// Get quick complaint templates
router.get('/complaints/templates/:firebaseUid', async (req, res, next) => {
  try {
    // Get user details for contextual templates
    const UserModel = require('../models/user.model');
    const user = await UserModel.findByFirebaseUid(req.params.firebaseUid);
    
    const templates = complaintService.getQuickComplaintTemplates({
      boothName: user?.boothName,
      constituency: user?.state,
    });
    
    res.json({ templates });
  } catch (err) {
    next(err);
  }
});

// GET /api/features/complaints/eci-contacts
// Get ECI helpline contacts
router.get('/complaints/eci-contacts', async (req, res, next) => {
  try {
    const { state } = req.query;
    const contacts = complaintService.getECIContacts(state);
    res.json(contacts);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/complaints/stats/:firebaseUid
// Get complaint statistics
router.get('/complaints/stats/:firebaseUid', async (req, res, next) => {
  try {
    const result = await complaintService.getComplaintStats(req.params.firebaseUid);
    res.json(result[0]);
  } catch (err) {
    next(err);
  }
});

// ==========================================
// BOOTH CROWDSOURCE ROUTES
// ==========================================

// POST /api/features/booths/report
// Report booth status (crowdsourced)
router.post('/booths/report', async (req, res, next) => {
  try {
    const { firebaseUid, reportData } = req.body;
    
    if (!firebaseUid || !reportData) {
      return res.status(400).json({ message: 'firebaseUid and reportData required' });
    }
    
    const result = await boothCrowdsourceService.reportBoothStatus(firebaseUid, reportData);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/booths/status
// Get booth status
router.get('/booths/status', async (req, res, next) => {
  try {
    const { boothName, constituency, state } = req.query;
    
    if (!boothName || !constituency || !state) {
      return res.status(400).json({ 
        message: 'boothName, constituency, and state required' 
      });
    }
    
    const result = await boothCrowdsourceService.getBoothStatus(
      boothName, constituency, state
    );
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/booths/constituency
// Get all booths in constituency
router.get('/booths/constituency', async (req, res, next) => {
  try {
    const { constituency, state } = req.query;
    
    if (!constituency || !state) {
      return res.status(400).json({ message: 'constituency and state required' });
    }
    
    const result = await boothCrowdsourceService.getConstituencyBooths(
      constituency, state
    );
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/booths/best-time
// Get best time to vote prediction
router.get('/booths/best-time', async (req, res, next) => {
  try {
    const { boothName, constituency, state } = req.query;
    
    if (!boothName || !constituency || !state) {
      return res.status(400).json({ 
        message: 'boothName, constituency, and state required' 
      });
    }
    
    const result = await boothCrowdsourceService.getBestTimeToVote(
      boothName, constituency, state
    );
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/booths/alternatives
// Get alternative booths with shorter queues
router.get('/booths/alternatives', async (req, res, next) => {
  try {
    const { currentBooth, constituency, state } = req.query;
    
    if (!currentBooth || !constituency || !state) {
      return res.status(400).json({ 
        message: 'currentBooth, constituency, and state required' 
      });
    }
    
    const result = await boothCrowdsourceService.getAlternativeBooths(
      currentBooth, constituency, state
    );
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// POST /api/features/booths/verify
// Verify a booth report
router.post('/booths/verify', async (req, res, next) => {
  try {
    const { reportId, firebaseUid } = req.body;
    
    if (!reportId || !firebaseUid) {
      return res.status(400).json({ message: 'reportId and firebaseUid required' });
    }
    
    const result = await boothCrowdsourceService.verifyReport(reportId, firebaseUid);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/booths/leaderboard/:constituency
// Get reporter leaderboard
router.get('/booths/leaderboard/:constituency', async (req, res, next) => {
  try {
    const { state } = req.query;
    
    if (!state) {
      return res.status(400).json({ message: 'state query parameter required' });
    }
    
    const result = await boothCrowdsourceService.getReporterLeaderboard(
      req.params.constituency, state
    );
    res.json({ leaderboard: result });
  } catch (err) {
    next(err);
  }
});

// ==========================================
// SMART REMINDERS ROUTES
// ==========================================

// POST /api/features/reminders/schedule
// Schedule a reminder
router.post('/reminders/schedule', async (req, res, next) => {
  try {
    const { firebaseUid, reminderType, title, message, scheduledAt, priority } = req.body;
    
    const { query } = require('../config/postgres');
    
    // Get user ID
    const users = await query(
      'SELECT id FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (users.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    const result = await query(
      `INSERT INTO reminders 
       (user_id, firebase_uid, reminder_type, title, message, scheduled_at, priority)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [users[0].id, firebaseUid, reminderType, title, message, scheduledAt, priority || 'medium']
    );
    
    res.json({
      success: true,
      reminder: result[0],
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/features/reminders/my-reminders/:firebaseUid
// Get user's pending reminders
router.get('/reminders/my-reminders/:firebaseUid', async (req, res, next) => {
  try {
    const { query } = require('../config/postgres');
    
    const reminders = await query(
      `SELECT * FROM reminders 
       WHERE firebase_uid = $1 AND status = 'pending'
       AND scheduled_at > NOW()
       ORDER BY scheduled_at ASC`,
      [req.params.firebaseUid]
    );
    
    res.json({ reminders });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
