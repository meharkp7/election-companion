/**
 * Integration tests for /api/verification routes
 * Uses supertest to test the full Express middleware stack.
 */

jest.mock('../../src/config/postgres', () => ({ query: jest.fn() }));
jest.mock('../../src/config/firebase', () => ({
  auth: jest.fn(() => ({ verifyIdToken: jest.fn().mockResolvedValue({ uid: 'test-uid' }) })),
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({ doc: jest.fn(() => ({ get: jest.fn() })) })),
  })),
  messaging: jest.fn(() => ({ send: jest.fn() })),
}));
jest.mock('../../src/services/verification.service', () => ({
  processDocumentUpload: jest.fn(),
  initiateAadhaarEKYC: jest.fn(),
  verifyAadhaarOTP: jest.fn(),
  verifyVoterID: jest.fn(),
}));
jest.mock('../../src/middleware/audit.middleware', () => ({
  logAudit: jest.fn().mockResolvedValue(undefined),
  auditMiddleware: (req, res, next) => next(),
}));

const request = require('supertest');
const app = require('../../src/app');
const verificationService = require('../../src/services/verification.service');
const { query } = require('../../src/config/postgres');

describe('POST /api/verification/document', () => {
  it('returns 400 when required fields are missing', async () => {
    const res = await request(app)
      .post('/api/verification/document')
      .send({ userId: 'u1' }); // missing documentType and imageUrls
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('returns 200 with result on success', async () => {
    verificationService.processDocumentUpload.mockResolvedValue({
      documentId: 'doc-1',
      confidence: 0.95,
    });
    const res = await request(app)
      .post('/api/verification/document')
      .send({
        userId: 'u1',
        documentType: 'aadhaar',
        imageUrls: { front: 'https://example.com/doc.jpg' },
      });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.documentId).toBe('doc-1');
  });

  it('returns 500 when service throws', async () => {
    verificationService.processDocumentUpload.mockRejectedValue(
      new Error('Storage unavailable'),
    );
    const res = await request(app)
      .post('/api/verification/document')
      .send({
        userId: 'u1',
        documentType: 'aadhaar',
        imageUrls: { front: 'https://example.com/doc.jpg' },
      });
    expect(res.status).toBe(500);
  });
});

describe('POST /api/verification/aadhaar/initiate', () => {
  it('returns 400 for missing fields', async () => {
    const res = await request(app)
      .post('/api/verification/aadhaar/initiate')
      .send({ userId: 'u1' });
    expect(res.status).toBe(400);
  });

  it('returns 400 for invalid Aadhaar format', async () => {
    const res = await request(app)
      .post('/api/verification/aadhaar/initiate')
      .send({ userId: 'u1', aadhaarNumber: '12345' }); // too short
    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/Invalid Aadhaar/);
  });

  it('returns 200 for valid 12-digit Aadhaar', async () => {
    verificationService.initiateAadhaarEKYC.mockResolvedValue({
      maskedAadhaar: 'XXXX-XXXX-9012',
      otpSent: true,
    });
    const res = await request(app)
      .post('/api/verification/aadhaar/initiate')
      .send({ userId: 'u1', aadhaarNumber: '123456789012' });
    expect(res.status).toBe(200);
    expect(res.body.data.otpSent).toBe(true);
  });

  it('accepts Aadhaar with spaces', async () => {
    verificationService.initiateAadhaarEKYC.mockResolvedValue({
      maskedAadhaar: 'XXXX-XXXX-9012',
      otpSent: true,
    });
    const res = await request(app)
      .post('/api/verification/aadhaar/initiate')
      .send({ userId: 'u1', aadhaarNumber: '1234 5678 9012' });
    expect(res.status).toBe(200);
  });
});

describe('POST /api/verification/aadhaar/verify-otp', () => {
  it('returns 400 when otp is missing', async () => {
    const res = await request(app)
      .post('/api/verification/aadhaar/verify-otp')
      .send({ userId: 'u1' });
    expect(res.status).toBe(400);
  });

  it('returns 200 on successful OTP verification', async () => {
    verificationService.verifyAadhaarOTP.mockResolvedValue({
      success: true,
      verificationLevel: 3,
    });
    const res = await request(app)
      .post('/api/verification/aadhaar/verify-otp')
      .send({ userId: 'u1', otp: '123456' });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});

describe('POST /api/verification/voter-id', () => {
  it('returns 400 when state is missing', async () => {
    const res = await request(app)
      .post('/api/verification/voter-id')
      .send({ userId: 'u1', epicNumber: 'ABC1234567' });
    expect(res.status).toBe(400);
  });

  it('returns 200 on valid voter ID verification', async () => {
    verificationService.verifyVoterID.mockResolvedValue({
      success: true,
      boothDetails: { boothName: 'Booth 42' },
    });
    const res = await request(app)
      .post('/api/verification/voter-id')
      .send({ userId: 'u1', epicNumber: 'ABC1234567', state: 'Delhi' });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});

describe('GET /api/verification/status/:userId', () => {
  it('returns 404 when user not found', async () => {
    query.mockResolvedValue([]);
    const res = await request(app).get('/api/verification/status/999');
    expect(res.status).toBe(404);
  });

  it('returns 200 with status data when user exists', async () => {
    query.mockResolvedValue([{
      verification_status: 'verified',
      verification_level: 3,
      verified_at: new Date().toISOString(),
      documents_uploaded: 2,
      aadhaar_status: 'completed',
      voter_id_status: 'verified',
    }]);
    const res = await request(app).get('/api/verification/status/1');
    expect(res.status).toBe(200);
    expect(res.body.data.verification_level).toBe(3);
  });
});

describe('GET /health', () => {
  it('returns ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});
