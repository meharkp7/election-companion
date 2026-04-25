/**
 * Google Cloud Logging Service
 *
 * Structured logging to Cloud Logging (formerly Stackdriver).
 * Falls back to console when not configured.
 *
 * Usage:
 *   const { log } = require('./cloudLogging.service');
 *   log.info('user_verified', { firebaseUid, state });
 *   log.error('verification_failed', { error: err.message });
 *   log.warn('rate_limit_hit', { ip });
 */

const { Logging } = require('@google-cloud/logging');

const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT_ID;
const LOG_NAME = process.env.CLOUD_LOG_NAME || 'voteready-app';

const isConfigured = () =>
  !!(PROJECT_ID && PROJECT_ID !== 'your-project-id-here');

let loggingClient = null;
let cloudLog = null;

if (isConfigured()) {
  try {
    loggingClient = new Logging({ projectId: PROJECT_ID });
    cloudLog = loggingClient.log(LOG_NAME);
    console.log('✅ Cloud Logging initialised');
  } catch (err) {
    console.warn('⚠️  Cloud Logging init failed:', err.message);
  }
}

// ── Severity helpers ────────────────────────────────────────────────────────

/**
 * Write a structured log entry to Cloud Logging.
 * @param {'DEFAULT'|'INFO'|'WARNING'|'ERROR'|'CRITICAL'} severity
 * @param {string} message  Short event name (e.g. 'user_verified')
 * @param {object} payload  Structured data attached to the entry
 */
async function writeLog(severity, message, payload = {}) {
  const entry = {
    severity,
    message,
    timestamp: new Date().toISOString(),
    service: 'voteready-backend',
    environment: process.env.NODE_ENV || 'development',
    ...payload,
  };

  if (!cloudLog) {
    // Local fallback — structured JSON so log aggregators can still parse it
    const fn = severity === 'ERROR' || severity === 'CRITICAL'
      ? console.error
      : severity === 'WARNING'
        ? console.warn
        : console.log;
    fn(JSON.stringify(entry));
    return;
  }

  try {
    const metadata = { resource: { type: 'global' }, severity };
    const logEntry = cloudLog.entry(metadata, entry);
    await cloudLog.write(logEntry);
  } catch (err) {
    // Never let logging failures crash the app
    console.error('Cloud Logging write error:', err.message);
  }
}

// ── Public API ──────────────────────────────────────────────────────────────

const log = {
  /** Informational event (user actions, state transitions) */
  info: (message, payload) => writeLog('INFO', message, payload),

  /** Non-critical warning (rate limit, fallback used) */
  warn: (message, payload) => writeLog('WARNING', message, payload),

  /** Recoverable error (API call failed, retrying) */
  error: (message, payload) => writeLog('ERROR', message, payload),

  /** Critical failure (DB down, auth broken) */
  critical: (message, payload) => writeLog('CRITICAL', message, payload),

  /** Security event (invalid token, suspicious activity) */
  security: (message, payload) =>
    writeLog('WARNING', message, { ...payload, securityEvent: true }),
};

module.exports = { log, isConfigured };
