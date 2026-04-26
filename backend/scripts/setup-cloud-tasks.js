#!/usr/bin/env node

/**
 * Cloud Tasks Setup Script
 * 
 * Creates the required Cloud Tasks queues for the VoteReady application.
 * Run this script once after setting up your Google Cloud project.
 * 
 * Usage: node scripts/setup-cloud-tasks.js
 */

require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const { CloudTasksClient } = require('@google-cloud/tasks');

const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT_ID;
const LOCATION = process.env.CLOUD_TASKS_LOCATION || 'asia-south1';

const QUEUES = [
  {
    name: process.env.TASKS_QUEUE_NOTIFICATIONS || 'notifications-queue',
    description: 'Queue for FCM push notification delivery',
    rateLimits: {
      maxDispatchesPerSecond: 100,
      maxBurstSize: 100,
      maxConcurrentDispatches: 50,
    },
    retryConfig: {
      maxAttempts: 3,
      maxRetryDuration: '300s',
      minBackoff: '1s',
      maxBackoff: '10s',
      maxDoublings: 3,
    },
  },
  {
    name: process.env.TASKS_QUEUE_ANALYTICS || 'analytics-queue',
    description: 'Queue for BigQuery analytics batch processing',
    rateLimits: {
      maxDispatchesPerSecond: 50,
      maxBurstSize: 100,
      maxConcurrentDispatches: 25,
    },
    retryConfig: {
      maxAttempts: 5,
      maxRetryDuration: '600s',
      minBackoff: '2s',
      maxBackoff: '30s',
      maxDoublings: 4,
    },
  },
  {
    name: process.env.TASKS_QUEUE_DOCUMENTS || 'document-queue',
    description: 'Queue for Document AI processing jobs',
    rateLimits: {
      maxDispatchesPerSecond: 10,
      maxBurstSize: 20,
      maxConcurrentDispatches: 10,
    },
    retryConfig: {
      maxAttempts: 3,
      maxRetryDuration: '900s',
      minBackoff: '5s',
      maxBackoff: '60s',
      maxDoublings: 3,
    },
  },
];

async function setupCloudTasks() {
  if (!PROJECT_ID || PROJECT_ID === 'your-project-id-here') {
    console.error('❌ GOOGLE_CLOUD_PROJECT_ID not configured in .env file');
    process.exit(1);
  }

  console.log(`🚀 Setting up Cloud Tasks queues for project: ${PROJECT_ID}`);
  console.log(`📍 Location: ${LOCATION}`);

  const client = new CloudTasksClient();
  const parent = client.locationPath(PROJECT_ID, LOCATION);

  for (const queueConfig of QUEUES) {
    try {
      const queuePath = client.queuePath(PROJECT_ID, LOCATION, queueConfig.name);
      
      // Check if queue already exists
      try {
        await client.getQueue({ name: queuePath });
        console.log(`✅ Queue '${queueConfig.name}' already exists`);
        continue;
      } catch (err) {
        if (err.code !== 5) { // NOT_FOUND
          throw err;
        }
      }

      // Create the queue
      const queue = {
        name: queuePath,
        rateLimits: queueConfig.rateLimits,
        retryConfig: queueConfig.retryConfig,
      };

      await client.createQueue({
        parent,
        queue,
      });

      console.log(`✅ Created queue '${queueConfig.name}'`);
      console.log(`   Description: ${queueConfig.description}`);
      console.log(`   Max dispatches/sec: ${queueConfig.rateLimits.maxDispatchesPerSecond}`);
      console.log(`   Max concurrent: ${queueConfig.rateLimits.maxConcurrentDispatches}`);
      console.log(`   Max retry attempts: ${queueConfig.retryConfig.maxAttempts}`);
      console.log('');

    } catch (err) {
      console.error(`❌ Failed to create queue '${queueConfig.name}':`, err.message);
      process.exit(1);
    }
  }

  console.log('🎉 Cloud Tasks setup completed successfully!');
  console.log('');
  console.log('Next steps:');
  console.log('1. Ensure your service account has Cloud Tasks Admin role');
  console.log('2. Configure queue-level IAM permissions if needed');
  console.log('3. Test the queues by running your application');
  console.log('');
  console.log('Monitor queues at:');
  console.log(`https://console.cloud.google.com/cloudtasks/queues?project=${PROJECT_ID}`);
}

// Run the setup
setupCloudTasks().catch((err) => {
  console.error('❌ Setup failed:', err);
  process.exit(1);
});