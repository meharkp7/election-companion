import 'package:flutter_test/flutter_test.dart';
import 'package:voteready/core/services/analytics_service.dart';

void main() {
  group('AnalyticsEvent', () {
    test('toJson / fromJson round-trip', () {
      final event = AnalyticsEvent(
        name: 'screen_view',
        type: AnalyticsEventType.screenView,
        parameters: {'screen_name': 'onboarding'},
        sessionId: 'session-1',
        userId: 'user-1',
      );
      final json = event.toJson();
      final restored = AnalyticsEvent.fromJson(json);
      expect(restored.name, 'screen_view');
      expect(restored.type, AnalyticsEventType.screenView);
      expect(restored.parameters['screen_name'], 'onboarding');
      expect(restored.sessionId, 'session-1');
      expect(restored.userId, 'user-1');
    });

    test('timestamp defaults to now when not provided', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final event = AnalyticsEvent(
        name: 'test',
        type: AnalyticsEventType.userAction,
      );
      expect(event.timestamp.isAfter(before), isTrue);
    });

    test('all AnalyticsEventType values have names', () {
      for (final type in AnalyticsEventType.values) {
        expect(type.name, isNotEmpty);
      }
    });
  });

  group('UserProperties', () {
    test('copyWith preserves unchanged fields', () {
      final props = UserProperties(
        userId: 'u1',
        isFirstTimeVoter: true,
        appVersion: '1.0.0',
        deviceModel: 'Pixel',
        operatingSystem: 'android',
        operatingSystemVersion: '14',
        firstLaunchDate: DateTime(2025, 1, 1),
        totalSessions: 5,
        totalScreenViews: 20,
      );
      final updated = props.copyWith(state: 'Delhi', totalSessions: 6);
      expect(updated.userId, 'u1');
      expect(updated.state, 'Delhi');
      expect(updated.totalSessions, 6);
      expect(updated.totalScreenViews, 20); // unchanged
      expect(updated.isFirstTimeVoter, isTrue); // unchanged
    });

    test('toJson includes all required fields', () {
      final props = UserProperties(
        userId: 'u2',
        isFirstTimeVoter: false,
        appVersion: '1.0.0',
        deviceModel: 'iPhone',
        operatingSystem: 'ios',
        operatingSystemVersion: '17',
        firstLaunchDate: DateTime(2025, 3, 15),
      );
      final json = props.toJson();
      expect(json['userId'], 'u2');
      expect(json['isFirstTimeVoter'], isFalse);
      expect(json['appVersion'], '1.0.0');
      expect(json['totalSessions'], 0);
    });
  });
}
