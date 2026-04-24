#!/usr/bin/env node
/**
 * Database initialization script
 * Run: node scripts/init-db.js
 */

const fs = require('fs');
const path = require('path');
const { pool } = require('../src/config/postgres');

async function initializeDatabase() {
  console.log('🔧 Initializing VoteReady Database...\n');
  
  try {
    // Read schema file
    const schemaPath = path.join(__dirname, '../src/config/schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    
    // Execute schema
    await pool.query(schema);
    
    console.log('✅ Database schema created successfully!');
    console.log('📊 Tables created:');
    console.log('   • users - Core user data with verification tracking');
    console.log('   • verification_documents - Document uploads and OCR');
    console.log('   • aadhaar_verifications - E-KYC integration');
    console.log('   • voter_id_verifications - EPIC verification');
    console.log('   • state_logs - State machine audit trail');
    console.log('   • audit_logs - Security & compliance logging');
    console.log('');
    console.log('👁️  Views created:');
    console.log('   • user_verification_summary');
    console.log('   • verification_stats');
    console.log('');
    console.log('🎉 Database ready for government-grade verification!');
    
  } catch (error) {
    console.error('❌ Database initialization failed:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

// Run if called directly
if (require.main === module) {
  initializeDatabase();
}

module.exports = { initializeDatabase };
