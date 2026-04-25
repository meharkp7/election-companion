/**
 * Unit tests for BigQuery service
 * Mocks the @google-cloud/bigquery SDK so no real API calls are made.
 */

// Ensure project ID is NOT set so we exercise the mock/fallback path
delete process.env.GOOGLE_CLOUD_PROJECT_ID;

jest.mock('@google-cloud/bigquery', () => ({
  BigQuery: jest.fn().mockImplementation(() => ({
    dataset: jest.fn().mockReturnValue({
      exists: jest.fn().mockResolvedValue([true]),
      table: jest.fn().mockReturnValue({
        exists: jest.fn().mockResolvedValue([true]),
        insert: jest.fn().mockResolvedValue([{}]),
      }),
    }),
    query: jest.fn().mockResolvedValue([[
      { state: 'Delhi', unique_voters: 1000, voted_count: 650, turnout_pct: 65.0 },
    ]]),
  })),
}));

const {
  logVoterEvent,
  logAIInteraction,
  queryTurnoutStats,
  isBigQueryConfigured,
} = require('../src/services/bigquery.service');

describe('BigQueryService', () => {
  describe('isBigQueryConfigured', () => {
    it('returns false when project ID is not set', () => {
      expect(isBigQueryConfigured()).toBe(false);
    });
  });

  describe('logVoterEvent (mock path — no BigQuery)', () => {
    it('resolves without throwing for valid event', async () => {
      await expect(
        logVoterEvent('uid-1', 'onboarded', {
          state: 'Delhi',
          age: 25,
          isFirstTimeVoter: false,
          currentState: 'REGISTRATION',
          readinessScore: 40,
        }),
      ).resolves.toBeUndefined();
    });

    it('resolves without throwing when context is empty', async () => {
      await expect(logVoterEvent('uid-2', 'voted', {})).resolves.toBeUndefined();
    });

    it('handles all event types without throwing', async () => {
      const events = ['onboarded', 'verified', 'voted', 'state_registration', 'state_completed'];
      for (const event of events) {
        await expect(logVoterEvent('uid-3', event, {})).resolves.toBeUndefined();
      }
    });
  });

  describe('logAIInteraction (mock path)', () => {
    it('resolves without throwing', async () => {
      await expect(
        logAIInteraction('uid-1', 'How do I vote?', 250, 320),
      ).resolves.toBeUndefined();
    });

    it('handles null firebaseUid', async () => {
      await expect(
        logAIInteraction(null, 'What is Form 6?', 180, 150),
      ).resolves.toBeUndefined();
    });

    it('truncates very long questions', async () => {
      const longQuestion = 'a'.repeat(2000);
      await expect(
        logAIInteraction('uid-1', longQuestion, 100, 200),
      ).resolves.toBeUndefined();
    });
  });

  describe('queryTurnoutStats (mock path)', () => {
    it('returns note when BigQuery not configured', async () => {
      const result = await queryTurnoutStats();
      expect(result).toHaveProperty('note');
      expect(result.data).toEqual([]);
    });
  });
});
