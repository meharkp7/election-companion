#!/usr/bin/env node
/**
 * Migration: Add all feature tables
 * Run: node scripts/migrate-all-features.js
 */

require('dotenv').config();
const { pool } = require('../src/config/postgres');

async function migrate() {
  console.log('🔧 Running migration: Adding all feature tables...\n');
  
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    // Enable UUID extension first
    console.log('🔧 Enabling UUID extension...');
    await client.query(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp"`);

    // ==========================================
    // 1. POLLING DAY KIT - Voter Slips
    // ==========================================
    console.log('📋 Creating voter_slips table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS voter_slips (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        firebase_uid VARCHAR(128) NOT NULL,
        
        -- Digital Voter Slip
        epic_number VARCHAR(20),
        voter_name TEXT,
        part_number VARCHAR(10),
        serial_number VARCHAR(10),
        polling_station_name TEXT,
        polling_station_address TEXT,
        
        -- Document Images
        slip_image_url TEXT,
        epic_front_image_url TEXT,
        epic_back_image_url TEXT,
        id_proof_image_url TEXT,
        
        -- Validation Status
        documents_verified BOOLEAN DEFAULT FALSE,
        verification_method VARCHAR(50),
        verified_at TIMESTAMP WITH TIME ZONE,
        
        -- Offline Cache
        offline_synced BOOLEAN DEFAULT FALSE,
        cached_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      CREATE INDEX IF NOT EXISTS idx_voter_slips_user_id ON voter_slips(user_id);
      CREATE INDEX IF NOT EXISTS idx_voter_slips_firebase_uid ON voter_slips(firebase_uid);
    `);

    // ==========================================
    // 2. POLLING DAY KIT - Checklists
    // ==========================================
    console.log('✅ Creating polling_checklists table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS polling_checklists (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        firebase_uid VARCHAR(128) NOT NULL,
        
        -- Check Items
        has_epic BOOLEAN DEFAULT FALSE,
        has_photo_id BOOLEAN DEFAULT FALSE,
        has_voter_slip BOOLEAN DEFAULT FALSE,
        phone_charged BOOLEAN DEFAULT FALSE,
        knows_booth_location BOOLEAN DEFAULT FALSE,
        checked_documents_night_before BOOLEAN DEFAULT FALSE,
        
        -- Panic Button History
        panic_button_used BOOLEAN DEFAULT FALSE,
        panic_reason VARCHAR(50),
        panic_resolved BOOLEAN DEFAULT FALSE,
        panic_triggered_at TIMESTAMP WITH TIME ZONE,
        
        -- Completion
        checklist_completed BOOLEAN DEFAULT FALSE,
        completed_at TIMESTAMP WITH TIME ZONE,
        
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      CREATE INDEX IF NOT EXISTS idx_checklists_user_id ON polling_checklists(user_id);
      CREATE INDEX IF NOT EXISTS idx_checklists_firebase_uid ON polling_checklists(firebase_uid);
    `);

    // ==========================================
    // 3. ELECTION TRACKER - Election Dates
    // ==========================================
    console.log('📅 Creating election_phases table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS election_phases (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        
        -- Election Info
        election_year INTEGER NOT NULL,
        election_type VARCHAR(50) NOT NULL, -- 'lok_sabha', 'state_assembly'
        state VARCHAR(50),
        phase_number INTEGER,
        
        -- Dates
        polling_date DATE NOT NULL,
        counting_date DATE,
        result_declaration_date DATE,
        
        -- Constituencies in this phase
        constituencies TEXT[], -- Array of constituency names
        total_seats INTEGER,
        
        -- Status
        status VARCHAR(30) DEFAULT 'upcoming', -- 'upcoming', 'active', 'completed'
        
        -- Live Data URLs
        turnout_data_url TEXT,
        results_data_url TEXT,
        
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      CREATE INDEX IF NOT EXISTS idx_election_phases_state ON election_phases(state);
      CREATE INDEX IF NOT EXISTS idx_election_phases_status ON election_phases(status);
      CREATE INDEX IF NOT EXISTS idx_election_phases_date ON election_phases(polling_date);
    `);

    // ==========================================
    // 4. ELECTION TRACKER - User Calendar/Reminders
    // ==========================================
    console.log('🔔 Creating user_election_calendar table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS user_election_calendar (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        firebase_uid VARCHAR(128) NOT NULL,
        election_phase_id UUID REFERENCES election_phases(id),
        
        -- Personalized Reminders
        booth_visit_reminder_sent BOOLEAN DEFAULT FALSE,
        documents_reminder_sent BOOLEAN DEFAULT FALSE,
        transport_reminder_sent BOOLEAN DEFAULT FALSE,
        
        -- User Preferences
        reminder_timing VARCHAR(20) DEFAULT '1_day_before', -- '2_days', '1_day', 'morning_of'
        notification_method VARCHAR(20) DEFAULT 'push', -- 'push', 'sms', 'both'
        
        -- Sample Ballot Viewed
        sample_ballet_viewed BOOLEAN DEFAULT FALSE,
        sample_ballot_viewed_at TIMESTAMP WITH TIME ZONE,
        
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        
        UNIQUE(user_id, election_phase_id)
      );
      
      CREATE INDEX IF NOT EXISTS idx_user_calendar_user_id ON user_election_calendar(user_id);
    `);

    // ==========================================
    // 5. LIVE RESULTS - Results Data
    // ==========================================
    console.log('📊 Creating election_results table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS election_results (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        election_phase_id UUID REFERENCES election_phases(id),
        
        -- Constituency Info
        state VARCHAR(50) NOT NULL,
        constituency VARCHAR(100) NOT NULL,
        constituency_number VARCHAR(10),
        
        -- Result Data
        status VARCHAR(30) DEFAULT 'counting', -- 'counting', 'completed', 'tied', 'postponed'
        total_votes INTEGER,
        valid_votes INTEGER,
        rejected_votes INTEGER,
        
        -- Winner
        winning_candidate VARCHAR(100),
        winning_party VARCHAR(50),
        winning_margin INTEGER,
        winning_margin_percentage DECIMAL(5, 2),
        
        -- Turnout
        registered_voters INTEGER,
        votes_polled INTEGER,
        turnout_percentage DECIMAL(5, 2),
        
        -- Historical Comparison
        previous_winner VARCHAR(100),
        previous_winner_party VARCHAR(50),
        previous_turnout DECIMAL(5, 2),
        
        -- Last Updated
        last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      CREATE INDEX IF NOT EXISTS idx_results_constituency ON election_results(state, constituency);
      CREATE INDEX IF NOT EXISTS idx_results_status ON election_results(status);
      CREATE INDEX IF NOT EXISTS idx_results_election ON election_results(election_phase_id);
    `);

    // ==========================================
    // 6. LIVE RESULTS - Candidate Results
    // ==========================================
    console.log('👤 Creating candidate_results table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS candidate_results (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        result_id UUID NOT NULL REFERENCES election_results(id) ON DELETE CASCADE,
        candidate_id UUID, -- References candidates(id) when table exists
        
        -- Candidate Info (denormalized for speed)
        candidate_name VARCHAR(100) NOT NULL,
        party VARCHAR(50),
        party_symbol VARCHAR(50),
        
        -- Vote Data
        votes_received INTEGER,
        vote_share_percentage DECIMAL(5, 2),
        position INTEGER, -- 1st, 2nd, 3rd, etc.
        
        -- Status
        status VARCHAR(20) DEFAULT 'counting', -- 'counting', 'won', 'lost', 'leading', 'trailing'
        
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      CREATE INDEX IF NOT EXISTS idx_candidate_results_result_id ON candidate_results(result_id);
      CREATE INDEX IF NOT EXISTS idx_candidate_results_position ON candidate_results(position);
    `);

    // ==========================================
    // 7. VOTER RIGHTS & HELP - Knowledge Base
    // ==========================================
    console.log('📚 Creating voter_rights_guides table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS voter_rights_guides (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        
        -- Content
        topic VARCHAR(50) NOT NULL, -- 'missing_name', 'evm_issue', 'rights', 'accessibility', etc.
        title VARCHAR(200) NOT NULL,
        content TEXT NOT NULL,
        quick_steps TEXT[],
        
        -- Categorization
        category VARCHAR(50), -- 'emergency', 'rights', 'procedure', 'accessibility'
        priority INTEGER DEFAULT 0, -- For ordering
        
        -- Media
        video_url TEXT,
        infographic_url TEXT,
        
        -- Metadata
        language VARCHAR(10) DEFAULT 'en',
        is_active BOOLEAN DEFAULT TRUE,
        
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      CREATE INDEX IF NOT EXISTS idx_voter_rights_topic ON voter_rights_guides(topic);
      CREATE INDEX IF NOT EXISTS idx_voter_rights_category ON voter_rights_guides(category);
    `);

    // ==========================================
    // 8. VOTER RIGHTS - Helpline Contacts
    // ==========================================
    console.log('☎️ Creating helpline_contacts table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS helpline_contacts (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        
        -- Contact Info
        name VARCHAR(100) NOT NULL,
        contact_type VARCHAR(50), -- 'helpline', 'ceo_office', 'blo', 'ero', 'control_room'
        phone VARCHAR(20),
        email VARCHAR(100),
        
        -- Location
        state VARCHAR(50),
        constituency VARCHAR(100),
        
        -- Purpose
        purpose VARCHAR(200),
        available_hours VARCHAR(50),
        
        -- Priority
        is_primary BOOLEAN DEFAULT FALSE,
        priority INTEGER DEFAULT 0,
        
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      CREATE INDEX IF NOT EXISTS idx_helpline_state ON helpline_contacts(state);
      CREATE INDEX IF NOT EXISTS idx_helpline_type ON helpline_contacts(contact_type);
    `);

    // ==========================================
    // 9. SOCIAL FEATURES - Carpool/Rideshare
    // ==========================================
    console.log('🚗 Creating booth_carpools table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS booth_carpools (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        
        -- Creator
        creator_firebase_uid VARCHAR(128) NOT NULL,
        creator_name VARCHAR(100),
        creator_phone VARCHAR(15),
        
        -- Booth Details
        booth_name TEXT NOT NULL,
        constituency VARCHAR(100),
        state VARCHAR(50),
        meeting_point TEXT,
        
        -- Trip Details
        ride_type VARCHAR(20) DEFAULT 'offer', -- 'offer', 'request'
        vehicle_type VARCHAR(20), -- 'car', 'bike', 'auto', 'walking'
        seats_available INTEGER,
        
        -- Timing
        departure_time TIMESTAMP WITH TIME ZONE NOT NULL,
        return_trip BOOLEAN DEFAULT FALSE,
        return_time TIMESTAMP WITH TIME ZONE,
        
        -- Participants
        passengers TEXT[], -- Array of firebase UIDs
        max_passengers INTEGER DEFAULT 3,
        
        -- Status
        status VARCHAR(20) DEFAULT 'active', -- 'active', 'full', 'completed', 'cancelled'
        
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      CREATE INDEX IF NOT EXISTS idx_carpools_booth ON booth_carpools(booth_name, constituency);
      CREATE INDEX IF NOT EXISTS idx_carpools_state ON booth_carpools(state);
      CREATE INDEX IF NOT EXISTS idx_carpools_status ON booth_carpools(status);
      CREATE INDEX IF NOT EXISTS idx_carpools_time ON booth_carpools(departure_time);
    `);

    // ==========================================
    // 10. SOCIAL FEATURES - I Voted Records
    // ==========================================
    console.log('🗳️ Creating i_voted_records table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS i_voted_records (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        firebase_uid VARCHAR(128) NOT NULL UNIQUE,
        
        -- Voting Details
        booth_name TEXT,
        constituency VARCHAR(100),
        state VARCHAR(50),
        
        -- Timestamp & Verification
        voted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        verified_via VARCHAR(50), -- 'self_reported', 'eci_api', 'photo_upload'
        
        -- Photo Badge
        badge_image_url TEXT,
        badge_generated BOOLEAN DEFAULT FALSE,
        
        -- Privacy
        share_publicly BOOLEAN DEFAULT TRUE,
        share_anonymously BOOLEAN DEFAULT FALSE,
        
        -- Engagement
        shared_count INTEGER DEFAULT 0,
        likes_count INTEGER DEFAULT 0,
        
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      CREATE INDEX IF NOT EXISTS idx_i_voted_user_id ON i_voted_records(user_id);
      CREATE INDEX IF NOT EXISTS idx_i_voted_constituency ON i_voted_records(constituency);
      CREATE INDEX IF NOT EXISTS idx_i_voted_voted_at ON i_voted_records(voted_at);
    `);

    // ==========================================
    // 11. LIVE TURNOUT - Hourly Data
    // ==========================================
    console.log('📈 Creating live_turnout_data table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS live_turnout_data (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        election_phase_id UUID REFERENCES election_phases(id),
        
        -- Location
        state VARCHAR(50) NOT NULL,
        constituency VARCHAR(100),
        booth_name TEXT,
        
        -- Turnout Data
        hour_interval VARCHAR(10), -- '08:00', '09:00', etc.
        cumulative_percentage DECIMAL(5, 2),
        votes_polled INTEGER,
        
        -- Comparison
        previous_election_percentage DECIMAL(5, 2),
        difference_from_previous DECIMAL(5, 2),
        
        -- Timestamp
        recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      CREATE INDEX IF NOT EXISTS idx_turnout_state ON live_turnout_data(state);
      CREATE INDEX IF NOT EXISTS idx_turnout_constituency ON live_turnout_data(constituency);
      CREATE INDEX IF NOT EXISTS idx_turnout_time ON live_turnout_data(recorded_at);
    `);

    await client.query('COMMIT');
    
    console.log('\n✅ All feature tables created successfully!');
    console.log('\n📊 Tables added:');
    console.log('   • voter_slips - Digital voter slip storage');
    console.log('   • polling_checklists - Polling day preparation');
    console.log('   • election_phases - Election dates and phases');
    console.log('   • user_election_calendar - Personalized reminders');
    console.log('   • election_results - Live results');
    console.log('   • candidate_results - Candidate-wise results');
    console.log('   • voter_rights_guides - Rights & help content');
    console.log('   • helpline_contacts - ECI & state helplines');
    console.log('   • booth_carpools - Ride sharing to booths');
    console.log('   • i_voted_records - I voted badges');
    console.log('   • live_turnout_data - Hourly turnout tracking');
    
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
