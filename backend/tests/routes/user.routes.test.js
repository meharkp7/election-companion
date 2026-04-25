/**
 * Integration tests for /api/user routes
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
  create: jest.fn(),
  update: jest.fn(),
  updateBooth: jest.fn(),
}));
jest.mock('../../src/services/stateMachine.service', () => ({
  calculateReadinessScore: jest.fn().mockReturnValue(40),
  transition: jest.fn(),
}));

const request = require('supertest');
const app = require('../../src/app');
const UserModel = require('../../src/models/user.model');

const mockUser = {
  id: 1,
  firebaseUid: 'uid-1',
  age: 25,
  state: 'Delhi',
  isFirstTimeVoter: false,
  currentState: 'REGISTRATION',
  readinessScore: 60,
};

describe('POST /api/user/onboard', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 400 when firebaseUid is missing', async () => {
    const res = await request(app)
      .post('/api/user/onboard')
      .send({ age: 25, state: 'Delhi' });
    expect(res.status).toBe(400);
  });

  it('returns existing user if already onboarded', async () => {
    UserModel.findByFirebaseUid.mockResolvedValue(mockUser);
    const res = await request(app)
      .post('/api/user/onboard')
      .send({ firebaseUid: 'uid-1', age: 25, state: 'Delhi' });
    expect(res.status).toBe(200);
    expect(res.body.user.firebaseUid).toBe('uid-1');
  });

  it('creates new user and returns 201', async () => {
    UserModel.findByFirebaseUid.mockResolvedValue(null);
    UserModel.create.mockResolvedValue({ ...mockUser, id: 2 });
    UserModel.update.mockResolvedValue({ ...mockUser, id: 2, currentState: 'ELIGIBILITY_CHECK' });

    const res = await request(app)
      .post('/api/user/onboard')
      .send({ firebaseUid: 'uid-new', age: 22, state: 'Mumbai' });
    expect(res.status).toBe(201);
    expect(res.body.message).toBe('User created');
  });

  it('sets START state for underage user', async () => {
    UserModel.findByFirebaseUid.mockResolvedValue(null);
    UserModel.create.mockResolvedValue({ ...mockUser, age: 16 });
    UserModel.update.mockResolvedValue({ ...mockUser, age: 16, currentState: 'START' });

    const res = await request(app)
      .post('/api/user/onboard')
      .send({ firebaseUid: 'uid-minor', age: 16, state: 'Delhi' });
    expect(res.status).toBe(201);
  });
});

describe('GET /api/user/:firebaseUid', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 404 when user not found', async () => {
    UserModel.findByFirebaseUid.mockResolvedValue(null);
    const res = await request(app)
      .get('/api/user/nonexistent')
      .set('Authorization', 'Bearer valid-token');
    expect(res.status).toBe(404);
  });

  it('returns user data when found', async () => {
    UserModel.findByFirebaseUid.mockResolvedValue(mockUser);
    const res = await request(app)
      .get('/api/user/uid-1')
      .set('Authorization', 'Bearer valid-token');
    expect(res.status).toBe(200);
    expect(res.body.user.firebaseUid).toBe('uid-1');
  });
});

describe('PATCH /api/user/:firebaseUid/notifications', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 404 when user not found', async () => {
    UserModel.findByFirebaseUid.mockResolvedValue(null);
    const res = await request(app)
      .patch('/api/user/nonexistent/notifications')
      .set('Authorization', 'Bearer valid-token')
      .send({ enabled: true });
    expect(res.status).toBe(404);
  });

  it('updates notification preference', async () => {
    UserModel.findByFirebaseUid.mockResolvedValue(mockUser);
    UserModel.update.mockResolvedValue({ ...mockUser, notificationsEnabled: true });
    const res = await request(app)
      .patch('/api/user/uid-1/notifications')
      .set('Authorization', 'Bearer valid-token')
      .send({ enabled: true });
    expect(res.status).toBe(200);
  });
});

describe('PATCH /api/user/:firebaseUid/booth', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 404 when user not found', async () => {
    UserModel.updateBooth.mockResolvedValue(null);
    const res = await request(app)
      .patch('/api/user/nonexistent/booth')
      .set('Authorization', 'Bearer valid-token')
      .send({ boothDetails: { boothName: 'Booth 1' } });
    expect(res.status).toBe(404);
  });

  it('updates booth and recalculates readiness score', async () => {
    UserModel.updateBooth.mockResolvedValue({ ...mockUser, boothName: 'Booth 42' });
    UserModel.update.mockResolvedValue({ ...mockUser, boothName: 'Booth 42', readinessScore: 80 });
    const res = await request(app)
      .patch('/api/user/uid-1/booth')
      .set('Authorization', 'Bearer valid-token')
      .send({ boothDetails: { boothName: 'Booth 42' } });
    expect(res.status).toBe(200);
  });
});
