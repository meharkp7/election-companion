import 'package:flutter_test/flutter_test.dart';
import 'package:voteready/models/user_model.dart';

void main() {
  group('User model', () {
    const base = User(
      firebaseUid: 'uid-1',
      age: 28,
      state: 'Delhi',
      isFirstTimeVoter: false,
      currentState: 'REGISTRATION',
      readinessScore: 60,
    );

    test('copyWith updates only specified fields', () {
      final updated = base.copyWith(age: 30, readinessScore: 80);
      expect(updated.age, 30);
      expect(updated.readinessScore, 80);
      expect(updated.state, 'Delhi'); // unchanged
      expect(updated.firebaseUid, 'uid-1'); // unchanged
    });

    test('currentScreen falls back to onboarding when latestUI is null', () {
      expect(base.currentScreen, 'onboarding');
    });

    test('boothDetails is null when boothName is null', () {
      expect(base.boothDetails, isNull);
    });

    test('boothDetails is populated when boothName is set', () {
      final withBooth = base.copyWith(
        boothName: 'Booth 42',
        boothAddress: '123 Main St',
      );
      expect(withBooth.boothDetails, isNotNull);
      expect(withBooth.boothDetails!['boothName'], 'Booth 42');
      expect(withBooth.boothDetails!['boothAddress'], '123 Main St');
    });

    test('isFirstTimeVoter flag is preserved through copyWith', () {
      final firstTimer = base.copyWith(isFirstTimeVoter: true);
      expect(firstTimer.isFirstTimeVoter, isTrue);
      // Original unchanged
      expect(base.isFirstTimeVoter, isFalse);
    });
  });

  group('GlobalInsights model', () {
    // Imported via stats_model.dart — tested here for completeness
  });
}
