-- VoteReady PostgreSQL Schema
-- Run: psql -U postgres -d voteready -f schema.sql

-- ─── Extensions ────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── Users table ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_uid          VARCHAR(128) UNIQUE NOT NULL,
  phone                 VARCHAR(20),
  age                   INTEGER,
  state                 VARCHAR(100),
  is_first_time_voter   BOOLEAN DEFAULT FALSE,

  -- State machine
  current_state         VARCHAR(50) NOT NULL DEFAULT 'START',
  registration_status   VARCHAR(30) DEFAULT 'not_sure',
  verification_status   VARCHAR(30) DEFAULT 'not_verified',

  -- Booth
  booth_known           BOOLEAN DEFAULT FALSE,
  booth_name            VARCHAR(255),
  booth_address         TEXT,
  booth_lat             NUMERIC(10, 7),
  booth_lng             NUMERIC(10, 7),

  -- Scoring & preferences
  readiness_score       INTEGER DEFAULT 0,
  notifications_enabled BOOLEAN DEFAULT FALSE,
  issue_type            VARCHAR(50),

  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_current_state ON users(current_state);
CREATE INDEX IF NOT EXISTS idx_users_notifications ON users(notifications_enabled) WHERE notifications_enabled = TRUE;

-- ─── State logs table ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS state_logs (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  from_state  VARCHAR(50),
  to_state    VARCHAR(50) NOT NULL,
  trigger     VARCHAR(100) DEFAULT 'user_action',
  meta        JSONB DEFAULT '{}',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_state_logs_user_id ON state_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_state_logs_created_at ON state_logs(created_at DESC);

-- ─── Elections table ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS elections (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name                    VARCHAR(255) NOT NULL,
  state                   VARCHAR(100),
  election_date           DATE,
  nomination_deadline     DATE,
  registration_deadline   DATE,
  results_date            DATE,
  is_active               BOOLEAN DEFAULT TRUE,
  phases                  JSONB DEFAULT '[]',
  created_at              TIMESTAMPTZ DEFAULT NOW(),
  updated_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_elections_state ON elections(state);
CREATE INDEX IF NOT EXISTS idx_elections_active ON elections(is_active) WHERE is_active = TRUE;

-- ─── Auto-update updated_at trigger ────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_elections_updated_at
  BEFORE UPDATE ON elections
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ─── Seed: sample Delhi election ────────────────────────────────────────────
INSERT INTO elections (name, state, election_date, registration_deadline, results_date, is_active)
VALUES (
  'Delhi Legislative Assembly Election 2025',
  'Delhi',
  '2025-02-05',
  '2025-01-10',
  '2025-02-08',
  TRUE
) ON CONFLICT DO NOTHING;