const UserModel = require('../models/user.model');
const { transition } = require('../services/stateMachine.service');
const { isElectionDay } = require('../services/election.service');

// POST /api/assistant/next-step
const nextStep = async (req, res, next) => {
  try {
    const { firebaseUid, input = {} } = req.body;

    if (!firebaseUid) {
      return res.status(400).json({ message: 'firebaseUid required' });
    }

    let user = await UserModel.findByFirebaseUid(firebaseUid);

    // Auto-create user (IMPORTANT)
    if (!user) {
      user = await UserModel.create({
        firebaseUid: firebaseUid,
      });
    }

    // Auto-trigger election mode
    if (
      user.currentState === 'READY_TO_VOTE' &&
      (await isElectionDay(user.state))
    ) {
      input.electionMode = true;
    }

    const result = await transition(user.id, input);

    const uiPayload = buildUIPayload({
      currentState: result.currentState,
      action: result.action,
      user: result.user,
    });

    res.json({
      currentState: result.currentState,
      message: result.message,
      ui: uiPayload,
    });
  } catch (err) {
    console.error('❌ NEXT STEP ERROR:', err);
    next(err);
  }
};

// GET /api/assistant/current-step/:firebaseUid
const getCurrentStep = async (req, res, next) => {
  try {
    let user = await UserModel.findByFirebaseUid(
      req.params.firebaseUid
    );

    if (!user) {
      user = await UserModel.create({
        firebaseUid: req.params.firebaseUid,
      });
    }

    const uiPayload = buildUIPayload({
      currentState: user.currentState,
      user,
    });

    res.json({
      currentState: user.currentState,
      readinessScore: user.readinessScore,
      ui: uiPayload,
    });
  } catch (err) {
    next(err);
  }
};

// UI payload builder
const buildUIPayload = ({ currentState, action, user }) => {
  const payloads = {
    START: {
      screen: 'onboarding',
      title: 'Let\'s get you vote-ready! 🗳️',
      prompt: 'How old are you, and which state are you in?',
      inputs: ['age', 'state', 'isFirstTimeVoter'],
    },
    ELIGIBILITY_CHECK: {
      screen: 'eligibility',
      title: 'Checking your eligibility ✅',
      prompt: 'You\'re eligible to vote! Let\'s check your registration.',
    },
    REGISTRATION: {
      screen: 'registration',
      title: 'Voter Registration',
      prompt: 'Are you registered to vote?',
      options: ['registered', 'not_registered', 'not_sure'],
      action: action || null,
    },
    CHECK_STATUS: {
      screen: 'check_status',
      title: 'Check Your Voter Status 🔍',
      prompt: 'Let\'s check if your name is on the electoral roll.',
      link: 'https://electoralsearch.eci.gov.in',
    },
    VERIFICATION: {
      screen: 'verification',
      title: 'Verify Your Details',
      prompt: 'Is your name correctly listed?',
      inputs: ['verificationStatus', 'boothKnown'],
    },
    ISSUE_RESOLVER: {
      screen: 'issue_resolver',
      title: '🚨 Let\'s Fix This',
      prompt: 'What issue are you facing?',
      options: ['missing_name', 'wrong_details', 'booth_issue', 'transfer'],
      action: action || null,
    },
    READY_TO_VOTE: {
      screen: 'ready',
      title: '🎉 You\'re Vote-Ready!',
      prompt: 'We\'ll remind you on election day.',
      readinessScore: user?.readinessScore,
    },
    VOTING_DAY: {
      screen: 'voting_day',
      title: '🗳️ Today is Election Day!',
      steps: [
        'Go to your polling booth',
        'Carry valid ID',
        'Vote on EVM',
        'Verify on VVPAT',
      ],
      boothDetails: user?.boothDetails,
    },
    COMPLETED: {
      screen: 'completed',
      title: '🏆 You Voted!',
      prompt: 'Thank you for participating!',
    },
  };

  return payloads[currentState] || payloads['START'];
};

module.exports = { nextStep, getCurrentStep };