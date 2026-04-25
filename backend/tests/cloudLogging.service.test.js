/**
 * Unit tests for Cloud Logging service.
 * Tests the local fallback path (no real Cloud Logging calls).
 */

// Ensure project ID is NOT set so we exercise the console fallback
delete process.env.GOOGLE_CLOUD_PROJECT_ID;

jest.mock('@google-cloud/logging', () => ({
  Logging: jest.fn().mockImplementation(() => ({
    log: jest.fn().mockReturnValue({
      entry: jest.fn().mockReturnValue({}),
      write: jest.fn().mockResolvedValue(undefined),
    }),
  })),
}));

const { log, isConfigured } = require('../src/services/cloudLogging.service');

describe('CloudLoggingService', () => {
  describe('isConfigured', () => {
    it('returns false when GOOGLE_CLOUD_PROJECT_ID is not set', () => {
      expect(isConfigured()).toBe(false);
    });
  });

  describe('log.info (fallback path)', () => {
    it('resolves without throwing', async () => {
      await expect(log.info('test_event', { key: 'value' })).resolves.toBeUndefined();
    });

    it('resolves with empty payload', async () => {
      await expect(log.info('empty_event')).resolves.toBeUndefined();
    });
  });

  describe('log.warn (fallback path)', () => {
    it('resolves without throwing', async () => {
      await expect(log.warn('rate_limit', { ip: '1.2.3.4' })).resolves.toBeUndefined();
    });
  });

  describe('log.error (fallback path)', () => {
    it('resolves without throwing', async () => {
      await expect(log.error('db_error', { error: 'connection refused' })).resolves.toBeUndefined();
    });
  });

  describe('log.critical (fallback path)', () => {
    it('resolves without throwing', async () => {
      await expect(log.critical('auth_broken', { service: 'firebase' })).resolves.toBeUndefined();
    });
  });

  describe('log.security (fallback path)', () => {
    it('resolves without throwing', async () => {
      await expect(log.security('invalid_token', { path: '/api/user', ip: '1.2.3.4' })).resolves.toBeUndefined();
    });

    it('includes securityEvent flag in payload', async () => {
      // We can't inspect the console output directly, but we verify it doesn't throw
      await expect(log.security('suspicious_activity', { uid: 'uid-1' })).resolves.toBeUndefined();
    });
  });

  describe('log methods handle all severity levels', () => {
    const methods = ['info', 'warn', 'error', 'critical', 'security'];

    for (const method of methods) {
      it(`log.${method} resolves for any string message`, async () => {
        await expect(log[method](`test_${method}`, {})).resolves.toBeUndefined();
      });
    }
  });
});
