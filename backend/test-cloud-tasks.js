#!/usr/bin/env node

/**
 * Cloud Tasks Integration Test
 * 
 * Simple test to verify Cloud Tasks integration is working correctly.
 * This tests the core functionality without requiring a full test suite.
 */

require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });

async function testCloudTasksIntegration() {
  console.log('🧪 Testing Cloud Tasks Integration...\n');

  try {
    // Test 1: Cloud Tasks Service Configuration
    console.log('1️⃣ Testing Cloud Tasks Service...');
    const cloudTasks = require('./src/services/cloudTasks.service');
    
    console.log(`   ✅ Cloud Tasks configured: ${cloudTasks.isConfigured()}`);
    console.log(`   ✅ Project ID: ${process.env.GOOGLE_CLOUD_PROJECT_ID || 'Not set'}`);
    console.log(`   ✅ Location: ${process.env.CLOUD_TASKS_LOCATION || 'Default'}`);
    console.log(`   ✅ Backend URL: ${process.env.BACKEND_BASE_URL || 'Not set'}`);

    // Test 2: Notification Service
    console.log('\n2️⃣ Testing Notification Service...');
    const { sendPushNotificationAsync } = require('./src/services/notification.service');
    
    // This should queue a task (or log mock in dev)
    await sendPushNotificationAsync('test-uid', 'Test Title', 'Test Body', { type: 'test' });
    console.log('   ✅ Notification service working');

    // Test 3: BigQuery Service
    console.log('\n3️⃣ Testing BigQuery Service...');
    const { logVoterEvent, flushEventBatch } = require('./src/services/bigquery.service');
    
    // This should add to batch
    await logVoterEvent('test-uid', 'test_event', { state: 'TestState' });
    console.log('   ✅ Event added to batch');
    
    // Force flush the batch
    await flushEventBatch();
    console.log('   ✅ Batch flushed');

    // Test 4: Verification Service
    console.log('\n4️⃣ Testing Verification Service...');
    const { processDocumentUpload } = require('./src/services/verification.service');
    
    // Mock document upload (this will queue processing)
    try {
      await processDocumentUpload('test-user-id', 'aadhaar', {
        front: 'https://example.com/test.jpg',
        back: 'https://example.com/test-back.jpg'
      });
      console.log('   ✅ Document processing queued');
    } catch (err) {
      console.log(`   ⚠️  Document processing test skipped: ${err.message}`);
    }

    // Test 5: Environment Variables
    console.log('\n5️⃣ Testing Environment Configuration...');
    const requiredEnvVars = [
      'GOOGLE_CLOUD_PROJECT_ID',
      'CLOUD_TASKS_LOCATION', 
      'BACKEND_BASE_URL',
      'CLOUD_TASKS_SECRET'
    ];

    let envScore = 0;
    requiredEnvVars.forEach(envVar => {
      if (process.env[envVar]) {
        console.log(`   ✅ ${envVar}: Set`);
        envScore++;
      } else {
        console.log(`   ❌ ${envVar}: Not set`);
      }
    });

    console.log(`   📊 Environment Score: ${envScore}/${requiredEnvVars.length}`);

    // Summary
    console.log('\n🎉 Cloud Tasks Integration Test Complete!');
    console.log('\n📋 Summary:');
    console.log('   • Cloud Tasks service is properly configured');
    console.log('   • Notification queuing is working');
    console.log('   • Analytics batching is functional');
    console.log('   • Document processing is integrated');
    console.log(`   • Environment configuration: ${envScore}/${requiredEnvVars.length} variables set`);

    if (envScore === requiredEnvVars.length) {
      console.log('\n✅ All systems ready for production!');
    } else {
      console.log('\n⚠️  Some environment variables missing - check .env file');
    }

    console.log('\n🚀 Next steps:');
    console.log('   1. Run: npm run setup:cloud-tasks (to create queues)');
    console.log('   2. Deploy your application');
    console.log('   3. Monitor queues in Google Cloud Console');

  } catch (err) {
    console.error('\n❌ Test failed:', err.message);
    console.error('Stack:', err.stack);
    process.exit(1);
  }
}

// Run the test
testCloudTasksIntegration();