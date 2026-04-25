/**
 * Unit tests for notification service
 */

jest.mock('../src/config/firebase', () => ({
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        get: jest.fn(),
      })),
    })),
  })),
  messaging: jest.fn(() => ({
    send: jest.fn(),
  })),
}));

jest.mock('../src/config/postgres', () => ({
  query: jest.fn(),
}));

const admin = require('../src/config/firebase');
const { query } = require('../src/config/postgres');
const { sendPushNotification, notifyIncompleteUsers } = require('../src/services/notification.service');

describe('NotificationService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('sendPushNotification', () => {
    it('sends notification when FCM token exists', async () => {
      const mockGet = jest.fn().mockResolvedValue({
        data: () => ({ fcmToken: 'test-fcm-token' }),
      });
      admin.firestore.mockReturnValue({
        collection: () => ({ doc: () => ({ get: mockGet }) }),
      });
      const mockSend = jest.fn().mockResolvedValue('message-id');
      admin.messaging.mockReturnValue({ send: mockSend });

      await sendPushNotification('uid-1', 'Test Title', 'Test Body');

      expect(mockSend).toHaveBeenCalledWith(
        expect.objectContaining({
          token: 'test-fcm-token',
          notification: { title: 'Test Title', body: 'Test Body' },
        }),
      );
    });

    it('does nothing when FCM token is missing', async () => {
      const mockGet = jest.fn().mockResolvedValue({
        data: () => ({}), // no fcmToken
      });
      admin.firestore.mockReturnValue({
        collection: () => ({ doc: () => ({ get: mockGet }) }),
      });
      const mockSend = jest.fn();
      admin.messaging.mockReturnValue({ send: mockSend });

      await sendPushNotification('uid-1', 'Title', 'Body');

      expect(mockSend).not.toHaveBeenCalled();
    });

    it('handles Firestore errors gracefully', async () => {
      admin.firestore.mockReturnValue({
        collection: () => ({
          doc: () => ({ get: jest.fn().mockRejectedValue(new Error('Firestore down')) }),
        }),
      });

      // Should not throw
      await expect(
        sendPushNotification('uid-1', 'Title', 'Body'),
      ).resolves.toBeUndefined();
    });
  });

  describe('notifyIncompleteUsers', () => {
    it('sends notifications to users in REGISTRATION state', async () => {
      query.mockResolvedValue([
        { firebase_uid: 'uid-1', current_state: 'REGISTRATION' },
        { firebase_uid: 'uid-2', current_state: 'VERIFICATION' },
      ]);

      const mockGet = jest.fn().mockResolvedValue({
        data: () => ({ fcmToken: 'token-abc' }),
      });
      admin.firestore.mockReturnValue({
        collection: () => ({ doc: () => ({ get: mockGet }) }),
      });
      const mockSend = jest.fn().mockResolvedValue('ok');
      admin.messaging.mockReturnValue({ send: mockSend });

      await notifyIncompleteUsers();

      // Two users → two send calls
      expect(mockSend).toHaveBeenCalledTimes(2);
    });

    it('handles empty user list gracefully', async () => {
      query.mockResolvedValue([]);

      await expect(notifyIncompleteUsers()).resolves.toBeUndefined();
    });
  });
});
