// routes/allFeatures.routes.js
// Combined routes for all new features

const express = require('express');
const router = express.Router();

// Services
const pollingDayKitService = require('../services/pollingDayKit.service');
const electionTrackerService = require('../services/electionTracker.service');
const voterRightsService = require('../services/voterRights.service');
const electionResultsService = require('../services/electionResults.service');
const socialFeaturesService = require('../services/socialFeatures.service');
const boothCrowdsourceService = require('../services/boothCrowdsource.service');
const assistantFaqService = require('../services/assistantFaq.service');

// ==========================================
// POLLING DAY KIT ROUTES
// ==========================================

// GET /api/features/polling-kit/voter-slip/:firebaseUid
router.get('/polling-kit/voter-slip/:firebaseUid', async (req, res, next) => {
  try {
    const slip = await pollingDayKitService.getVoterSlip(req.params.firebaseUid);
    res.json({ slip });
  } catch (err) {
    next(err);
  }
});

// POST /api/features/polling-kit/voter-slip
router.post('/polling-kit/voter-slip', async (req, res, next) => {
  try {
    const { firebaseUid, slipData } = req.body;
    const result = await pollingDayKitService.saveVoterSlip(firebaseUid, slipData);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/polling-kit/validate-documents/:firebaseUid
router.get('/polling-kit/validate-documents/:firebaseUid', async (req, res, next) => {
  try {
    const result = await pollingDayKitService.validateDocuments(req.params.firebaseUid);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/polling-kit/checklist/:firebaseUid
router.get('/polling-kit/checklist/:firebaseUid', async (req, res, next) => {
  try {
    const checklist = await pollingDayKitService.getChecklist(req.params.firebaseUid);
    res.json({ checklist });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/features/polling-kit/checklist/:firebaseUid
router.patch('/polling-kit/checklist/:firebaseUid', async (req, res, next) => {
  try {
    const updates = req.body;
    const checklist = await pollingDayKitService.updateChecklist(req.params.firebaseUid, updates);
    res.json({ checklist });
  } catch (err) {
    next(err);
  }
});

// POST /api/features/polling-kit/panic-button
router.post('/polling-kit/panic-button', async (req, res, next) => {
  try {
    const { firebaseUid, reason, location } = req.body;
    const result = await pollingDayKitService.triggerPanicButton(firebaseUid, reason, location);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// POST /api/features/polling-kit/resolve-panic/:firebaseUid
router.post('/polling-kit/resolve-panic/:firebaseUid', async (req, res, next) => {
  try {
    const { resolutionNotes } = req.body;
    const result = await pollingDayKitService.resolvePanic(req.params.firebaseUid, resolutionNotes);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// ==========================================
// ELECTION TRACKER ROUTES
// ==========================================

// GET /api/features/election-tracker/phases/:firebaseUid
router.get('/election-tracker/phases/:firebaseUid', async (req, res, next) => {
  try {
    const phases = await electionTrackerService.getElectionPhasesForUser(req.params.firebaseUid);
    res.json(phases);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/election-tracker/phases-by-state/:state
router.get('/election-tracker/phases-by-state/:state', async (req, res, next) => {
  try {
    const phases = await electionTrackerService.getElectionPhasesByState(req.params.state);
    res.json(phases);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/election-tracker/upcoming
router.get('/election-tracker/upcoming', async (req, res, next) => {
  try {
    const elections = await electionTrackerService.getUpcomingElections();
    res.json(elections);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/election-tracker/calendar/:firebaseUid
router.get('/election-tracker/calendar/:firebaseUid', async (req, res, next) => {
  try {
    const calendar = await electionTrackerService.getUserCalendar(req.params.firebaseUid);
    res.json(calendar);
  } catch (err) {
    next(err);
  }
});

// POST /api/features/election-tracker/reminder-preferences/:firebaseUid
router.post('/election-tracker/reminder-preferences/:firebaseUid', async (req, res, next) => {
  try {
    const result = await electionTrackerService.setReminderPreferences(req.params.firebaseUid, req.body);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/election-tracker/sample-ballot/:firebaseUid
router.get('/election-tracker/sample-ballot/:firebaseUid', async (req, res, next) => {
  try {
    const ballot = await electionTrackerService.getSampleBallot(req.params.firebaseUid);
    res.json(ballot);
  } catch (err) {
    next(err);
  }
});

// POST /api/features/election-tracker/mark-ballot-viewed/:firebaseUid
router.post('/election-tracker/mark-ballot-viewed/:firebaseUid', async (req, res, next) => {
  try {
    const { phaseId } = req.body;
    const result = await electionTrackerService.markSampleBallotViewed(req.params.firebaseUid, phaseId);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/election-tracker/live-turnout/:firebaseUid
router.get('/election-tracker/live-turnout/:firebaseUid', async (req, res, next) => {
  try {
    const turnout = await electionTrackerService.getLiveTurnoutForUser(req.params.firebaseUid);
    res.json(turnout);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/election-tracker/state-turnout/:state
router.get('/election-tracker/state-turnout/:state', async (req, res, next) => {
  try {
    const turnout = await electionTrackerService.getStateTurnout(req.params.state);
    res.json(turnout);
  } catch (err) {
    next(err);
  }
});

// ==========================================
// VOTER RIGHTS ROUTES
// ==========================================

// GET /api/features/voter-rights/guides
router.get('/voter-rights/guides', async (req, res, next) => {
  try {
    const { category, language } = req.query;
    const guides = await voterRightsService.getAllGuides(category, language);
    res.json(guides);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/voter-rights/guides/:topic
router.get('/voter-rights/guides/:topic', async (req, res, next) => {
  try {
    const { language } = req.query;
    const guide = await voterRightsService.getGuideByTopic(req.params.topic, language);
    res.json({ guide });
  } catch (err) {
    next(err);
  }
});

// GET /api/features/voter-rights/search
router.get('/voter-rights/search', async (req, res, next) => {
  try {
    const { q, language } = req.query;
    const guides = await voterRightsService.searchGuides(q, language);
    res.json(guides);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/voter-rights/helplines/:firebaseUid
router.get('/voter-rights/helplines/:firebaseUid', async (req, res, next) => {
  try {
    const helplines = await voterRightsService.getHelplinesForUser(req.params.firebaseUid);
    res.json(helplines);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/voter-rights/helplines-by-state/:state
router.get('/voter-rights/helplines-by-state/:state', async (req, res, next) => {
  try {
    const helplines = await voterRightsService.getHelplines(req.params.state);
    res.json(helplines);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/voter-rights/emergency-contacts
router.get('/voter-rights/emergency-contacts', async (req, res, next) => {
  try {
    const { state } = req.query;
    const contacts = await voterRightsService.getEmergencyContacts(state);
    res.json(contacts);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/voter-rights/accessibility
router.get('/voter-rights/accessibility', async (req, res, next) => {
  try {
    const info = await voterRightsService.getAccessibilityInfo();
    res.json(info);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/voter-rights/rights
router.get('/voter-rights/rights', async (req, res, next) => {
  try {
    const rights = await voterRightsService.getVoterRights();
    res.json(rights);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/voter-rights/emergency-scenarios
router.get('/voter-rights/emergency-scenarios', async (req, res, next) => {
  try {
    const scenarios = await voterRightsService.getEmergencyScenarios();
    res.json(scenarios);
  } catch (err) {
    next(err);
  }
});

// ==========================================
// ELECTION RESULTS ROUTES
// ==========================================

// GET /api/features/results/my-constituency/:firebaseUid
router.get('/results/my-constituency/:firebaseUid', async (req, res, next) => {
  try {
    const results = await electionResultsService.getResultsForUser(req.params.firebaseUid);
    res.json(results);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/results/constituency
router.get('/results/constituency', async (req, res, next) => {
  try {
    const { state, constituency } = req.query;
    const results = await electionResultsService.getConstituencyResults(state, constituency);
    res.json(results);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/results/state/:state
router.get('/results/state/:state', async (req, res, next) => {
  try {
    const results = await electionResultsService.getStateResults(req.params.state);
    res.json(results);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/results/historical
router.get('/results/historical', async (req, res, next) => {
  try {
    const { state, constituency } = req.query;
    const results = await electionResultsService.getHistoricalResults(state, constituency);
    res.json(results);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/results/compare
router.get('/results/compare', async (req, res, next) => {
  try {
    const { state, constituency } = req.query;
    const comparison = await electionResultsService.compareWithPrevious(state, constituency);
    res.json(comparison);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/results/party-performance/:state
router.get('/results/party-performance/:state', async (req, res, next) => {
  try {
    const { year } = req.query;
    const performance = await electionResultsService.getPartyPerformance(req.params.state, year);
    res.json(performance);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/results/closest-contests/:state
router.get('/results/closest-contests/:state', async (req, res, next) => {
  try {
    const { limit } = req.query;
    const contests = await electionResultsService.getClosestContests(req.params.state, parseInt(limit) || 10);
    res.json(contests);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/results/biggest-victories/:state
router.get('/results/biggest-victories/:state', async (req, res, next) => {
  try {
    const { limit } = req.query;
    const victories = await electionResultsService.getBiggestVictories(req.params.state, parseInt(limit) || 10);
    res.json(victories);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/results/vote-share
router.get('/results/vote-share', async (req, res, next) => {
  try {
    const { state, constituency } = req.query;
    const voteShare = await electionResultsService.getVoteShare(state, constituency);
    res.json(voteShare);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/results/turnout-analysis/:state
router.get('/results/turnout-analysis/:state', async (req, res, next) => {
  try {
    const analysis = await electionResultsService.getTurnoutAnalysis(req.params.state);
    res.json(analysis);
  } catch (err) {
    next(err);
  }
});

// ==========================================
// SOCIAL FEATURES ROUTES
// ==========================================

// CARPOOL ROUTES
// POST /api/features/social/carpool
router.post('/social/carpool', async (req, res, next) => {
  try {
    const { firebaseUid, ...carpoolData } = req.body;
    const result = await socialFeaturesService.createCarpool(firebaseUid, carpoolData);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/social/carpools
router.get('/social/carpools', async (req, res, next) => {
  try {
    const { boothName, constituency, state } = req.query;
    const carpools = await socialFeaturesService.findCarpools(boothName, constituency, state);
    res.json(carpools);
  } catch (err) {
    next(err);
  }
});

// POST /api/features/social/carpool/join
router.post('/social/carpool/join', async (req, res, next) => {
  try {
    const { carpoolId, firebaseUid } = req.body;
    const result = await socialFeaturesService.joinCarpool(carpoolId, firebaseUid);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/social/carpools/my/:firebaseUid
router.get('/social/carpools/my/:firebaseUid', async (req, res, next) => {
  try {
    const carpools = await socialFeaturesService.getMyCarpools(req.params.firebaseUid);
    res.json(carpools);
  } catch (err) {
    next(err);
  }
});

// I VOTED ROUTES
// POST /api/features/social/i-voted
router.post('/social/i-voted', async (req, res, next) => {
  try {
    const { firebaseUid, ...voteData } = req.body;
    const result = await socialFeaturesService.recordIVoted(firebaseUid, voteData);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/social/i-voted/:firebaseUid
router.get('/social/i-voted/:firebaseUid', async (req, res, next) => {
  try {
    const record = await socialFeaturesService.getIVotedRecord(req.params.firebaseUid);
    res.json({ record });
  } catch (err) {
    next(err);
  }
});

// GET /api/features/social/i-voted-feed
router.get('/social/i-voted-feed', async (req, res, next) => {
  try {
    const { constituency, state, limit } = req.query;
    const feed = await socialFeaturesService.getIVotedFeed(constituency, state, parseInt(limit) || 50);
    res.json(feed);
  } catch (err) {
    next(err);
  }
});

// POST /api/features/social/share-i-voted/:firebaseUid
router.post('/social/share-i-voted/:firebaseUid', async (req, res, next) => {
  try {
    const { platform } = req.body;
    const result = await socialFeaturesService.shareIVoted(req.params.firebaseUid, platform);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// BOOTH SHARING
// POST /api/features/social/share-booth
router.post('/social/share-booth', async (req, res, next) => {
  try {
    const { firebaseUid, ...shareData } = req.body;
    const result = await socialFeaturesService.shareBoothInfo(firebaseUid, shareData);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// COMMUNITY STATS
// GET /api/features/social/community-stats
router.get('/social/community-stats', async (req, res, next) => {
  try {
    const { constituency, state } = req.query;
    const stats = await socialFeaturesService.getCommunityStats(constituency, state);
    res.json(stats);
  } catch (err) {
    next(err);
  }
});

// ==========================================
// BOOTH CROWDSOURCE ROUTES
// ==========================================

// POST /api/features/booth-crowdsource/report
router.post('/booth-crowdsource/report', async (req, res, next) => {
  try {
    const { firebaseUid, reportData } = req.body;
    const result = await boothCrowdsourceService.reportBoothStatus(firebaseUid, reportData);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/booth-crowdsource/status
router.get('/booth-crowdsource/status', async (req, res, next) => {
  try {
    const { boothName, constituency, state } = req.query;
    const status = await boothCrowdsourceService.getBoothStatus(boothName, constituency, state);
    res.json(status);
  } catch (err) {
    next(err);
  }
});

// ==========================================
// AI ASSISTANT FAQ ROUTES
// ==========================================

// POST /api/features/assistant/faq
router.post('/assistant/faq', async (req, res, next) => {
  try {
    const { question, userContext } = req.body;
    const answer = await assistantFaqService.answerQuestion(question, userContext);
    res.json(answer);
  } catch (err) {
    next(err);
  }
});

// GET /api/features/assistant/quick-questions
router.get('/assistant/quick-questions', async (req, res, next) => {
  try {
    const questions = assistantFaqService.getQuickQuestions();
    res.json({ questions });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
