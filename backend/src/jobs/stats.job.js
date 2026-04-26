/**
 * Hourly stats snapshot job
 *
 * Runs every hour to:
 *  1. Fetch current app stats from PostgreSQL
 *  2. Log a synthetic voter_event to BigQuery for trend analysis
 *  3. Log an election_metric row for per-state turnout tracking
 *  4. Invalidate the stats cache so the next API call gets fresh data
 */

const cron = require('node-cron');
const { getAppStats }        = require('../services/stats.service');
const { logVoterEvent, logElectionMetric } = require('../services/bigquery.service');
const { log }                = require('../services/cloudLogging.service');
const cache                  = require('../services/cache.service');

// Every hour on the hour
cron.schedule('0 * * * *', async () => {
  try {
    const stats = await getAppStats();

    // Operational log
    log.info('stats_snapshot', { stats }).catch(() => {});

    // Voter events table — synthetic aggregate event
    await logVoterEvent('system', 'hourly_stats_snapshot', {
      metadata: {
        totalUsers:     stats.totalUsers,
        votedUsers:     stats.votedUsers,
        turnoutPercent: stats.turnoutPercent,
        avgReadiness:   stats.readiness?.avg,
      },
    });

    // Election metrics table — structured turnout row
    await logElectionMetric('ALL', 'hourly_snapshot', {
      totalUsers:     stats.totalUsers,
      votedUsers:     stats.votedUsers,
      turnoutPercent: stats.turnoutPercent,
      avgReadiness:   stats.readiness?.avg,
    });

    // Bust the stats cache so the next API request reflects fresh data
    cache.invalidatePrefix('stats:');

    console.log('✅ Stats job completed');
  } catch (err) {
    log.error('stats_job_failed', { error: err.message }).catch(() => {});
    console.error('❌ Stats job failed:', err.message);
  }
});
