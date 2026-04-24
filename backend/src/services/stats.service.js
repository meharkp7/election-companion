// services/stats.service.js — PostgreSQL version
const UserModel = require('../models/user.model');

const getAppStats = async () => {
  const [stateRows, readinessRow] = await Promise.all([
    UserModel.countByState(),
    UserModel.readinessStats(),
  ]);

  const total = parseInt(readinessRow?.total ?? 0);
  const voted = stateRows.find(r => r.state === 'COMPLETED')?.count ?? 0;
  const exploring = stateRows.find(r => r.state === 'POST_VOTING_EXPLORE')?.count ?? 0;
  const totalVoted = parseInt(voted) + parseInt(exploring);

  return {
    totalUsers: total,
    votedUsers: totalVoted,
    turnoutPercent: total ? ((totalVoted / total) * 100).toFixed(1) : '0.0',
    stateDistribution: stateRows,
    readiness: {
      avg: parseFloat(readinessRow?.avg ?? 0),
      max: parseInt(readinessRow?.max ?? 0),
    },
  };
};

module.exports = { getAppStats };