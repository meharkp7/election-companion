/**
 * Graceful Shutdown Service
 * 
 * Handles cleanup tasks when the server is shutting down,
 * including flushing pending analytics batches to Cloud Tasks.
 */

const { flushEventBatch } = require('./bigquery.service');
const { log } = require('./cloudLogging.service');

let isShuttingDown = false;

/**
 * Initialize graceful shutdown handlers
 */
function initGracefulShutdown() {
  // Handle various shutdown signals
  const signals = ['SIGTERM', 'SIGINT', 'SIGUSR2'];
  
  signals.forEach(signal => {
    process.on(signal, async () => {
      if (isShuttingDown) return;
      isShuttingDown = true;
      
      console.log(`\n🛑 Received ${signal}. Starting graceful shutdown...`);
      
      try {
        // Flush any pending analytics batches
        await flushEventBatch();
        console.log('✅ Analytics batch flushed');
        
        // Log shutdown event
        await log.info('server_shutdown', { signal }).catch(() => {});
        
        console.log('✅ Graceful shutdown completed');
        process.exit(0);
      } catch (err) {
        console.error('❌ Error during graceful shutdown:', err.message);
        process.exit(1);
      }
    });
  });

  // Handle uncaught exceptions
  process.on('uncaughtException', async (err) => {
    console.error('❌ Uncaught Exception:', err);
    await log.error('uncaught_exception', { error: err.message, stack: err.stack }).catch(() => {});
    process.exit(1);
  });

  // Handle unhandled promise rejections
  process.on('unhandledRejection', async (reason, promise) => {
    console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
    await log.error('unhandled_rejection', { reason: reason?.toString() }).catch(() => {});
    process.exit(1);
  });

  console.log('✅ Graceful shutdown handlers initialized');
}

module.exports = {
  initGracefulShutdown,
};