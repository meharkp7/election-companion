/**
 * BigQuery Analytics Service
 *
 * Exports voter engagement events and election analytics to BigQuery
 * for large-scale analysis, dashboards, and ML model training.
 *
 * Dataset: vote_ready_analytics
 * Tables:
 *   - voter_events       : user journey events (onboard, verify, vote)
 *   - election_metrics   : turnout, phase-wise stats per state/phase
 *   - ai_interactions    : assistant queries and response quality
 */

const { BigQuery } = require('@google-cloud/bigquery');
const { enqueueAnalyticsBatch } = require('./cloudTasks.service');

const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT_ID;
const DATASET_ID = process.env.BIGQUERY_DATASET_ID || 'vote_ready_analytics';

// In-memory batch for analytics events
let eventBatch = [];
const BATCH_SIZE = 10;
const BATCH_TIMEOUT = 30000; // 30 seconds

// Only initialise if project is configured
const isBigQueryConfigured = () =>
  !!(PROJECT_ID && PROJECT_ID !== 'your-project-id-here');

let bigquery = null;
if (isBigQueryConfigured()) {
  bigquery = new BigQuery({ projectId: PROJECT_ID });
  console.log('✅ BigQuery initialised');
} else {
  console.log('ℹ️  BigQuery not configured — analytics will be logged locally');
}

// ── Table references ────────────────────────────────────────────────────────

const table = (tableId) =>
  bigquery?.dataset(DATASET_ID).table(tableId);

// ── Schema definitions ──────────────────────────────────────────────────────

const VOTER_EVENTS_SCHEMA = [
  { name: 'event_id',    type: 'STRING',    mode: 'REQUIRED' },
  { name: 'firebase_uid',type: 'STRING',    mode: 'REQUIRED' },
  { name: 'event_type',  type: 'STRING',    mode: 'REQUIRED' },
  { name: 'state',       type: 'STRING',    mode: 'NULLABLE' },
  { name: 'age_group',   type: 'STRING',    mode: 'NULLABLE' },
  { name: 'is_first_time_voter', type: 'BOOLEAN', mode: 'NULLABLE' },
  { name: 'current_state',       type: 'STRING',  mode: 'NULLABLE' },
  { name: 'readiness_score',     type: 'INTEGER', mode: 'NULLABLE' },
  { name: 'metadata',   type: 'JSON',      mode: 'NULLABLE' },
  { name: 'timestamp',  type: 'TIMESTAMP', mode: 'REQUIRED' },
];

const AI_INTERACTIONS_SCHEMA = [
  { name: 'interaction_id', type: 'STRING',    mode: 'REQUIRED' },
  { name: 'firebase_uid',   type: 'STRING',    mode: 'NULLABLE' },
  { name: 'question',       type: 'STRING',    mode: 'REQUIRED' },
  { name: 'response_length',type: 'INTEGER',   mode: 'NULLABLE' },
  { name: 'model_used',     type: 'STRING',    mode: 'NULLABLE' },
  { name: 'latency_ms',     type: 'INTEGER',   mode: 'NULLABLE' },
  { name: 'timestamp',      type: 'TIMESTAMP', mode: 'REQUIRED' },
];

const ELECTION_METRICS_SCHEMA = [
  { name: 'metric_id',       type: 'STRING',    mode: 'REQUIRED' },
  { name: 'state',           type: 'STRING',    mode: 'REQUIRED' },
  { name: 'phase_number',    type: 'INTEGER',   mode: 'NULLABLE' },
  { name: 'metric_type',     type: 'STRING',    mode: 'REQUIRED' },
  { name: 'value',           type: 'FLOAT',     mode: 'NULLABLE' },
  { name: 'total_users',     type: 'INTEGER',   mode: 'NULLABLE' },
  { name: 'voted_users',     type: 'INTEGER',   mode: 'NULLABLE' },
  { name: 'turnout_percent', type: 'FLOAT',     mode: 'NULLABLE' },
  { name: 'avg_readiness',   type: 'FLOAT',     mode: 'NULLABLE' },
  { name: 'metadata',        type: 'JSON',      mode: 'NULLABLE' },
  { name: 'recorded_at',     type: 'TIMESTAMP', mode: 'REQUIRED' },
];

// ── Ensure dataset and tables exist ────────────────────────────────────────

async function ensureDatasetExists() {
  if (!bigquery) return;
  const dataset = bigquery.dataset(DATASET_ID);
  const [exists] = await dataset.exists();
  if (!exists) {
    await dataset.create({ location: 'asia-south1' });
    console.log(`BigQuery dataset ${DATASET_ID} created`);
  }
}

async function ensureTableExists(tableId, schema) {
  if (!bigquery) return;
  const t = table(tableId);
  const [exists] = await t.exists();
  if (!exists) {
    await t.create({ schema });
    console.log(`BigQuery table ${tableId} created`);
  }
}

// ── Public API ──────────────────────────────────────────────────────────────

/**
 * Log a voter journey event to BigQuery.
 * Uses Cloud Tasks for batched processing to improve performance.
 *
 * @param {string} firebaseUid
 * @param {string} eventType  e.g. 'onboarded', 'verified', 'voted'
 * @param {object} context    Additional fields (state, age, currentState, etc.)
 */
async function logVoterEvent(firebaseUid, eventType, context = {}) {
  const event = {
    firebaseUid,
    eventType,
    context,
    timestamp: new Date().toISOString(),
  };

  // Add to batch
  eventBatch.push(event);

  // Send batch if it's full
  if (eventBatch.length >= BATCH_SIZE) {
    await flushEventBatch();
  }

  // Set timeout to flush batch if it's not full
  if (eventBatch.length === 1) {
    setTimeout(flushEventBatch, BATCH_TIMEOUT);
  }
}

/**
 * Log a voter journey event directly to BigQuery (synchronous).
 * Use this for critical events that need immediate processing.
 */
async function logVoterEventSync(firebaseUid, eventType, context = {}) {
  const row = {
    event_id: `${firebaseUid}_${eventType}_${Date.now()}`,
    firebase_uid: firebaseUid,
    event_type: eventType,
    state: context.state ?? null,
    age_group: context.age ? _ageGroup(context.age) : null,
    is_first_time_voter: context.isFirstTimeVoter ?? null,
    current_state: context.currentState ?? null,
    readiness_score: context.readinessScore ?? null,
    metadata: context.metadata ? JSON.stringify(context.metadata) : null,
    timestamp: new Date().toISOString(),
  };

  if (!bigquery) {
    console.log('[BigQuery mock] voter_event:', JSON.stringify(row));
    return;
  }

  try {
    await table('voter_events').insert([row]);
  } catch (err) {
    // BigQuery streaming insert errors are non-fatal
    console.error('BigQuery insert error (voter_events):', err.message);
  }
}

/**
 * Flush the current event batch to Cloud Tasks
 */
async function flushEventBatch() {
  if (eventBatch.length === 0) return;

  const batch = [...eventBatch];
  eventBatch = [];

  try {
    // Convert events to BigQuery format
    const formattedEvents = batch.map(event => ({
      event_id: `${event.firebaseUid}_${event.eventType}_${Date.now()}_${Math.random().toString(36).slice(2)}`,
      firebase_uid: event.firebaseUid,
      event_type: event.eventType,
      state: event.context.state ?? null,
      age_group: event.context.age ? _ageGroup(event.context.age) : null,
      is_first_time_voter: event.context.isFirstTimeVoter ?? null,
      current_state: event.context.currentState ?? null,
      readiness_score: event.context.readinessScore ?? null,
      metadata: event.context.metadata ? JSON.stringify(event.context.metadata) : null,
      timestamp: event.timestamp,
    }));

    await enqueueAnalyticsBatch(formattedEvents);
    console.log(`📊 Queued ${batch.length} analytics events`);
  } catch (err) {
    console.error('Failed to queue analytics batch:', err.message);
    // Fallback: try direct insert for critical events
    for (const event of batch) {
      await logVoterEventSync(event.firebaseUid, event.eventType, event.context).catch(() => {});
    }
  }
}

/**
 * Log an AI assistant interaction.
 */
async function logAIInteraction(firebaseUid, question, responseLength, latencyMs) {
  const row = {
    interaction_id: `ai_${Date.now()}_${Math.random().toString(36).slice(2)}`,
    firebase_uid: firebaseUid ?? null,
    question: question.substring(0, 1024), // cap at 1 KB
    response_length: responseLength,
    model_used: 'gemini-pro',
    latency_ms: latencyMs,
    timestamp: new Date().toISOString(),
  };

  if (!bigquery) {
    console.log('[BigQuery mock] ai_interaction:', JSON.stringify(row));
    return;
  }

  try {
    await table('ai_interactions').insert([row]);
  } catch (err) {
    console.error('BigQuery insert error (ai_interactions):', err.message);
  }
}

/**
 * Log an election metric snapshot (turnout, readiness, phase stats).
 * Used by the hourly stats job to track trends over time.
 *
 * @param {string} state          Indian state name
 * @param {string} metricType     e.g. 'hourly_snapshot', 'phase_complete'
 * @param {object} data           { totalUsers, votedUsers, turnoutPercent, avgReadiness, phaseNumber? }
 */
async function logElectionMetric(state, metricType, data = {}) {
  const row = {
    metric_id:       `metric_${state}_${metricType}_${Date.now()}`,
    state:           state || 'ALL',
    phase_number:    data.phaseNumber ?? null,
    metric_type:     metricType,
    value:           data.value ?? null,
    total_users:     data.totalUsers ?? null,
    voted_users:     data.votedUsers ?? null,
    turnout_percent: data.turnoutPercent ? parseFloat(data.turnoutPercent) : null,
    avg_readiness:   data.avgReadiness ?? null,
    metadata:        data.metadata ? JSON.stringify(data.metadata) : null,
    recorded_at:     new Date().toISOString(),
  };

  if (!bigquery) {
    console.log('[BigQuery mock] election_metric:', JSON.stringify(row));
    return;
  }

  try {
    await table('election_metrics').insert([row]);
  } catch (err) {
    console.error('BigQuery insert error (election_metrics):', err.message);
  }
}

/**
 * Query turnout statistics from BigQuery.
 * Returns aggregated voter event counts grouped by state.
 */
async function queryTurnoutStats() {
  if (!bigquery) {
    return { note: 'BigQuery not configured', data: [] };
  }

  const sql = `
    SELECT
      state,
      COUNT(DISTINCT firebase_uid) AS unique_voters,
      COUNTIF(event_type = 'voted')  AS voted_count,
      ROUND(
        SAFE_DIVIDE(COUNTIF(event_type = 'voted'), COUNT(DISTINCT firebase_uid)) * 100,
        2
      ) AS turnout_pct
    FROM \`${PROJECT_ID}.${DATASET_ID}.voter_events\`
    WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
    GROUP BY state
    ORDER BY turnout_pct DESC
  `;

  const [rows] = await bigquery.query({ query: sql, location: 'asia-south1' });
  return { data: rows };
}

/**
 * Initialise BigQuery resources (call once at startup).
 */
async function initBigQuery() {
  if (!bigquery) return;
  try {
    await ensureDatasetExists();
    await ensureTableExists('voter_events', VOTER_EVENTS_SCHEMA);
    await ensureTableExists('ai_interactions', AI_INTERACTIONS_SCHEMA);
    await ensureTableExists('election_metrics', ELECTION_METRICS_SCHEMA);
    console.log('✅ BigQuery tables ready');
  } catch (err) {
    console.warn('BigQuery init warning:', err.message);
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

function _ageGroup(age) {
  if (age < 25) return '18-24';
  if (age < 35) return '25-34';
  if (age < 45) return '35-44';
  if (age < 60) return '45-59';
  return '60+';
}

module.exports = {
  logVoterEvent,
  logVoterEventSync,
  logAIInteraction,
  logElectionMetric,
  queryTurnoutStats,
  initBigQuery,
  isBigQueryConfigured,
  flushEventBatch,
};
