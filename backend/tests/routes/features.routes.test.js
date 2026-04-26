/**
 * Integration tests for /api/features and /api/v2/features routes.
 * All external services are mocked.
 */

jest.mock('../../src/config/postgres', () => ({ query: jest.fn() }));
jest.mock('../../src/config/firebase', () => ({
  auth: jest.fn(() => ({
    verifyIdToken: jest.fn().mockResolvedValue({ uid: 'test-uid' }),
  })),
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({ doc: jest.fn(() => ({ get: jest.fn() })) })),
  })),
  messaging: jest.fn(() => ({ send: jest.fn() })),
}));
jest.mock('../../src/services/bigquery.service', () => ({
  logVoterEvent:        jest.fn().mockResolvedValue(undefined),
  logElectionMetric:    jest.fn().mockResolvedValue(undefined),
  initBigQuery:         jest.fn().mockResolvedValue(undefined),
  isBigQueryConfigured: jest.fn().mockReturnValue(false),
}));
jest.mock('../../src/services/boothCrowdsource.service', () => ({
  reportBoothStatus:    jest.fn().mockResolvedValue({ success: true, reportId: 'r-1' }),
  getBoothStatus:       jest.fn().mockResolvedValue({ boothName: 'Booth 1', queueLength: 5 }),
  getConstituencyBooths: jest.fn().mockResolvedValue({ booths: [] }),
  getBestTimeToVote:    jest.fn().mockResolvedValue({ bestTime: '11:00' }),
  getAlternativeBooths: jest.fn().mockResolvedValue({ alternatives: [] }),
  verifyReport:         jest.fn().mockResolvedValue({ success: true }),
  getReporterLeaderboard: jest.fn().mockResolvedValue([]),
}));
jest.mock('../../src/services/electionTracker.service', () => ({
  getElectionPhasesForUser: jest.fn().mockResolvedValue({ phases: [] }),
  getElectionPhasesByState: jest.fn().mockResolvedValue({ phases: [] }),
  getUpcomingElections:     jest.fn().mockResolvedValue({ elections: [] }),
  getUserCalendar:          jest.fn().mockResolvedValue({ calendar: [] }),
  setReminderPreferences:   jest.fn().mockResolvedValue({ success: true }),
  getSampleBallot:          jest.fn().mockResolvedValue({ candidates: [] }),
  markSampleBallotViewed:   jest.fn().mockResolvedValue({ success: true }),
  getLiveTurnoutForUser:    jest.fn().mockResolvedValue({ currentTurnout: 48.7 }),
  getStateTurnout:          jest.fn().mockResolvedValue({ averageTurnout: 48.1 }),
}));
jest.mock('../../src/services/voterRights.service', () => ({
  getAllGuides:          jest.fn().mockResolvedValue({ guides: [], count: 0 }),
  getGuideByTopic:      jest.fn().mockResolvedValue({ topic: 'rights', title: 'Your Rights' }),
  searchGuides:         jest.fn().mockResolvedValue({ guides: [] }),
  getHelplinesForUser:  jest.fn().mockResolvedValue({ national: [], state: [] }),
  getHelplines:         jest.fn().mockResolvedValue({ national: [], state: [] }),
  getEmergencyContacts: jest.fn().mockResolvedValue({ priority: [] }),
  getAccessibilityInfo: jest.fn().mockResolvedValue({ rights: [] }),
  getVoterRights:       jest.fn().mockResolvedValue({ fundamentalRights: [] }),
  getEmergencyScenarios: jest.fn().mockResolvedValue({ scenarios: [] }),
}));
jest.mock('../../src/services/assistantFaq.service', () => ({
  answerQuestion:    jest.fn().mockResolvedValue({ answer: 'Test answer' }),
  getQuickQuestions: jest.fn().mockReturnValue(['How do I vote?', 'Where is my booth?']),
}));
jest.mock('../../src/services/complaint.service', () => ({
  fileComplaint:             jest.fn().mockResolvedValue({ success: true, referenceId: 'ECI-001' }),
  getUserComplaints:         jest.fn().mockResolvedValue([]),
  getComplaintDetails:       jest.fn().mockResolvedValue({ id: 'c-1' }),
  getQuickComplaintTemplates: jest.fn().mockReturnValue([]),
  getECIContacts:            jest.fn().mockReturnValue({ national: [] }),
  getComplaintStats:         jest.fn().mockResolvedValue([{ total: 0 }]),
}));
jest.mock('../../src/models/user.model', () => ({
  findByFirebaseUid: jest.fn().mockResolvedValue({
    id: 1,
    firebaseUid: 'uid-1',
    state: 'Delhi',
    boothName: 'Booth 42',
    currentState: 'READY_TO_VOTE',
  }),
}));

const request = require('supertest');
const app     = require('../../src/app');
const { query } = require('../../src/config/postgres');

beforeEach(() => jest.clearAllMocks());

// ── Booth crowdsource ────────────────────────────────────────────────────────
describe('POST /api/features/booths/report', () => {
  it('returns 400 when required fields are missing', async () => {
    const res = await request(app)
      .post('/api/features/booths/report')
      .send({});
    expect(res.status).toBe(400);
  });

  it('returns success when valid data provided', async () => {
    const res = await request(app)
      .post('/api/features/booths/report')
      .send({ firebaseUid: 'uid-1', reportData: { queueLength: 10, status: 'open' } });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});

describe('GET /api/features/booths/status', () => {
  it('returns 400 when query params are missing', async () => {
    const res = await request(app).get('/api/features/booths/status');
    expect(res.status).toBe(400);
  });

  it('returns booth status with valid params', async () => {
    const res = await request(app)
      .get('/api/features/booths/status?boothName=Booth+1&constituency=Delhi+East&state=Delhi');
    expect(res.status).toBe(200);
    expect(res.body.boothName).toBe('Booth 1');
  });
});

// ── Election tracker ─────────────────────────────────────────────────────────
describe('GET /api/v2/features/election-tracker/upcoming', () => {
  it('returns upcoming elections list', async () => {
    const res = await request(app).get('/api/v2/features/election-tracker/upcoming');
    expect(res.status).toBe(200);
    expect(res.body.elections).toBeDefined();
  });
});

describe('GET /api/v2/features/election-tracker/phases-by-state/:state', () => {
  it('returns phases for a state', async () => {
    const res = await request(app).get('/api/v2/features/election-tracker/phases-by-state/Delhi');
    expect(res.status).toBe(200);
    expect(res.body.phases).toBeDefined();
  });
});

// ── Voter rights ─────────────────────────────────────────────────────────────
describe('GET /api/v2/features/voter-rights/guides', () => {
  it('returns guides list', async () => {
    const res = await request(app).get('/api/v2/features/voter-rights/guides');
    expect(res.status).toBe(200);
    expect(res.body.guides).toBeDefined();
  });
});

describe('GET /api/v2/features/voter-rights/rights', () => {
  it('returns voter rights info', async () => {
    const res = await request(app).get('/api/v2/features/voter-rights/rights');
    expect(res.status).toBe(200);
    expect(res.body.fundamentalRights).toBeDefined();
  });
});

describe('GET /api/v2/features/voter-rights/emergency-contacts', () => {
  it('returns emergency contacts', async () => {
    const res = await request(app).get('/api/v2/features/voter-rights/emergency-contacts');
    expect(res.status).toBe(200);
    expect(res.body.priority).toBeDefined();
  });
});

// ── AI Assistant FAQ ─────────────────────────────────────────────────────────
describe('POST /api/v2/features/assistant/faq', () => {
  it('returns an answer for a question', async () => {
    const res = await request(app)
      .post('/api/v2/features/assistant/faq')
      .send({ question: 'How do I vote?', userContext: {} });
    expect(res.status).toBe(200);
    expect(res.body.answer).toBeDefined();
  });
});

describe('GET /api/v2/features/assistant/quick-questions', () => {
  it('returns quick questions list', async () => {
    const res = await request(app).get('/api/v2/features/assistant/quick-questions');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.questions)).toBe(true);
  });
});

// ── Complaints ───────────────────────────────────────────────────────────────
describe('POST /api/features/complaints/file', () => {
  it('returns 400 when required fields are missing', async () => {
    const res = await request(app)
      .post('/api/features/complaints/file')
      .send({});
    expect(res.status).toBe(400);
  });

  it('files a complaint successfully', async () => {
    const res = await request(app)
      .post('/api/features/complaints/file')
      .send({ firebaseUid: 'uid-1', complaintData: { type: 'evm_issue', description: 'EVM not working' } });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});

// ── Reminders ────────────────────────────────────────────────────────────────
describe('POST /api/features/reminders/schedule', () => {
  it('returns 404 when user not found', async () => {
    query.mockResolvedValue([]); // no user
    const res = await request(app)
      .post('/api/features/reminders/schedule')
      .send({
        firebaseUid: 'unknown-uid',
        reminderType: 'election_day',
        title: 'Vote Today',
        message: 'Go vote!',
        scheduledAt: new Date(Date.now() + 86400000).toISOString(),
      });
    expect(res.status).toBe(404);
  });

  it('schedules a reminder successfully', async () => {
    query
      .mockResolvedValueOnce([{ id: 1 }]) // user lookup
      .mockResolvedValueOnce([{ id: 10, reminder_type: 'election_day' }]); // insert

    const res = await request(app)
      .post('/api/features/reminders/schedule')
      .send({
        firebaseUid: 'uid-1',
        reminderType: 'election_day',
        title: 'Vote Today',
        message: 'Go vote!',
        scheduledAt: new Date(Date.now() + 86400000).toISOString(),
      });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});
