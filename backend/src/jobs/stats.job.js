const cron = require('node-cron');
const { getAppStats } = require('../services/stats.service');
const { logVoterEvent } = require('../services/bigquery.service');
const { log } = require('../services/cloudLogging.service');

// Every hour — snapshot stats to BigQuery for trend analysis
cron.schedule('0 * * * *', async () => {
  try {
    const stats = await getAppStats();
    log.info('stats_snapshot', { stats }).catch(() => {});

    // Push aggregate stats as a synthetic event so BigQuery can track trends
    await logVoterEvent('system', 'hourly_stats_snapshot', {
      metadata: {
        totalUsers: stats.totalUsers,
        votedUsers: stats.votedUsers,
        turnoutPercent: stats.turnoutPercent,
        avgReadiness: stats.readiness?.avg,
      },
    });
  } catch (err) {
    log.error('stats_job_failed', { error: err.message }).catch(() => {});
  }
});