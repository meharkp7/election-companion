-- ==========================================
-- VOTEREADY V2 - ENHANCED FEATURES SCHEMA
-- ==========================================

-- ==========================================
-- CANDIDATES TABLE (Constituency-specific)
-- ==========================================
CREATE TABLE IF NOT EXISTS candidates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Identity
    name VARCHAR(200) NOT NULL,
    party VARCHAR(100),
    party_symbol VARCHAR(200),
    
    -- Constituency
    constituency VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    
    -- Background
    age INTEGER,
    education VARCHAR(200),
    profession VARCHAR(100),
    
    -- Track Record (from ADR/ECI data)
    criminal_cases INTEGER DEFAULT 0,
    serious_charges TEXT,
    assets_declared DECIMAL(15, 2),
    liabilities_declared DECIMAL(15, 2),
    
    -- Parliamentary Performance (for incumbents)
    attendance_percentage DECIMAL(5, 2),
    debates_participated INTEGER DEFAULT 0,
    questions_asked INTEGER DEFAULT 0,
    private_bills INTEGER DEFAULT 0,
    
    -- Contact
    email VARCHAR(100),
    phone VARCHAR(20),
    social_media JSONB,
    
    -- AI Summary
    ai_summary TEXT,
    key_highlights JSONB,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Unique constraint
    UNIQUE(constituency, name, state)
);

CREATE INDEX IF NOT EXISTS idx_candidates_constituency ON candidates(constituency);
CREATE INDEX IF NOT EXISTS idx_candidates_state ON candidates(state);

-- ==========================================
-- COMPLAINTS/GRIEVANCES TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS complaints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- User reference
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    firebase_uid VARCHAR(128) NOT NULL,
    
    -- Complaint details
    complaint_type VARCHAR(50) NOT NULL, -- 'name_missing', 'wrong_details', 'booth_issue', 'other'
    description TEXT,
    
    -- ECI Details
    epic_number VARCHAR(20),
    constituency VARCHAR(100),
    booth_number VARCHAR(50),
    
    -- Status tracking
    status VARCHAR(50) DEFAULT 'submitted', -- 'submitted', 'acknowledged', 'in_progress', 'resolved', 'closed'
    eci_reference_number VARCHAR(50),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE,
    
    -- Meta
    priority VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'urgent'
    assigned_to VARCHAR(100),
    resolution_notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_complaints_user ON complaints(user_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON complaints(status);
CREATE INDEX IF NOT EXISTS idx_complaints_created ON complaints(created_at);

-- ==========================================
-- POLLING BOOTH CROWDSOURCE TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS booth_status_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Booth reference
    booth_name VARCHAR(200) NOT NULL,
    constituency VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    
    -- Report details
    reported_by UUID REFERENCES users(id),
    firebase_uid VARCHAR(128),
    
    -- Status
    queue_length VARCHAR(20), -- 'none', 'short', 'medium', 'long', 'very_long'
    wait_time_minutes INTEGER,
    
    -- Issues
    evm_working BOOLEAN DEFAULT TRUE,
    water_available BOOLEAN DEFAULT TRUE,
    seating_available BOOLEAN DEFAULT TRUE,
    ramp_accessible BOOLEAN DEFAULT TRUE,
    parking_available BOOLEAN DEFAULT TRUE,
    
    -- Issues reported
    issues JSONB, -- array of issue strings
    
    -- Crowd density
    crowd_level INTEGER CHECK (crowd_level >= 1 AND crowd_level <= 5),
    
    -- Best time prediction
    best_time_to_visit VARCHAR(50),
    
    -- Timestamps
    reported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() + INTERVAL '2 hours',
    
    -- Verification
    is_verified BOOLEAN DEFAULT FALSE,
    verification_count INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_booth_status_booth ON booth_status_reports(booth_name, constituency, state);
CREATE INDEX IF NOT EXISTS idx_booth_status_expires ON booth_status_reports(expires_at);
CREATE INDEX IF NOT EXISTS idx_booth_status_reported ON booth_status_reports(reported_at);

-- ==========================================
-- BOOTH HISTORICAL DATA (for predictions)
-- ==========================================
CREATE TABLE IF NOT EXISTS booth_historical_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    booth_name VARCHAR(200) NOT NULL,
    constituency VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    
    election_date DATE NOT NULL,
    
    -- Historical metrics
    avg_queue_length VARCHAR(20),
    avg_wait_time INTEGER,
    peak_hours JSONB, -- ["9AM-11AM", "4PM-6PM"]
    quiet_hours JSONB, -- ["2PM-4PM"]
    
    total_voters INTEGER,
    turnout_percentage DECIMAL(5, 2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- SMART REMINDERS TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS reminders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    firebase_uid VARCHAR(128) NOT NULL,
    
    reminder_type VARCHAR(50) NOT NULL, -- 'registration_deadline', 'document_check', 'election_day', 'booth_verify'
    
    title VARCHAR(200) NOT NULL,
    message TEXT,
    
    -- Scheduling
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'sent', 'dismissed', 'snoozed'
    
    -- Meta
    priority VARCHAR(20) DEFAULT 'medium',
    action_url VARCHAR(500),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reminders_user ON reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_reminders_scheduled ON reminders(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_reminders_status ON reminders(status);

-- ==========================================
-- OFFLINE CACHE TABLE (for election day)
-- ==========================================
CREATE TABLE IF NOT EXISTS offline_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    firebase_uid VARCHAR(128) NOT NULL,
    
    cache_type VARCHAR(50) NOT NULL, -- 'booth_details', 'documents', 'candidates', 'emergency_contacts'
    
    data JSONB NOT NULL,
    
    -- Sync status
    last_synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, cache_type)
);

-- ==========================================
-- DOCUMENT AI VALIDATION RESULTS
-- ==========================================
CREATE TABLE IF NOT EXISTS document_validations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    firebase_uid VARCHAR(128) NOT NULL,
    
    document_type VARCHAR(50) NOT NULL, -- 'aadhaar', 'voter_id', 'passport', 'dl'
    
    -- AI Analysis
    is_valid BOOLEAN,
    confidence_score DECIMAL(3, 2), -- 0.00 to 1.00
    
    -- Issues found
    issues JSONB, -- ['blurry', 'cropped', 'expired', 'wrong_format']
    
    -- Extracted data
    extracted_data JSONB,
    
    -- Suggestions
    suggestions JSONB, -- ['retake_photo', 'use_better_lighting', 'show_full_document']
    
    -- File reference
    file_url VARCHAR(500),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- CANDIDATE COMPARISONS (User saved)
-- ==========================================
CREATE TABLE IF NOT EXISTS user_candidate_comparisons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    firebase_uid VARCHAR(128) NOT NULL,
    
    constituency VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    
    compared_candidates JSONB NOT NULL, -- [candidate_id1, candidate_id2, ...]
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, constituency, state)
);

-- ==========================================
-- TRIGGER FUNCTIONS
-- ==========================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to all tables
CREATE TRIGGER update_candidates_updated_at BEFORE UPDATE ON candidates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_complaints_updated_at BEFORE UPDATE ON complaints
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- VIEWS FOR ANALYTICS
-- ==========================================

-- Active booth status (non-expired)
CREATE OR REPLACE VIEW active_booth_status AS
SELECT * FROM booth_status_reports
WHERE expires_at > NOW()
AND is_verified = TRUE OR verification_count >= 2;

-- Pending complaints summary
CREATE OR REPLACE VIEW complaints_summary AS
SELECT 
    complaint_type,
    status,
    COUNT(*) as count,
    AVG(EXTRACT(EPOCH FROM (COALESCE(resolved_at, NOW()) - created_at))/3600) as avg_resolution_hours
FROM complaints
GROUP BY complaint_type, status;

-- Constituency candidate count
CREATE OR REPLACE VIEW constituency_stats AS
SELECT 
    state,
    constituency,
    COUNT(*) as candidate_count,
    AVG(assets_declared) as avg_assets,
    SUM(criminal_cases) as total_criminal_cases
FROM candidates
GROUP BY state, constituency;

-- ==========================================
-- ELECTION DATES REFERENCE
-- ==========================================
CREATE TABLE IF NOT EXISTS election_dates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    state VARCHAR(50) NOT NULL,
    election_date DATE NOT NULL,
    election_type VARCHAR(50), -- 'general', 'assembly', 'by-election'
    
    -- Phases
    phase INTEGER,
    total_phases INTEGER,
    
    -- Key dates
    notification_date DATE,
    nomination_last_date DATE,
    scrutiny_date DATE,
    withdrawal_last_date DATE,
    
    -- Status
    status VARCHAR(50) DEFAULT 'upcoming', -- 'upcoming', 'ongoing', 'completed'
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(state, election_date)
);

CREATE INDEX IF NOT EXISTS idx_election_dates_state ON election_dates(state);
CREATE INDEX IF NOT EXISTS idx_election_dates_date ON election_dates(election_date);

-- Insert 2024 General Election dates
INSERT INTO election_dates (state, election_date, phase, election_type, status) VALUES
('Andhra Pradesh', '2024-05-13', 1, 'general', 'completed'),
('Arunachal Pradesh', '2024-04-19', 1, 'general', 'completed'),
('Assam', '2024-05-07', 1, 'general', 'completed'),
('Bihar', '2024-05-20', 1, 'general', 'completed'),
('Chhattisgarh', '2024-04-19', 1, 'general', 'completed'),
('Goa', '2024-05-07', 1, 'general', 'completed'),
('Gujarat', '2024-05-07', 1, 'general', 'completed'),
('Haryana', '2024-05-25', 1, 'general', 'completed'),
('Himachal Pradesh', '2024-06-01', 1, 'general', 'completed'),
('Jharkhand', '2024-05-25', 1, 'general', 'completed'),
('Karnataka', '2024-04-26', 1, 'general', 'completed'),
('Kerala', '2024-04-26', 1, 'general', 'completed'),
('Madhya Pradesh', '2024-04-19', 1, 'general', 'completed'),
('Maharashtra', '2024-05-20', 1, 'general', 'completed'),
('Manipur', '2024-04-19', 1, 'general', 'completed'),
('Meghalaya', '2024-04-19', 1, 'general', 'completed'),
('Mizoram', '2024-04-19', 1, 'general', 'completed'),
('Nagaland', '2024-04-19', 1, 'general', 'completed'),
('Odisha', '2024-05-25', 1, 'general', 'completed'),
('Punjab', '2024-06-01', 1, 'general', 'completed'),
('Rajasthan', '2024-04-19', 1, 'general', 'completed'),
('Sikkim', '2024-04-19', 1, 'general', 'completed'),
('Tamil Nadu', '2024-04-19', 1, 'general', 'completed'),
('Telangana', '2024-05-13', 1, 'general', 'completed'),
('Tripura', '2024-04-19', 1, 'general', 'completed'),
('Uttar Pradesh', '2024-05-20', 1, 'general', 'completed'),
('Uttarakhand', '2024-04-19', 1, 'general', 'completed'),
('West Bengal', '2024-05-20', 1, 'general', 'completed'),
('Delhi', '2024-05-25', 1, 'general', 'completed')
ON CONFLICT (state, election_date) DO NOTHING;
