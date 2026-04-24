const cron = require('node-cron');
const { getAppStats } = require('../services/stats.service');

// Every hour — log stats (extend to cache in Redis later)
cron.schedule('0 * * * *', async () => {
  const stats = await getAppStats();
  console.log('📊 Stats snapshot:', stats);
});