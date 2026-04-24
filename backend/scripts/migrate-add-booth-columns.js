#!/usr/bin/env node
/**
 * Migration: Add booth columns to users table
 * Run: node scripts/migrate-add-booth-columns.js
 */

require('dotenv').config();
const { pool } = require('../src/config/postgres');

async function migrate() {
  console.log('🔧 Running migration: Add booth columns to users table...\n');
  
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    // Check if columns exist
    const checkResult = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      AND column_name = 'booth_known'
    `);
    
    if (checkResult.rows.length > 0) {
      console.log('✅ booth_known column already exists, skipping migration');
      await client.query('COMMIT');
      return;
    }
    
    // Add booth columns
    await client.query(`
      ALTER TABLE users 
      ADD COLUMN booth_known BOOLEAN DEFAULT FALSE,
      ADD COLUMN booth_name VARCHAR(200),
      ADD COLUMN booth_address TEXT,
      ADD COLUMN booth_lat DECIMAL(10, 8),
      ADD COLUMN booth_lng DECIMAL(11, 8)
    `);
    
    await client.query('COMMIT');
    
    console.log('✅ Migration successful!');
    console.log('📊 Added columns:');
    console.log('   • booth_known - BOOLEAN DEFAULT FALSE');
    console.log('   • booth_name - VARCHAR(200)');
    console.log('   • booth_address - TEXT');
    console.log('   • booth_lat - DECIMAL(10, 8)');
    console.log('   • booth_lng - DECIMAL(11, 8)');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

if (require.main === module) {
  migrate();
}

module.exports = { migrate };
