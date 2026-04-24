const UserModel = require('../models/user.model');
const { calculateReadinessScore } = require('../services/stateMachine.service');

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