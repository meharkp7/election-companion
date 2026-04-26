const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const { errorMiddleware } = require('./middleware/error.middleware');
const { verifyAppCheck } = require('./middleware/appcheck.middleware');

const userRoutes        = require('./routes/user.routes');
const electionRoutes    = require('./routes/election.routes');
const statsRoutes       = require('./routes/stats.routes');
const assistantRoutes   = require('./routes/assistant.routes');
const verificationRoutes = require('./routes/verification.routes');
const featuresRoutes    = require('./routes/features.routes');
const allFeaturesRoutes = require('./routes/allFeatures.routes');
const digilockerRoutes  = require('./routes/digilocker.routes');
const tasksRoutes       = require('./routes/tasks.routes');

require('./jobs/reminder.job');
require('./jobs/stats.job');

const app = express();

// ── Security & parsing ──────────────────────────────────────────────────────
app.use(helmet());
app.use(cors());
app.use(compression()); // gzip responses — improves bandwidth efficiency
app.use(express.json());
app.use(morgan('dev'));
app.set('trust proxy', 1);

// ── Rate limiting ───────────────────────────────────────────────────────────
const limiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 100 });
app.use(limiter);

// ── Cache-control headers for public/static-ish endpoints ──────────────────
app.use('/api/election', (req, res, next) => {
  if (req.method === 'GET') {
    // Election info changes infrequently — cache at CDN/proxy for 5 min
    res.set('Cache-Control', 'public, max-age=300, stale-while-revalidate=60');
  }
  next();
});

// ── Firebase App Check — protects all /api routes in production ─────────────
app.use('/api', verifyAppCheck);

// ── Public API routes ───────────────────────────────────────────────────────
app.use('/api/user',         userRoutes);
app.use('/api/election',     electionRoutes);
app.use('/api/stats',        statsRoutes);
app.use('/api/assistant',    assistantRoutes);
app.use('/api/verification', verificationRoutes);
app.use('/api/features',     featuresRoutes);
app.use('/api/v2/features',  allFeaturesRoutes);
app.use('/api/digilocker',   digilockerRoutes);

// ── Internal Cloud Tasks callbacks (not under /api — no App Check) ──────────
app.use('/internal/tasks', tasksRoutes);

// ── Health checks ───────────────────────────────────────────────────────────
app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.get('/health/detailed', async (req, res) => {
  const checks = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    services: {},
  };

  // PostgreSQL
  try {
    const { query } = require('./config/postgres');
    await query('SELECT 1');
    checks.services.database = 'ok';
  } catch {
    checks.services.database = 'error';
    checks.status = 'degraded';
  }

  // BigQuery
  try {
    const bq = require('./services/bigquery.service');
    checks.services.bigquery = (bq.isBigQueryConfigured && bq.isBigQueryConfigured())
      ? 'configured'
      : 'not_configured';
  } catch {
    checks.services.bigquery = 'not_configured';
  }

  // Vertex AI
  checks.services.vertexai = process.env.GOOGLE_CLOUD_PROJECT_ID ? 'configured' : 'not_configured';

  // Cloud Tasks
  try {
    const tasks = require('./services/cloudTasks.service');
    checks.services.cloudTasks = (tasks.isConfigured && tasks.isConfigured())
      ? 'configured'
      : 'not_configured';
  } catch {
    checks.services.cloudTasks = 'not_configured';
  }

  // Cache
  const cache = require('./services/cache.service');
  checks.services.cache = cache.healthStats();

  const httpStatus = checks.status === 'ok' ? 200 : 503;
  res.status(httpStatus).json(checks);
});

// ── Error handler (must be last) ────────────────────────────────────────────
app.use(errorMiddleware);

module.exports = app;
