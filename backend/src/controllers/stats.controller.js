/**
 * Stats controller
 *
 * Returns aggregated application statistics.
 * Results are cached for 5 minutes to avoid hammering the DB
 * on every request.
 */

const { getAppStats }  = require('../services/stats.service');
const cache            = require('../services/cache.service');
const { queryTurnoutStats } = require('../services/bigquery.service');

const STATS_CACHE_KEY    = 'stats:app';
const TURNOUT_CACHE_KEY  = 'stats:turnout';
const STATS_TTL_SECONDS  = 5 * 60;   // 5 minutes
const TURNOUT_TTL_SECONDS = 10 * 60; // 10 minutes

/**
 * GET /api/stats
 * Returns overall app statistics (user counts, turnout, readiness).
 */
const getStats = async (req, res, next) => {
  try {
    const stats = await cache.getOrSet(
      STATS_CACHE_KEY,
      () => getAppStats(),
      STATS_TTL_SECONDS,
    );
    res.json({ stats, cached: cache.get(STATS_CACHE_KEY) !== undefined });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/stats/turnout
 * Returns BigQuery-backed turnout analytics grouped by state.
 */
const getTurnoutStats = async (req, res, next) => {
  try {
    const data = await cache.getOrSet(
      TURNOUT_CACHE_KEY,
      () => queryTurnoutStats(),
      TURNOUT_TTL_SECONDS,
    );
    res.json(data);
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/stats/cache
 * Returns cache health metrics (admin / monitoring use).
 */
const getCacheStats = (req, res) => {
  res.json({ cache: cache.healthStats() });
};

module.exports = { getStats, getTurnoutStats, getCacheStats };
