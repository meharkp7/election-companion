const cron = require('node-cron');
const { notifyIncompleteUsers } = require('../services/notification.service');

// Every day at 10am
cron.schedule('0 10 * * *', async () => {
  console.log('⏰ Running reminder job...');
  await notifyIncompleteUsers();
});