-- PostgreSQL Schema for VoteReady - Government-Grade Voter Verification System
-- Run this to set up your database: psql -d voteready -f src/config/schema.sql

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- CORE USER TABLE (Enhanced for Government App)
-- ==========================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid VARCHAR(128) UNIQUE NOT NULL,
    
    -- Basic info
    phone VARCHAR(15),
    age INTEGER CHECK (age >= 0 AND age <= 120),
    state VARCHAR(50),
    is_first_time_voter BOOLEAN DEFAULT FALSE,
    
    -- State machine tracking
    current_state VARCHAR(50) DEFAULT 'START',
    previous_state VARCHAR(50),
    
    -- Registration tracking
    registration_status VARCHAR(50), -- 'registered', 'not_registered', 'not_sure'
    voter_id_number VARCHAR(20), -- EPIC number if available
    
    -- Verification tracking (GOVERNMENT-GRADE)
    verification_status VARCHAR(50) DEFAULT 'unverified', -- 'unverified', 'pending', 'verified', 'rejected'
    verification_level INTEGER DEFAULT 0, -- 0=none, 1=basic, 2=advanced, 3=govt
    
    -- Booth information
    booth_known BOOLEAN DEFAULT FALSE,
    booth_name VARCHAR(200),
    booth_address TEXT,
    booth_lat DECIMAL(10, 8),
    booth_lng DECIMAL(11, 8),
    
    -- Readiness & engagement
    readiness_score INTEGER DEFAULT 0 CHECK (readiness_score >= 0 AND readiness_score <= 100),
    notifications_enabled BOOLEAN DEFAULT TRUE,
    
    -- Issue tracking
    issue_type VARCHAR(50),
    issue_description TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    verified_at TIMESTAMP WITH TIME ZONE,
    last_login_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_current_state ON users(current_state);
CREATE INDEX IF NOT EXISTS idx_users_verification_status ON users(verification_status);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- ==========================================
-- VERIFICATION DOCUMENTS (Government-Grade)
-- ==========================================
CREATE TABLE IF NOT EXISTS verification_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Document type
    document_type VARCHAR(50) NOT NULL, -- 'aadhaar', 'voter_id', 'passport', 'driving_license', 'pan_card'
    document_number VARCHAR(50),
    
    -- Document images (stored in Firebase Storage, URL here)
    front_image_url TEXT,
    back_image_url TEXT,
    selfie_image_url TEXT, -- For face matching
    
    -- OCR extracted data
    ocr_raw_data JSONB,
    ocr_confidence DECIMAL(5,4), -- 0.0000 to 1.0000
    
    -- Verification results
    verification_method VARCHAR(50), -- 'manual', 'ocr', 'api', 'ai'
    verification_result VARCHAR(50), -- 'pending', 'approved', 'rejected', 'flagged'
    verification_score DECIMAL(5,4), -- confidence score
    
    -- Rejection/flagging reason
    rejection_reason TEXT,
    flagged_reason TEXT,
    
    -- Manual review
    reviewed_by VARCHAR(100),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    review_notes TEXT,
    
    -- API verification data (if using government APIs)
    api_verification_data JSONB,
    api_verified_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_verification_docs_user_id ON verification_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_docs_type ON verification_documents(document_type);
CREATE INDEX IF NOT EXISTS idx_verification_docs_status ON verification_documents(verification_result);

-- ==========================================
-- AADHAAR VERIFICATION (Specific Table for E-KYC)
-- ==========================================
CREATE TABLE IF NOT EXISTS aadhaar_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Aadhaar data (masked for privacy)
    aadhaar_number_masked VARCHAR(14), -- XXXX-XXXX-1234 format
    aadhaar_hash VARCHAR(64), -- SHA-256 hash for comparison
    
    -- e-KYC data from UIDAI
    ekyc_reference_id VARCHAR(50),
    ekyc_status VARCHAR(50), -- 'pending', 'success', 'failed', 'otp_required'
    
    -- Demographic data (received from UIDAI)
    demographic_data JSONB, -- name, address, photo, DOB, gender
    
    -- OTP verification
    otp_transaction_id VARCHAR(100),
    otp_verified BOOLEAN DEFAULT FALSE,
    otp_verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Biometric (if enabled)
    biometric_reference VARCHAR(100),
    
    -- Consent tracking
    consent_given BOOLEAN DEFAULT FALSE,
    consent_given_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_aadhaar_user_id ON aadhaar_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_aadhaar_ekyc_status ON aadhaar_verifications(ekyc_status);

-- ==========================================
-- VOTER ID (EPIC) VERIFICATION
-- ==========================================
CREATE TABLE IF NOT EXISTS voter_id_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- EPIC details
    epic_number VARCHAR(20) NOT NULL,
    epic_number_normalized VARCHAR(20), -- uppercase, no spaces
    
    -- ECI verification
    eci_reference VARCHAR(100),
    eci_verification_status VARCHAR(50), -- 'pending', 'verified', 'not_found', 'mismatch'
    
    -- Voter details from ECI
    voter_name TEXT,
    voter_name_verified BOOLEAN DEFAULT FALSE,
    
    father_husband_name TEXT,
    father_husband_name_verified BOOLEAN DEFAULT FALSE,
    
    age INTEGER,
    age_verified BOOLEAN DEFAULT FALSE,
    
    gender VARCHAR(10),
    gender_verified BOOLEAN DEFAULT FALSE,
    
    -- Address verification
    house_number TEXT,
    street TEXT,
    area TEXT,
    district TEXT,
    state VARCHAR(50),
    pincode VARCHAR(10),
    address_verified BOOLEAN DEFAULT FALSE,
    
    -- Booth details
    polling_station_name TEXT,
    polling_station_number VARCHAR(20),
    
    -- Parliamentary/Assembly constituency
    pc_name TEXT, -- Parliamentary Constituency
    pc_number VARCHAR(10),
    ac_name TEXT, -- Assembly Constituency
    ac_number VARCHAR(10),
    
    -- Verification tracking
    verified_at TIMESTAMP WITH TIME ZONE,
    verification_method VARCHAR(50), -- 'eci_api', 'manual', 'document_upload'
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_voter_id_user_id ON voter_id_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_voter_id_epic ON voter_id_verifications(epic_number_normalized);
CREATE INDEX IF NOT EXISTS idx_voter_id_eci_status ON voter_id_verifications(eci_verification_status);

-- ==========================================
-- STATE MACHINE LOG (Audit Trail)
-- ==========================================
CREATE TABLE IF NOT EXISTS state_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    from_state VARCHAR(50) NOT NULL,
    to_state VARCHAR(50) NOT NULL,
    trigger_action VARCHAR(100), -- what caused the transition
    input_data JSONB, -- the input that triggered the transition
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_state_logs_user_id ON state_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_state_logs_created_at ON state_logs(created_at);

-- ==========================================
-- AUDIT LOG (Security & Compliance)
-- ==========================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    firebase_uid VARCHAR(128),
    
    action VARCHAR(100) NOT NULL, -- 'login', 'document_upload', 'verification_attempt', etc.
    resource VARCHAR(100), -- what was acted upon
    resource_id UUID,
    
    -- Request details
    ip_address INET,
    user_agent TEXT,
    device_id VARCHAR(100),
    
    -- Action details
    request_data JSONB,
    response_data JSONB,
    success BOOLEAN,
    
    -- Risk assessment
    risk_score INTEGER, -- 0-100
    risk_factors JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

-- ==========================================
-- TRIGGER: Update timestamps automatically
-- ==========================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables with updated_at
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_verification_docs_updated_at ON verification_documents;
CREATE TRIGGER update_verification_docs_updated_at
    BEFORE UPDATE ON verification_documents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_aadhaar_updated_at ON aadhaar_verifications;
CREATE TRIGGER update_aadhaar_updated_at
    BEFORE UPDATE ON aadhaar_verifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_voter_id_updated_at ON voter_id_verifications;
CREATE TRIGGER update_voter_id_updated_at
    BEFORE UPDATE ON voter_id_verifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- DIGILOCKER INTEGRATION TABLES
-- ==========================================

-- DigiLocker OAuth sessions
CREATE TABLE IF NOT EXISTS digilocker_auth_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code_verifier VARCHAR(255),
    state VARCHAR(255),
    access_token TEXT,
    refresh_token TEXT,
    expires_at TIMESTAMP,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id)
);

-- DigiLocker documents cache
CREATE TABLE IF NOT EXISTS digilocker_documents (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL, -- 'aadhaar', 'voter_id', 'pan', etc.
    digilocker_doc_id VARCHAR(255),
    doc_name VARCHAR(255),
    uri TEXT,
    fetched_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, document_type)
);

-- Add DigiLocker columns to users table
ALTER TABLE users 
    ADD COLUMN IF NOT EXISTS digilocker_linked BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS digilocker_linked_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS digilocker_unlinked_at TIMESTAMP;

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_digilocker_sessions_user_id ON digilocker_auth_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_digilocker_docs_user_id ON digilocker_documents(user_id);

-- Trigger for updated_at on digilocker tables
DROP TRIGGER IF EXISTS update_digilocker_sessions_updated_at ON digilocker_auth_sessions;
CREATE TRIGGER update_digilocker_sessions_updated_at
    BEFORE UPDATE ON digilocker_auth_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- VIEWS FOR ANALYTICS
-- ==========================================

-- User verification summary view
CREATE OR REPLACE VIEW user_verification_summary AS
SELECT 
    u.id,
    u.firebase_uid,
    u.current_state,
    u.verification_status,
    u.verification_level,
    COUNT(DISTINCT vd.id) as total_documents_uploaded,
    COUNT(DISTINCT CASE WHEN vd.verification_result = 'approved' THEN vd.id END) as approved_documents,
    av.ekyc_status as aadhaar_ekyc_status,
    viv.eci_verification_status as voter_id_status,
    u.digilocker_linked,
    (SELECT COUNT(*) FROM digilocker_documents dd WHERE dd.user_id = u.id) as digilocker_docs_count,
    u.readiness_score,
    u.created_at
FROM users u
LEFT JOIN verification_documents vd ON vd.user_id = u.id
LEFT JOIN aadhaar_verifications av ON av.user_id = u.id
LEFT JOIN voter_id_verifications viv ON viv.user_id = u.id
GROUP BY u.id, av.ekyc_status, viv.eci_verification_status;

-- Verification statistics view
CREATE OR REPLACE VIEW verification_stats AS
SELECT 
    DATE_TRUNC('day', created_at) as date,
    COUNT(*) as total_attempts,
    COUNT(CASE WHEN verification_result = 'approved' THEN 1 END) as approved,
    COUNT(CASE WHEN verification_result = 'rejected' THEN 1 END) as rejected,
    COUNT(CASE WHEN verification_result = 'flagged' THEN 1 END) as flagged,
    AVG(verification_score) as avg_confidence_score
FROM verification_documents
GROUP BY DATE_TRUNC('day', created_at)
ORDER BY date DESC;

-- ==========================================
-- SEED DATA (For Development)
-- ==========================================
-- Insert a test user if none exists
INSERT INTO users (firebase_uid, phone, current_state, verification_status, created_at)
SELECT 'test_user_123', '+911234567890', 'START', 'unverified', NOW()
WHERE NOT EXISTS (SELECT 1 FROM users WHERE firebase_uid = 'test_user_123');
