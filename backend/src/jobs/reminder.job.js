/**
 * Daily reminder job
 *
 * Runs every day at 10 AM to remind users who haven't completed
 * their voter journey.
 *
 * When Cloud Tasks is configured, notifications are dispatched
 * asynchronously via the notifications-queue (better reliability,
 * retries, and rate control).  Falls back to direct FCM calls
 * when running locally.
 */

const cron = require('node-cron');
const { query }                = require('../config/postgres');
const { notifyIncompleteUsers, sendPushNotificationAsync } = require('../services/notification.service');
const { scheduleReminder, isConfigured: isTasksConfigured } = require('../services/cloudTasks.service');
const { logVoterEvent }        = require('../services/bigquery.service');
const { log }                  = require('../services/cloudLogging.service');

// ── Election-day advance reminders ─────────────────────────────────────────

/**
 * Schedule Cloud Tasks reminders for users whose election is
 * 1 day or 7 days away.
 */
async function scheduleElectionReminders() {
  try {
    // Users in READY_TO_VOTE with an upcoming election
    const rows = await query(
      `SELECT u.firebase_uid, u.state, e.election_date
       FROM users u
       JOIN elections e ON e.state = u.state AND e.is_active = TRUE
       WHERE u.current_state = 'READY_TO_VOTE'
         AND u.notifications_enabled = TRUE
         AND e.election_date BETWEEN CURRENT_DATE + INTERVAL '1 day'
                                 AND CURRENT_DATE + INTERVAL '7 days'`,
    );

    let scheduled = 0;
    for (const row of rows) {
      const electionDate = new Date(row.election_date);
      const daysUntil = Math.round(
        (electionDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24),
      );

      const title = daysUntil === 1
        ? '🗳️ Election is TOMORROW!'
        : `🗳️ Election in ${daysUntil} days`;
      const body = 'Make sure you\'re ready — check your booth and documents.';

      if (isTasksConfigured()) {
        // Fire at 9 AM on the reminder day
        const reminderDate = new Date(electionDate);
        reminderDate.setDate(reminderDate.getDate() - (daysUntil === 1 ? 0 : 6));
        reminderDate.setHours(9, 0, 0, 0);

        await scheduleReminder(row.firebase_uid, title, body, reminderDate);
      } else {
        // Fallback: send immediately (local dev)
        await sendPushNotificationAsync(row.firebase_uid, title, body);
      }

      scheduled++;
    }

    if (scheduled > 0) {
      log.info('election_reminders_scheduled', { count: scheduled }).catch(() => {});
      await logVoterEvent('system', 'election_reminders_scheduled', {
        metadata: { count: scheduled },
      });
    }
  } catch (err) {
    log.error('election_reminders_failed', { error: err.message }).catch(() => {});
    console.error('❌ Election reminder scheduling failed:', err.message);
  }
}

// ── Daily incomplete-user reminders ────────────────────────────────────────

// Every day at 10 AM
cron.schedule('0 10 * * *', async () => {
  console.log('⏰ Running reminder job...');

  // 1. Notify users who haven't completed their journey
  await notifyIncompleteUsers();

  // 2. Schedule advance election-day reminders via Cloud Tasks
  await scheduleElectionReminders();
});
