// services/stateMachine.service.js
// Full rewrite: PostgreSQL instead of Mongoose
const cloudTasks = require('./cloudTasks.service');
const UserModel = require('../models/user.model');
const StateLogModel = require('../models/state.model');

// ─── Readiness score calculator ────────────────────────────────────────────
const calculateReadinessScore = (user) => {
  let score = 0;
  if (user.age >= 18) score += 25;
  if (user.registrationStatus === 'registered') score += 25;
  if (user.verificationStatus === 'verified') score += 25;
  if (user.boothKnown) score += 15;
  if (user.currentState === 'READY_TO_VOTE' || user.currentState === 'VOTING_DAY') score += 10;
  return Math.min(score, 100);
};

// ─── Age group helper for analytics ─────────────────────────────────────────
const _ageGroup = (age) => {
  if (age < 25) return '18-24';
  if (age < 35) return '25-34';
  if (age < 45) return '35-44';
  if (age < 60) return '45-59';
  return '60+';
};

// ─── Core transition logic ──────────────────────────────────────────────────
const getNextState = (currentState, input) => {
  // Global actions - work from any state
  if (input.action === 'restart') {
    return { state: 'START' };
  }
  if (input.action === 'reset') {
    return { state: 'START' };
  }
  if (input.action === 'back') {
    // Go back one step based on current state
    const backMap = {
      'ELIGIBILITY_CHECK': 'START',
      'REGISTRATION': 'ELIGIBILITY_CHECK',
      'CHECK_STATUS': 'REGISTRATION',
      'VERIFICATION': 'REGISTRATION',
      'ISSUE_RESOLVER': 'VERIFICATION',
      'READY_TO_VOTE': 'VERIFICATION',
      'VOTING_DAY': 'READY_TO_VOTE',
      'COMPLETED': 'VOTING_DAY',
      'POST_VOTING_EXPLORE': 'COMPLETED',
    };
    return { state: backMap[currentState] || 'START' };
  }

  switch (currentState) {

    case 'START':
      if (!input.age || !input.state) return { state: 'START', error: 'Age and state are required' };
      if (input.age < 18) return { state: 'EXIT', reason: 'not_eligible_age' };
      return { state: 'ELIGIBILITY_CHECK' };

    case 'ELIGIBILITY_CHECK':
      return { state: 'REGISTRATION' };

    case 'REGISTRATION':
      if (input.registrationStatus === 'registered')    return { state: 'VERIFICATION' };
      if (input.registrationStatus === 'not_registered') return { state: 'REGISTRATION', action: 'show_form6_guide' };
      if (input.registrationStatus === 'not_sure')       return { state: 'CHECK_STATUS' };
      return { state: 'REGISTRATION' };

    case 'CHECK_STATUS':
      if (input.found === true)  return { state: 'VERIFICATION' };
      if (input.found === false) return { state: 'REGISTRATION', action: 'show_form6_guide' };
      return { state: 'CHECK_STATUS' };

    case 'VERIFICATION':
      if (input.verificationStatus === 'verified' && input.boothKnown) return { state: 'READY_TO_VOTE' };
      if (input.verificationStatus === 'issue')                         return { state: 'ISSUE_RESOLVER' };
      if (input.verificationStatus === 'verified' && !input.boothKnown) return { state: 'VERIFICATION', action: 'find_booth' };
      return { state: 'VERIFICATION' };

    case 'ISSUE_RESOLVER':
      if (input.issueResolved) return { state: 'VERIFICATION' };
      return { state: 'ISSUE_RESOLVER', action: resolveIssueAction(input.issueType) };

    case 'READY_TO_VOTE':
      if (input.electionMode) return { state: 'VOTING_DAY' };
      return { state: 'READY_TO_VOTE' };

    case 'VOTING_DAY':
      if (input.votingDone) return { state: 'COMPLETED' };
      return { state: 'VOTING_DAY' };

    case 'COMPLETED':
      return { state: 'POST_VOTING_EXPLORE' };

    case 'POST_VOTING_EXPLORE':
      return { state: 'POST_VOTING_EXPLORE' };

    default:
      return { state: 'START' };
  }
};

// ─── Issue → form mapper ────────────────────────────────────────────────────
const resolveIssueAction = (issueType) => {
  const map = {
    missing_name:  { form: 'Form 6',  description: 'Apply for new voter registration', url: 'https://voters.eci.gov.in' },
    wrong_details: { form: 'Form 8',  description: 'Correction of entries in electoral roll', url: 'https://voters.eci.gov.in' },
    booth_issue:   { form: null,      description: 'Contact your BLO (Booth Level Officer)', url: 'https://electoralsearch.eci.gov.in' },
    transfer:      { form: 'Form 8A', description: 'Transposition within Assembly constituency', url: 'https://voters.eci.gov.in' },
  };
  return map[issueType] || { form: 'Form 6', description: 'General voter registration', url: 'https://voters.eci.gov.in' };
};

// ─── Main transition function (persists to PostgreSQL) ──────────────────────
const transition = async (userId, input) => {
  const user = await UserModel.findById(userId);
  if (!user) throw new Error('User not found');

  try {
    const result = getNextState(user.currentState, input);
    const fromState = user.currentState;

    if (result.state === 'EXIT') {
      return { success: false, reason: result.reason, currentState: fromState };
    }

    // Build update payload
    const updateFields = { currentState: result.state };

    if (input.age !== undefined)                updateFields.age = input.age;
    if (input.state !== undefined)              updateFields.state = input.state;
    if (input.isFirstTimeVoter !== undefined)   updateFields.isFirstTimeVoter = input.isFirstTimeVoter;
    if (input.registrationStatus !== undefined) updateFields.registrationStatus = input.registrationStatus;
    if (input.verificationStatus !== undefined) updateFields.verificationStatus = input.verificationStatus;
    if (input.boothKnown !== undefined)         updateFields.boothKnown = input.boothKnown;
    if (input.issueType !== undefined)          updateFields.issueType = input.issueType;

    if (input.boothDetails) {
      updateFields.boothName    = input.boothDetails.boothName;
      updateFields.boothAddress = input.boothDetails.address;
      updateFields.boothLat     = input.boothDetails.lat;
      updateFields.boothLng     = input.boothDetails.lng;
      updateFields.boothKnown   = true;
    }

    const merged = { ...user, ...updateFields };
    updateFields.readinessScore = calculateReadinessScore(merged);

    const updatedUser = await UserModel.update(userId, updateFields);

    await StateLogModel.create({
      userId,
      fromState,
      toState: result.state,
      trigger: input.trigger || 'user_action',
      meta: input,
    });

    // 🔥 TRIGGER CLOUD TASKS FOR ASYNC PROCESSING
    try {
      // Queue analytics event for BigQuery
      await cloudTasks.enqueueAnalyticsBatch([{
        event_id: `${user.firebaseUid}_state_${result.state.toLowerCase()}_${Date.now()}`,
        firebase_uid: user.firebaseUid,
        event_type: `state_${result.state.toLowerCase()}`,
        state: updatedUser.state,
        age_group: updatedUser.age ? _ageGroup(updatedUser.age) : null,
        is_first_time_voter: updatedUser.isFirstTimeVoter,
        current_state: result.state,
        readiness_score: updatedUser.readinessScore,
        metadata: JSON.stringify({
          fromState,
          trigger: input.trigger || 'user_action',
          inputData: input
        }),
        timestamp: new Date().toISOString(),
      }]);

      // Queue notification for important state changes
      if (['READY_TO_VOTE', 'VOTING_DAY', 'COMPLETED'].includes(result.state)) {
        const notificationMessages = {
          'READY_TO_VOTE': {
            title: '🎉 You\'re Vote-Ready!',
            body: 'All set for election day. We\'ll remind you when it\'s time to vote!'
          },
          'VOTING_DAY': {
            title: '🗳️ Today is Election Day!',
            body: 'Time to vote! Head to your polling booth now.'
          },
          'COMPLETED': {
            title: '🏆 Thank You for Voting!',
            body: 'Your vote matters! Thanks for participating in democracy.'
          }
        };

        const notification = notificationMessages[result.state];
        if (notification) {
          await cloudTasks.enqueueNotification(
            user.firebaseUid,
            notification.title,
            notification.body,
            { 
              type: 'state_change',
              state: result.state,
              readinessScore: updatedUser.readinessScore
            }
          );
        }
      }

      console.log(`🔥 Cloud Tasks triggered for state: ${fromState} → ${result.state}`);
    } catch (taskError) {
      // Don't fail the transition if Cloud Tasks fails
      console.error('❌ Cloud Task failed (non-critical):', taskError.message);
    }

    return {
      success: true,
      previousState: fromState,
      currentState: result.state,
      action: result.action || null,
      readinessScore: updatedUser?.readinessScore || 0,
      user: updatedUser,
    };
  } catch (err) {
    console.error('❌ Transition Error:', err);
    throw err;
  }
};

module.exports = { transition, getNextState, calculateReadinessScore, resolveIssueAction };