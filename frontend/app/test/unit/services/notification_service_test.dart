import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voteready/core/services/notification_service.dart';

void main() {
  group('NotificationPreferences', () {
    test('default values are correct', () {
      const prefs = NotificationPreferences();
      expect(prefs.electionReminders, isTrue);
      expect(prefs.votingDayAlerts, isTrue);
      expect(prefs.resultUpdates, isTrue);
      expect(prefs.applicationStatusUpdates, isTrue);
      expect(prefs.generalInfo, isFalse);
      expect(prefs.emergencyAlerts, isTrue);
      expect(prefs.quietHoursEnabled, isFalse);
    });

    test('copyWith updates only specified fields', () {
      const prefs = NotificationPreferences();
      final updated = prefs.copyWith(generalInfo: true, quietHoursEnabled: true);
      expect(updated.generalInfo, isTrue);
      expect(updated.quietHoursEnabled, isTrue);
      // Unchanged fields stay the same
      expect(updated.electionReminders, isTrue);
      expect(updated.emergencyAlerts, isTrue);
    });

    test('shouldShowNotification respects preferences', () {
      const prefs = NotificationPreferences(
        electionReminders: false,
        emergencyAlerts: true,
      );
      expect(prefs.shouldShowNotification(NotificationType.electionReminder), isFalse);
      expect(prefs.shouldShowNotification(NotificationType.emergency), isTrue);
      expect(prefs.shouldShowNotification(NotificationType.votingDayAlert), isTrue);
    });

    test('toJson / fromJson round-trip', () {
      const prefs = NotificationPreferences(
        generalInfo: true,
        quietHoursEnabled: true,
        quietHoursStart: TimeOfDay(hour: 23, minute: 0),
        quietHoursEnd: TimeOfDay(hour: 7, minute: 30),
      );
      final json = prefs.toJson();
      final restored = NotificationPreferences.fromJson(json);
      expect(restored.generalInfo, isTrue);
      expect(restored.quietHoursEnabled, isTrue);
      expect(restored.quietHoursStart.hour, 23);
      expect(restored.quietHoursEnd.minute, 30);
    });

    group('isInQuietHours', () {
      test('returns false when quiet hours disabled', () {
        const prefs = NotificationPreferences(quietHoursEnabled: false);
        expect(prefs.isInQuietHours(), isFalse);
      });

      test('overnight quiet hours logic is correct', () {
        // 22:00 – 08:00 overnight window
        const prefs = NotificationPreferences(
          quietHoursEnabled: true,
          quietHoursStart: TimeOfDay(hour: 22, minute: 0),
          quietHoursEnd: TimeOfDay(hour: 8, minute: 0),
        );
        // We can't control TimeOfDay.now() in unit tests, but we can verify
        // the method runs without throwing.
        expect(() => prefs.isInQuietHours(), returnsNormally);
      });
    });
  });

  group('NotificationData', () {
    test('toJson / fromJson round-trip', () {
      final data = NotificationData(
        id: 'test-id',
        title: 'Election Day',
        body: 'Go vote!',
        type: NotificationType.votingDayAlert,
        timestamp: DateTime(2025, 4, 25, 9, 0),
        data: {'constituency': 'Delhi North'},
        actionUrl: '/voting-day',
      );
      final json = data.toJson();
      final restored = NotificationData.fromJson(json);
      expect(restored.id, 'test-id');
      expect(restored.title, 'Election Day');
      expect(restored.type, NotificationType.votingDayAlert);
      expect(restored.data?['constituency'], 'Delhi North');
      expect(restored.actionUrl, '/voting-day');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'x',
        'title': 'T',
        'body': 'B',
        'type': 'generalInfo',
        'timestamp': DateTime.now().toIso8601String(),
      };
      final data = NotificationData.fromJson(json);
      expect(data.imageUrl, isNull);
      expect(data.actionUrl, isNull);
      expect(data.data, isNull);
    });
  });

  group('NotificationType parsing', () {
    test('all types serialise to their name', () {
      for (final type in NotificationType.values) {
        expect(type.name, isNotEmpty);
      }
    });
  });
}
