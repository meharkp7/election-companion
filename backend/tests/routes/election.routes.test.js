/**
 * Integration tests for /api/election routes.
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

const request = require('supertest');
const app     = require('../../src/app');
const { query } = require('../../src/config/postgres');

const mockElectionRow = {
  id: 1,
  name: 'Delhi Assembly Election 2024',
  state: 'Delhi',
  election_date: '2024-11-15',
  nomination_deadline: '2024-10-20',
  registration_deadline: '2024-10-10',
  results_date: '2024-11-18',
  is_active: true,
  phases: [],
  created_at: new Date().toISOString(),
};

beforeEach(() => jest.clearAllMocks());

describe('GET /api/election/info', () => {
  it('returns election for a specific state', async () => {
    query.mockResolvedValue([mockElectionRow]);

    const res = await request(app).get('/api/election/info?state=Delhi');
    expect(res.status).toBe(200);
    expect(res.body.election).toBeDefined();
    expect(res.body.election.state).toBe('Delhi');
  });

  it('returns all active elections when no state provided', async () => {
    query.mockResolvedValue([mockElectionRow]);

    const res = await request(app).get('/api/election/info');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.election)).toBe(true);
  });

  it('returns null when no election found for state', async () => {
    query.mockResolvedValue([]);

    const res = await request(app).get('/api/election/info?state=UnknownState');
    expect(res.status).toBe(200);
    expect(res.body.election).toBeNull();
  });

  it('returns empty array when no active elections', async () => {
    query.mockResolvedValue([]);

    const res = await request(app).get('/api/election/info');
    expect(res.status).toBe(200);
    expect(res.body.election).toEqual([]);
  });
});
