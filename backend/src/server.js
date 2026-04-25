require('dotenv').config({
  path: require('path').resolve(__dirname, '../.env'),
});

const app = require('./app');
const { connectDB } = require('./config/postgres');
const { initBigQuery } = require('./services/bigquery.service');

const PORT = process.env.PORT || 5001;

// Connect DB, initialise BigQuery, then start server
connectDB().then(async () => {
  // BigQuery init is non-blocking — failure won't prevent startup
  await initBigQuery().catch((err) =>
    console.warn('BigQuery init skipped:', err.message)
  );

  app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📚 API Documentation: http://localhost:${PORT}/api`);
  });
});