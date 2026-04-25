const express = require('express');
const router = express.Router();
const Joi = require('joi');
const { nextStep, getCurrentStep } = require('../controllers/assistant.controller');
const { verifyFirebaseToken } = require('../middleware/auth.middleware');

// ── Input validation middleware ──────────────────────────────────────────────
const nextStepSchema = Joi.object({
  firebaseUid: Joi.string().min(1).max(128).required(),
  input: Joi.object({
    // Onboarding
    age: Joi.number().integer().min(0).max(120),
    state: Joi.string().max(100),
    isFirstTimeVoter: Joi.boolean(),
    // Registration
    registrationStatus: Joi.string().valid('registered', 'not_registered', 'not_sure'),
    // Check status
    found: Joi.boolean(),
    // Verification
    verificationStatus: Joi.string().valid('verified', 'issue', 'pending'),
    boothKnown: Joi.boolean(),
    // Issue resolver
    issueType: Joi.string().max(50),
    issueResolved: Joi.boolean(),
    // Voting day
    electionMode: Joi.boolean(),
    votingDone: Joi.boolean(),
    // Notifications
    notificationsEnabled: Joi.boolean(),
    // Navigation
    action: Joi.string().valid('restart', 'reset', 'back'),
  }).unknown(false),
});

const validateNextStep = (req, res, next) => {
  const { error } = nextStepSchema.validate(req.body, { abortEarly: false });
  if (error) {
    return res.status(400).json({
      message: 'Validation error',
      details: error.details.map((d) => d.message),
    });
  }
  next();
};

router.post('/next-step', validateNextStep, nextStep);
router.get('/current-step/:firebaseUid', verifyFirebaseToken, getCurrentStep);

module.exports = router;