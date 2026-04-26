/**
 * Google Cloud Tasks Service
 *
 * Provides async task dispatch via Cloud Tasks HTTP queues.
 * Falls back to direct in-process execution when Cloud Tasks
 * is not configured (local dev / CI).
 *
 * Queues used:
 *  - notifications-queue  : FCM push notification dispatch
 *  - analytics-queue      : BigQuery batch flush
 *  - document-queue       : Document AI processing jobs
 */

const { CloudTasksClient } = require('@google-cloud/tasks');

const PROJECT_ID  = process.env.GOOGLE_CLOUD_PROJECT_ID;
const LOCATION    = process.env.CLOUD_TASKS_LOCATION  || 'asia-south1';
const BASE_URL    = process.env.BACKEND_BASE_URL       || 'http://localhost:5001';

// Queue names (configurable via env)
const QUEUES = {
  notifications: process.env.TASKS_QUEUE_NOTIFICATIONS || 'notifications-queue',
  analytics:     process.env.TASKS_QUEUE_ANALYTICS     || 'analytics-queue',
  documents:     process.env.TASKS_QUEUE_DOCUMENTS     || 'document-queue',
};

/**
 * Returns true when Cloud Tasks is properly configured.
 * @returns {boolean}
 */
const isConfigured = () =>
  !!(PROJECT_ID && PROJECT_ID !== 'your-project-id-here');

let tasksClient = null;
if (isConfigured()) {
  try {
    tasksClient = new CloudTasksClient();
    console.log('✅ Cloud Tasks initialised');
  } catch (err) {
    console.warn('⚠️  Cloud Tasks init failed:', err.message);
  }
}

// ── Internal helpers ────────────────────────────────────────────────────────

/**
 * Build the fully-qualified queue path.
 * @param {string} queueName
 * @returns {string}
 */
function queuePath(queueName) {
  return tasksClient.queuePath(PROJECT_ID, LOCATION, queueName);
}

/**
 * Enqueue an HTTP task that POSTs `payload` to `relativeUrl`.
 * Falls back to a no-op log when Cloud Tasks is not configured.
 *
 * @param {string} queueName     One of the QUEUES values
 * @param {string} relativeUrl   e.g. '/internal/tasks/send-notification'
 * @param {object} payload       JSON body sent to the handler
 * @param {number} [delaySeconds=0]  Schedule delay
 * @returns {Promise<string|null>}   Task name or null in mock mode
 */
async function enqueueTask(queueName, relativeUrl, payload, delaySeconds = 0) {
  const body = JSON.stringify(payload);

  if (!tasksClient) {
    console.log(`[CloudTasks mock] queue=${queueName} url=${relativeUrl} payload=${body}`);
    return null;
  }

  const task = {
    httpRequest: {
      httpMethod: 'POST',
      url: `${BASE_URL}${relativeUrl}`,
      headers: { 'Content-Type': 'application/json' },
      body: Buffer.from(body).toString('base64'),
    },
  };

  if (delaySeconds > 0) {
    const scheduleTime = new Date(Date.now() + delaySeconds * 1000);
    task.scheduleTime = {
      seconds: Math.floor(scheduleTime.getTime() / 1000),
    };
  }

  const [response] = await tasksClient.createTask({
    parent: queuePath(queueName),
    task,
  });

  return response.name;
}

// ── Public API ──────────────────────────────────────────────────────────────

/**
 * Enqueue a push notification for async delivery.
 *
 * @param {string} firebaseUid
 * @param {string} title
 * @param {string} body
 * @param {object} [data={}]  Extra FCM data payload
 * @returns {Promise<string|null>}
 */
async function enqueueNotification(firebaseUid, title, body, data = {}) {
  return enqueueTask(
    QUEUES.notifications,
    '/internal/tasks/send-notification',
    { firebaseUid, title, body, data },
  );
}

/**
 * Enqueue a batch of analytics events for BigQuery flush.
 *
 * @param {Array<object>} events
 * @returns {Promise<string|null>}
 */
async function enqueueAnalyticsBatch(events) {
  return enqueueTask(
    QUEUES.analytics,
    '/internal/tasks/flush-analytics',
    { events },
  );
}

/**
 * Enqueue a document processing job.
 *
 * @param {string} firebaseUid
 * @param {string} fileUrl
 * @param {string} documentType
 * @returns {Promise<string|null>}
 */
async function enqueueDocumentProcessing(firebaseUid, fileUrl, documentType) {
  return enqueueTask(
    QUEUES.documents,
    '/internal/tasks/process-document',
    { firebaseUid, fileUrl, documentType },
  );
}

/**
 * Schedule a reminder notification to fire at a future time.
 *
 * @param {string} firebaseUid
 * @param {string} title
 * @param {string} body
 * @param {Date}   scheduledAt
 * @returns {Promise<string|null>}
 */
async function scheduleReminder(firebaseUid, title, body, scheduledAt) {
  const delaySeconds = Math.max(
    0,
    Math.floor((scheduledAt.getTime() - Date.now()) / 1000),
  );
  return enqueueTask(
    QUEUES.notifications,
    '/internal/tasks/send-notification',
    { firebaseUid, title, body, data: { type: 'reminder' } },
    delaySeconds,
  );
}

module.exports = {
  isConfigured,
  enqueueNotification,
  enqueueAnalyticsBatch,
  enqueueDocumentProcessing,
  scheduleReminder,
};
