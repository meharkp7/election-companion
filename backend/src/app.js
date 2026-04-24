const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { errorMiddleware } = require('./middleware/error.middleware');

const userRoutes = require('./routes/user.routes');
const electionRoutes = require('./routes/election.routes');
const statsRoutes = require('./routes/stats.routes');
const assistantRoutes = require('./routes/assistant.routes');
const verificationRoutes = require('./routes/verification.routes');
const featuresRoutes = require('./routes/features.routes');
const allFeaturesRoutes = require('./routes/allFeatures.routes');
const digilockerRoutes = require('./routes/digilocker.routes');

require('./jobs/reminder.job');
require('./jobs/stats.job');

const app = express();

// Security & parsing
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));
app.set('trust proxy', 1);
// Rate limiting
const limiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 100 });
app.use(limiter);

// Routes
app.use('/api/user', userRoutes);
app.use('/api/election', electionRoutes);
app.use('/api/stats', statsRoutes);
app.use('/api/assistant', assistantRoutes);
app.use('/api/verification', verificationRoutes);
app.use('/api/features', featuresRoutes);
app.use('/api/v2/features', allFeaturesRoutes);
app.use('/api/digilocker', digilockerRoutes);

app.get('/health', (req, res) => res.json({ status: 'ok' }));

// Error handler (must be last)
app.use(errorMiddleware);

module.exports = app;