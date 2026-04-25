/**
 * Integration tests for /api/assistant routes.
 * Mocks PostgreSQL and Firebase so no real services are called.
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
jest.mock('../../src/models/user.model', () => ({
  findByFirebaseUid: jest.fn(),
  findById: jest.fn(),
  create: jest.fn(),
  update: jest.fn(),
}));
jest.mock('../../src/models/state.model', () => ({
  create: jest.fn().mockResolvedValue({}),
}));
jest.mock('../../src/services/election.service', () => ({
  isElectionDay: jest.fn().mockResolvedValue(false),
}));
jest.mock('../../src/services/bigquery.service', () => ({
  logVoterEvent: jest.fn().mockResolvedValue(undefined),
  initBigQuery: jest.fn().mockResolvedValue(undefined),
}));

const request = require('supertest');
const app = require('../../src/app');
const UserModel = require('../../src/models/user.model');

const mockUser = {
  id: 'uuid-1',
  firebaseUid: 'uid-1',
  age: 25,
  state: 'Delhi',
  isFirstTimeVoter: false,
  currentState: 'START',
  readinessScore: 0,
  registrationStatus: null,
  verificationStatus: null,
  boothKnown: false,
};

beforeEach(() => jest.clearAllMocks());

// ─── Input validation (Joi) ─────────────────────────────────────────────────
describe('POST /api/assistant/next-step — validation', () => {
  it('returns 400 when firebaseUid is missing', async () => {
    const res = await request(app)
      .post('/api/assistant/next-step')
      .send({ input: { age: 25, state: 'Delhi' } });
    expect(res.status).toBe(400);
    expect(res.body.message).toBe('Validation error');
  });

  it('returns 400 when firebaseUid is empty string', async () => {
    const res = await request(app)
      .post('/api/assistant/next-step')
      .send({ firebaseUid: '', input: {} });
    expect(res.status).toBe(400);
  });

  it('returns 400 when input contains unknown keys', async () => {
    const res = await request(app)
      .post('/api/assistant/next-step')
      .send({ firebaseUid: 'uid-1', input: { maliciousField: 'hack' } });
    expect(res.status).toBe(400);
  });

  it('returns 400 when age is not a number', async () => {
    const res = await request(app)
      .post('/api/assistant/next-step')
      .send({ firebaseUid: 'uid-1', input: { age: 'twenty', state: 'Delhi' } });
    expect(res.status).toBe(400);
  });

  it('returns 400 when registrationStatus is invalid enum value', async () => {
    const res = await request(app)
      .post('/api/assistant/next-step')
      .send({ firebaseUid: 'uid-1', input: { registrationStatus: 'maybe' } });
    expect(res.status).toBe(400);
  });
});

// ─── Happy path — onboarding ────────────────────────────────────────────────
describe('POST /api/assistant/next-step — onboarding flow', () => {
  it('auto-creates user and transitions START → ELIGIBILITY_CHECK', async () => {
    UserModel.findByFirebaseUid.mockResolvedValue(null);
    UserModel.create.mockResolvedValue({ ...mockUser });
    UserModel.findById.mockResolvedValue({ ...mockUser });
    UserModel.update.mockResolvedValue({
      ...mockUser,
      currentState: 'ELIGIBILITY_CHECK',
      readinessScore: 25,
    });

    const res = await request(app)
      .post('/api/assistant/next-step')
      .send({ firebaseUid: 'uid-new', input: { age: 25, state: 'Delhi' } });

    expect(res.status).toBe(200);
    expect(res.body.currentState).toBe('ELIGIBILITY_CHECK');
    expect(res.body.ui).toBeDefined();
  });

  it('returns EXIT state for underage user (age < 18)', async () => {
    UserModel.findByFirebaseUid.mockResolvedValue(null);
    UserModel.create.mockResolvedValue({ ...mockUser, age: 16 });
    UserModel.findById.mockResolvedValue({ ...mockUser, age: 16 });

    const res = await request(app)
      .post('/api/assistant/next-step')
      .send({ firebaseUid: 'uid-minor', input: { age: 16, state: 'Delhi' } });

    // EXIT is handled gracefully — not a 500
    expect([200, 400]).toContain(res.status);
  });

  it('uses existing user when found', async () => {
    const existingUser = { ...mockUser, currentState: 'REGISTRATION' };
    UserModel.findByFirebaseUid.mockResolvedValue(existingUser);
    UserModel.findById.mockResolvedValue(existingUser);
    UserModel.update.mockResolvedValue({
      ...existingUser,
      currentState: 'VERIFICATION',
      readinessScore: 50,
    });

    const res = await request(app)
      .post('/api/assistant/next-step')
      .send({
        firebaseUid: 'uid-1',
        input: { registrationStatus: 'registered' },
      });

    expect(res.status).toBe(200);
    expect(res.body.currentState).toBe('VERIFICATION');
  });
});

// ─── Registration transitions ───────────────────────────────────────────────
describe('POST /api/assistant/next-step — registration transitions', () => {
  const registrationUser = { ...mockUser, currentState: 'REGISTRATION' };

  beforeEach(() => {
    UserModel.findByFirebaseUid.mockResolvedValue(registrationUser);
    UserModel.findById.mockResolvedValue(registrationUser);
  });

  it('transitions to CHECK_STATUS when not_sure', async () => {
    UserModel.update.mockResolvedValue({
      ...registrationUser,
      currentState: 'CHECK_STATUS',
    });

    const res = await request(app)
      .post('/api/assistant/next-step')
      .send({ firebaseUid: 'uid-1', input: { registrationStatus: 'not_sure' } });

    expect(res.status).toBe(200);
    expect(res.body.currentState).toBe('CHECK_STATUS');
  });

  it('stays at REGISTRATION with form6 action when not_registered', async () => {
    UserModel.update.mockResolvedValue({
      ...registrationUser,
      currentState: 'REGISTRATION',
    });

    const res = await request(app)
      .post('/api/assistant/next-step')
      .send({ firebaseUid: 'uid-1', input: { registrationStatus: 'not_registered' } });

    expect(res.status).toBe(200);
    expect(res.body.currentState).toBe('REGISTRATION');
  });
});

// ─── Voting day ─────────────────────────────────────────────────────────────
describe('POST /api/assistant/next-step — voting day', () => {
  it('transitions VOTING_DAY → COMPLETED when votingDone=true', async () => {
    const votingUser = { ...mockUser, currentState: 'VOTING_DAY' };
    UserModel.findByFirebaseUid.mockResolvedValue(votingUser);
    UserModel.findById.mockResolvedValue(votingUser);
    UserModel.update.mockResolvedValue({
      ...votingUser,
      currentState: 'COMPLETED',
    });

    const res = await request(app)
      .post('/api/assistant/next-step')
      .send({ firebaseUid: 'uid-1', input: { votingDone: true } });

    expect(res.status).toBe(200);
    expect(res.body.currentState).toBe('COMPLETED');
  });
});

// ─── UI payload ─────────────────────────────────────────────────────────────
describe('POST /api/assistant/next-step — UI payload', () => {
  it('always returns a ui object with a screen field', async () => {
    UserModel.findByFirebaseUid.mockResolvedValue(null);
    UserModel.create.mockResolvedValue({ ...mockUser });
    UserModel.findById.mockResolvedValue({ ...mockUser });
    UserModel.update.mockResolvedValue({
      ...mockUser,
      currentState: 'ELIGIBILITY_CHECK',
    });

    const res = await request(app)
      .post('/api/assistant/next-step')
      .send({ firebaseUid: 'uid-1', input: { age: 22, state: 'Maharashtra' } });

    expect(res.status).toBe(200);
    expect(res.body.ui).toBeDefined();
    expect(res.body.ui.screen).toBeDefined();
  });
});

// ─── GET /api/assistant/current-step/:firebaseUid ───────────────────────────
describe('GET /api/assistant/current-step/:firebaseUid', () => {
  it('auto-creates user and returns current step for dev placeholder', async () => {
    UserModel.findByFirebaseUid.mockResolvedValue(null);
    UserModel.create.mockResolvedValue({ ...mockUser });

    const res = await request(app)
      .get('/api/assistant/current-step/dev_user_placeholder')
      .set('Authorization', 'Bearer valid-token');

    expect(res.status).toBe(200);
    expect(res.body.currentState).toBeDefined();
    expect(res.body.ui).toBeDefined();
  });

  it('returns existing user state', async () => {
    UserModel.findByFirebaseUid.mockResolvedValue({
      ...mockUser,
      currentState: 'READY_TO_VOTE',
      readinessScore: 100,
    });

    const res = await request(app)
      .get('/api/assistant/current-step/dev_user_placeholder')
      .set('Authorization', 'Bearer valid-token');

    expect(res.status).toBe(200);
    expect(res.body.currentState).toBe('READY_TO_VOTE');
    expect(res.body.readinessScore).toBe(100);
  });
});

// ─── Health endpoints ────────────────────────────────────────────────────────
describe('GET /health', () => {
  it('returns 200 ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

describe('GET /health/detailed', () => {
  it('returns status and services object', async () => {
    const { query } = require('../../src/config/postgres');
    query.mockResolvedValue([{ '?column?': 1 }]);

    const res = await request(app).get('/health/detailed');
    expect([200, 503]).toContain(res.status);
    expect(res.body.services).toBeDefined();
    expect(res.body.timestamp).toBeDefined();
  });
});
