/**
 * Unit tests for Cloud Tasks service.
 * Runs entirely in mock mode (no GOOGLE_CLOUD_PROJECT_ID set).
 */

// Ensure Cloud Tasks is NOT configured so we exercise the mock path
delete process.env.GOOGLE_CLOUD_PROJECT_ID;

jest.mock('@google-cloud/tasks', () => ({
  CloudTasksClient: jest.fn().mockImplementation(() => ({
    queuePath: jest.fn().mockReturnValue('projects/p/locations/l/queues/q'),
    createTask: jest.fn().mockResolvedValue([{ name: 'task-name' }]),
  })),
}));

const {
  isConfigured,
  enqueueNotification,
  enqueueAnalyticsBatch,
  enqueueDocumentProcessing,
  scheduleReminder,
} = require('../src/services/cloudTasks.service');

describe('CloudTasksService — mock mode', () => {
  it('isConfigured returns false when project ID is not set', () => {
    expect(isConfigured()).toBe(false);
  });

  it('enqueueNotification resolves to null in mock mode', async () => {
    const result = await enqueueNotification('uid-1', 'Title', 'Body');
    expect(result).toBeNull();
  });

  it('enqueueNotification accepts optional data payload', async () => {
    await expect(
      enqueueNotification('uid-1', 'Title', 'Body', { type: 'reminder' }),
    ).resolves.toBeNull();
  });

  it('enqueueAnalyticsBatch resolves to null in mock mode', async () => {
    const events = [
      { firebaseUid: 'uid-1', eventType: 'voted', context: {} },
      { firebaseUid: 'uid-2', eventType: 'onboarded', context: { state: 'Delhi' } },
    ];
    await expect(enqueueAnalyticsBatch(events)).resolves.toBeNull();
  });

  it('enqueueDocumentProcessing resolves to null in mock mode', async () => {
    await expect(
      enqueueDocumentProcessing('uid-1', 'https://storage.example.com/doc.pdf', 'voter_id'),
    ).resolves.toBeNull();
  });

  it('scheduleReminder resolves to null in mock mode', async () => {
    const future = new Date(Date.now() + 60 * 60 * 1000); // 1 hour from now
    await expect(
      scheduleReminder('uid-1', 'Election Tomorrow!', 'Get ready to vote.', future),
    ).resolves.toBeNull();
  });

  it('scheduleReminder with past date resolves without throwing', async () => {
    const past = new Date(Date.now() - 1000);
    await expect(
      scheduleReminder('uid-1', 'Late reminder', 'Better late than never.', past),
    ).resolves.toBeNull();
  });

  it('enqueueAnalyticsBatch handles empty array', async () => {
    await expect(enqueueAnalyticsBatch([])).resolves.toBeNull();
  });
});
