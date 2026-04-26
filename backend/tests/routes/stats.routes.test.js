/**
 * Integration tests for /api/stats routes.
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
  countByState:   jest.fn(),
  readinessStats: jest.fn(),
}));
jest.mock('../../src/services/bigquery.service', () => ({
  queryTurnoutStats: jest.fn(),
  logVoterEvent:     jest.fn().mockResolvedValue(undefined),
  logElectionMetric: jest.fn().mockResolvedValue(undefined),
  initBigQuery:      jest.fn().mockResolvedValue(undefined),
  isBigQueryConfigured: jest.fn().mockReturnValue(false),
}));

const request   = require('supertest');
const app       = require('../../src/app');
const UserModel = require('../../src/models/user.model');
const { queryTurnoutStats } = require('../../src/services/bigquery.service');
const cache     = require('../../src/services/cache.service');

beforeEach(() => {
  jest.clearAllMocks();
  cache.flush(); // ensure no stale cache between tests
});

// ── GET /api/stats ───────────────────────────────────────────────────────────
describe('GET /api/stats', () => {
  const mockStateRows = [
    { state: 'COMPLETED', count: 50 },
    { state: 'POST_VOTING_EXPLORE', count: 10 },
    { state: 'REGISTRATION', count: 40 },
  ];
  const mockReadiness = { avg: '72.5', max: 100, total: '100' };

  beforeEach(() => {
    UserModel.countByState.mockResolvedValue(mockStateRows);
    UserModel.readinessStats.mockResolvedValue(mockReadiness);
  });

  it('returns 200 with stats object', async () => {
    const res = await request(app)
      .get('/api/stats')
      .set('Authorization', 'Bearer valid-token');

    expect(res.status).toBe(200);
    expect(res.body.stats).toBeDefined();
    expect(res.body.stats.totalUsers).toBe(100);
    expect(res.body.stats.votedUsers).toBe(60);
    expect(res.body.stats.turnoutPercent).toBe('60.0');
  });

  it('returns readiness stats', async () => {
    const res = await request(app)
      .get('/api/stats')
      .set('Authorization', 'Bearer valid-token');

    expect(res.body.stats.readiness).toBeDefined();
    expect(res.body.stats.readiness.avg).toBe(72.5);
  });

  it('handles zero users gracefully', async () => {
    UserModel.countByState.mockResolvedValue([]);
    UserModel.readinessStats.mockResolvedValue({ avg: null, max: null, total: '0' });

    const res = await request(app)
      .get('/api/stats')
      .set('Authorization', 'Bearer valid-token');

    expect(res.status).toBe(200);
    expect(res.body.stats.totalUsers).toBe(0);
    expect(res.body.stats.turnoutPercent).toBe('0.0');
  });

  it('returns 401 without auth token', async () => {
    const res = await request(app).get('/api/stats');
    expect(res.status).toBe(401);
  });
});

// ── GET /api/stats/turnout ───────────────────────────────────────────────────
describe('GET /api/stats/turnout', () => {
  it('returns BigQuery turnout data', async () => {
    queryTurnoutStats.mockResolvedValue({
      data: [{ state: 'Delhi', unique_voters: 1000, voted_count: 650, turnout_pct: 65.0 }],
    });

    const res = await request(app)
      .get('/api/stats/turnout')
      .set('Authorization', 'Bearer valid-token');

    expect(res.status).toBe(200);
    expect(res.body.data).toBeDefined();
  });

  it('returns note when BigQuery not configured', async () => {
    queryTurnoutStats.mockResolvedValue({ note: 'BigQuery not configured', data: [] });

    const res = await request(app)
      .get('/api/stats/turnout')
      .set('Authorization', 'Bearer valid-token');

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual([]);
  });
});

// ── GET /api/stats/cache ─────────────────────────────────────────────────────
describe('GET /api/stats/cache', () => {
  it('returns cache health metrics without auth', async () => {
    const res = await request(app).get('/api/stats/cache');
    expect(res.status).toBe(200);
    expect(res.body.cache).toBeDefined();
    expect(res.body.cache).toHaveProperty('size');
    expect(res.body.cache).toHaveProperty('hitRate');
  });
});
