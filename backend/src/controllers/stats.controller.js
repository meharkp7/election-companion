const { getAppStats } = require('../services/stats.service');

const getStats = async (req, res, next) => {
  try {
    const stats = await getAppStats();
    res.json({ stats });
  } catch (err) {
    next(err);
  }
};

module.exports = { getStats };