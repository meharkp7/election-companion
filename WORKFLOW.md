# VoteReady - Smooth Workflow & Verification System

## Overview
A government-grade voter assistance application with secure identity verification using Aadhaar E-KYC and Voter ID (EPIC) validation.

## Technology Stack (All Google Cloud)
- **Frontend:** Flutter + Firebase Auth
- **Backend:** Node.js + Express
- **Database:** PostgreSQL (Cloud SQL)
- **AI:** Vertex AI (Gemini)
- **Storage:** Firebase Storage
- **Auth:** Firebase Authentication

## Verification Levels

| Level | Name | Requirements | Use Case |
|-------|------|--------------|----------|
| 0 | None | None | Basic browsing |
| 1 | Basic | Phone verified | Notifications |
| 2 | Document | ID uploaded + OCR | Profile completion |
| 3 | Government | Aadhaar E-KYC OR Voter ID verified | Full access |

## User Workflow

### 1. Entry (START)
```
User opens app
    ↓
Firebase Phone Auth (OTP)
    ↓
Collect: Age, State, First-time voter status
    ↓
[Decision Point]
    ├── Age < 18 → EXIT (Not eligible)
    └── Age ≥ 18 → ELIGIBILITY_CHECK
```

### 2. Eligibility Check (ELIGIBILITY_CHECK)
```
Display eligibility confirmation
    ↓
User confirms → REGISTRATION
```

### 3. Registration Status (REGISTRATION)
```
Ask: Are you registered?
    ├── "Yes" → VERIFICATION (with Voter ID)
    ├── "No" → Show Form 6 guide → Document Upload
    └── "Not Sure" → CHECK_STATUS
```

### 4. Check Status (CHECK_STATUS)
```
Guide to check voter list
    ↓
[External: voters.eci.gov.in]
    ↓
[Decision Point]
    ├── Name Found → VERIFICATION
    └── Name Not Found → REGISTRATION (Form 6)
```

### 5. Verification (VERIFICATION) - **GOVERNMENT-GRADE**
This is the critical security step for government apps.

#### Option A: Aadhaar E-KYC (Recommended)
```
User selects "Verify with Aadhaar"
    ↓
Enter 12-digit Aadhaar Number
    ↓
Backend: Initiate E-KYC with UIDAI
    ↓
User receives OTP on registered mobile
    ↓
Enter OTP
    ↓
Backend: Verify OTP with UIDAI
    ↓
[Success] → Receive demographic data
    ↓
Update user profile with verified data
    ↓
→ READY_TO_VOTE (if booth known)
```

#### Option B: Voter ID (EPIC) Verification
```
User selects "Verify with Voter ID"
    ↓
Enter EPIC Number (from voter card)
    ↓
Select State
    ↓
Upload Voter ID front image
    ↓
Vertex AI OCR extracts:
    - Name, Age, Gender
    - Address
    - Polling Station
    - Constituency details
    ↓
Backend: Verify against ECI database
    ↓
[Success] → Booth automatically identified
    ↓
→ READY_TO_VOTE
```

#### Option C: Document Upload (Basic)
```
User selects "Upload Documents"
    ↓
Upload any Govt ID (Aadhaar/DL/Passport/PAN)
    ↓
Vertex AI OCR + Face Match
    ↓
Manual review queue (if needed)
    ↓
→ VERIFICATION (pending approval)
```

### 6. Issue Resolution (ISSUE_RESOLVER)
```
If verification reveals issues:
    ├── Missing name → Form 6 (New registration)
    ├── Wrong details → Form 8 (Correction)
    ├── Booth issue → Contact BLO
    └── Transfer → Form 8A (Transposition)
```

### 7. Ready to Vote (READY_TO_VOTE)
```
All verification complete
    ↓
Readiness Score = 100%
    ↓
Display:
    - Polling station details
    - Voting date countdown
    - Required documents checklist
    - Location map
    ↓
Enable Election Mode (on voting day)
```

### 8. Voting Day (VOTING_DAY)
```
Election day activated
    ↓
Quick access:
    - Polling station location
    - Queue status (if available)
    - Document reminder
    - Mark as Voted
```

### 9. Completed (COMPLETED)
```
User marked as voted
    ↓
→ POST_VOTING_EXPLORE
    - Stats
    - Share "I Voted"
    - Invite friends
```

## API Endpoints

### Verification API
```
POST /api/verification/document
  → Upload & OCR government ID

POST /api/verification/aadhaar/initiate
  → Start Aadhaar E-KYC (sends OTP)

POST /api/verification/aadhaar/verify-otp
  → Complete Aadhaar verification

POST /api/verification/voter-id
  → Verify EPIC number with ECI

GET /api/verification/status/:userId
  → Check verification status
```

### Assistant API (State Machine)
```
POST /api/assistant/next-step
  → Advance user through workflow

GET /api/assistant/current-step/:userId
  → Get current state & UI
```

## Database Schema

### Core Tables
- `users` - User profiles with verification status
- `verification_documents` - Document uploads & OCR results
- `aadhaar_verifications` - E-KYC data from UIDAI
- `voter_id_verifications` - ECI verification data
- `state_logs` - State machine audit trail
- `audit_logs` - Security & compliance logging

### Views
- `user_verification_summary` - Quick verification status lookup
- `verification_stats` - Analytics dashboard

## Security Features

1. **Data Privacy**
   - Aadhaar numbers hashed (SHA-256)
   - Only masked Aadhaar stored (XXXX-XXXX-1234)
   - Documents stored in Firebase Storage with restricted access

2. **Audit Trail**
   - Every verification attempt logged
   - IP address, device ID tracked
   - Risk scoring for suspicious activity

3. **Rate Limiting**
   - 100 requests per 15 minutes per IP
   - 5 OTP attempts per session

4. **Encryption**
   - All API traffic over HTTPS
   - Database connections encrypted
   - Sensitive fields encrypted at rest

## Setup Instructions

### 1. Database Setup
```bash
cd backend
# Install PostgreSQL locally or use Cloud SQL
brew install postgresql
brew services start postgresql

# Create database
createdb voteready

# Initialize schema
node scripts/init-db.js
```

### 2. Firebase Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
google auth application-default login

# Configure Firebase in .env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY=...
```

### 3. Vertex AI Setup
```bash
# Enable Vertex AI API
gcloud services enable aiplatform.googleapis.com

# Set project
gcloud config set project YOUR_PROJECT_ID

# Configure in .env
GOOGLE_CLOUD_PROJECT_ID=your-project-id
GOOGLE_CLOUD_LOCATION=us-central1
```

### 4. Run Backend
```bash
cd backend
npm install
npm start
# Server runs on http://localhost:5001
```

### 5. Run Flutter App
```bash
cd frontend/app
flutter pub get
flutter run
```

## Production Checklist

- [ ] Replace mock UIDAI integration with real API
- [ ] Replace mock ECI API with real electoral roll API
- [ ] Enable Firebase App Check
- [ ] Set up Cloud SQL (PostgreSQL)
- [ ] Configure Firebase Storage security rules
- [ ] Enable Cloud Armor for DDoS protection
- [ ] Set up Firebase Analytics
- [ ] Configure error monitoring (Crashlytics/Sentry)
- [ ] SSL certificates for custom domain
- [ ] Privacy policy and terms of service
- [ ] Data retention policy
- [ ] GDPR compliance (if applicable)

## Monitoring & Analytics

### Key Metrics
- Verification success rate
- Time to complete verification
- Drop-off points in workflow
- AI OCR accuracy
- API response times

### Alerts
- Failed verification spikes
- Suspicious activity patterns
- Database connection issues
- API rate limiting triggers

---

**Note:** This is a development setup. For production government deployment:
1. Integrate with actual UIDAI E-KYC API
2. Integrate with actual ECI electoral search API
3. Complete security audit
4. Obtain necessary government approvals
