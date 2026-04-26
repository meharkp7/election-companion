require('dotenv').config({
  path: require('path').resolve(__dirname, '../.env'),
});

const app = require('./app');
const { connectDB } = require('./config/postgres');
const { initBigQuery } = require('./services/bigquery.service');
const { initGracefulShutdown } = require('./services/gracefulShutdown.service');

const PORT = process.env.PORT || 5001;

// Initialize graceful shutdown handlers
initGracefulShutdown();

// Connect DB, initialise BigQuery, then start server
connectDB().then(async () => {
  // BigQuery init is non-blocking — failure won't prevent startup
  await initBigQuery().catch((err) =>
    console.warn('BigQuery init skipped:', err.message)
  );

  const server = app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📚 API Documentation: http://localhost:${PORT}/api`);
    console.log(`☁️  Cloud Tasks: ${process.env.GOOGLE_CLOUD_PROJECT_ID ? 'Configured' : 'Not configured'}`);
  });

  // Handle server shutdown gracefully
  process.on('SIGTERM', () => {
    console.log('SIGTERM received, closing HTTP server...');
    server.close(() => {
      console.log('HTTP server closed');
    });
  });
});