/**
 * Internal Cloud Tasks callback routes
 *
 * These endpoints are called by Google Cloud Tasks workers.
 * They must NOT be exposed publicly — protect them with a
 * shared secret header or VPC-internal routing in production.
 *
 * Routes:
 *  POST /internal/tasks/send-notification
 *  POST /internal/tasks/flush-analytics
 *  POST /internal/tasks/process-document
 */

const express = require('express');
const router = express.Router();

const { sendPushNotification } = require('../services/notification.service');
const { logVoterEventSync } = require('../services/bigquery.service');
const { processDocumentSync } = require('../services/verification.service');
const { log }                  = require('../services/cloudLogging.service');

// ── Simple shared-secret guard ──────────────────────────────────────────────
const verifyTaskSecret = (req, res, next) => {
  // In production, Cloud Tasks adds a custom header you set on the queue.
  // Skip the check in non-production so local dev still works.
  if (process.env.NODE_ENV !== 'production') return next();

  const secret = req.headers['x-cloudtasks-secret'];
  if (!secret || secret !== process.env.CLOUD_TASKS_SECRET) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  next();
};

router.use(verifyTaskSecret);

// ── POST /internal/tasks/send-notification ──────────────────────────────────
/**
 * Deliver a single FCM push notification.
 * Body: { firebaseUid, title, body, data? }
 */
router.post('/send-notification', async (req, res, next) => {
  try {
    const { firebaseUid, title, body, data = {} } = req.body;

    if (!firebaseUid || !title || !body) {
      return res.status(400).json({ error: 'firebaseUid, title, and body are required' });
    }

    await sendPushNotification(firebaseUid, title, body, data);

    log.info('task_notification_sent', { firebaseUid }).catch(() => {});
    res.json({ success: true });
  } catch (err) {
    log.error('task_notification_failed', { error: err.message }).catch(() => {});
    next(err);
  }
});

// ── POST /internal/tasks/flush-analytics ────────────────────────────────────
/**
 * Flush a batch of analytics events to BigQuery.
 * Body: { events: Array<{ event_id, firebase_uid, event_type, ... }> }
 */
router.post('/flush-analytics', async (req, res, next) => {
  try {
    const { events = [] } = req.body;

    if (!bigquery) {
      console.log('[BigQuery mock] Batch analytics flush:', events.length, 'events');
      return res.json({ success: true, processed: events.length, failed: 0 });
    }

    // Insert events directly to BigQuery
    const results = await Promise.allSettled(
      events.map(async (event) => {
        const table = bigquery.dataset(process.env.BIGQUERY_DATASET_ID || 'vote_ready_analytics').table('voter_events');
        await table.insert([event]);
      })
    );

    const failed = results.filter(r => r.status === 'rejected').length;
    if (failed > 0) {
      log.warn('task_analytics_partial_failure', { total: events.length, failed }).catch(() => {});
    }

    res.json({ success: true, processed: events.length, failed });
  } catch (err) {
    log.error('task_analytics_flush_failed', { error: err.message }).catch(() => {});
    next(err);
  }
});

// ── POST /internal/tasks/process-document ───────────────────────────────────
/**
 * Trigger async Document AI processing.
 * Body: { firebaseUid, fileUrl, documentType }
 */
router.post('/process-document', async (req, res, next) => {
  try {
    const { firebaseUid, fileUrl, documentType } = req.body;

    if (!firebaseUid || !fileUrl || !documentType) {
      return res.status(400).json({ error: 'firebaseUid, fileUrl, and documentType are required' });
    }

    // Process document synchronously in the background task
    await processDocumentSync(firebaseUid, fileUrl, documentType);

    log.info('task_document_processed', { firebaseUid, documentType }).catch(() => {});
    res.json({ success: true });
  } catch (err) {
    log.error('task_document_failed', { error: err.message }).catch(() => {});
    next(err);
  }
});

// Add BigQuery reference for analytics flushing
const { BigQuery } = require('@google-cloud/bigquery');
const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT_ID;
let bigquery = null;
if (PROJECT_ID && PROJECT_ID !== 'your-project-id-here') {
  bigquery = new BigQuery({ projectId: PROJECT_ID });
}

module.exports = router;
