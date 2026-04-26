const UserModel = require('../models/user.model');
const { calculateReadinessScore } = require('../services/stateMachine.service');
const { logVoterEvent } = require('../services/bigquery.service');
const { sendPushNotificationAsync } = require('../services/notification.service');

// POST /api/user/onboard
const onboardUser = async (req, res, next) => {
  try {
    const { firebaseUid, phone, age, state, isFirstTimeVoter } = req.body;

    if (!firebaseUid) {
      return res.status(400).json({ message: 'firebaseUid required' });
    }

    let user = await UserModel.findByFirebaseUid(firebaseUid);

    if (user) {
      return res.json({ message: 'User already exists', user });
    }

    // Create user
    user = await UserModel.create({
      firebaseUid,
      phone,
      age,
      state,
      isFirstTimeVoter,
    });

    // Compute next state + score
    const nextState = age >= 18 ? 'ELIGIBILITY_CHECK' : 'START';
    const score = calculateReadinessScore(user) || 0;

    // Update user (IMPORTANT: camelCase keys only)
    user = await UserModel.update(user.id, {
      currentState: nextState,
      readinessScore: score,
    });

    // Log user onboarding event asynchronously
    logVoterEvent(firebaseUid, 'user_onboarded', {
      state,
      age,
      isFirstTimeVoter,
      currentState: nextState,
      readinessScore: score,
    }).catch(() => {}); // fire-and-forget

    // Send welcome notification asynchronously
    if (age >= 18) {
      sendPushNotificationAsync(
        firebaseUid,
        '🎉 Welcome to VoteReady!',
        'Let\'s get you ready to vote in the upcoming elections.',
        { type: 'onboarding_welcome' }
      ).catch(() => {});
    }

    res.status(201).json({
      message: 'User created',
      user,
    });

  } catch (err) {
    next(err);
  }
};

// GET /api/user/:firebaseUid
const getUser = async (req, res, next) => {
  try {
    const user = await UserModel.findByFirebaseUid(req.params.firebaseUid);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ user });

  } catch (err) {
    next(err);
  }
};

// PATCH /api/user/:firebaseUid/notifications
const updateNotifications = async (req, res, next) => {
  try {
    const user = await UserModel.findByFirebaseUid(req.params.firebaseUid);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const updated = await UserModel.update(user.id, {
      notificationsEnabled: req.body.enabled,
    });

    // Log notification preference change
    logVoterEvent(req.params.firebaseUid, 'notifications_updated', {
      enabled: req.body.enabled,
      state: user.state,
      currentState: user.currentState,
    }).catch(() => {});

    res.json({ user: updated });

  } catch (err) {
    next(err);
  }
};

// PATCH /api/user/:firebaseUid/booth
const updateBooth = async (req, res, next) => {
  try {
    const { firebaseUid } = req.params;
    const { boothDetails } = req.body;

    let user = await UserModel.updateBooth(firebaseUid, boothDetails);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const score = calculateReadinessScore(user) || 0;

    user = await UserModel.update(user.id, {
      readinessScore: score,
    });

    // Log booth update event
    logVoterEvent(firebaseUid, 'booth_updated', {
      state: user.state,
      currentState: user.currentState,
      readinessScore: score,
      boothKnown: !!boothDetails,
    }).catch(() => {});

    res.json({ user });

  } catch (err) {
    next(err);
  }
};

module.exports = {
  onboardUser,
  getUser,
  updateNotifications,
  updateBooth,
};