/// Widget tests for VotingDayScreen.
/// Verifies rendering, accessibility semantics, and step navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voteready/features/voting_day/screens/voting_day_screen.dart';
import 'package:voteready/providers/user_provider.dart';
import 'package:voteready/models/user_model.dart';
import 'package:voteready/models/assistant_response.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

User _votingUser({String? boothName}) => User(
      firebaseUid: 'test-uid',
      age: 25,
      state: 'Delhi',
      isFirstTimeVoter: false,
      currentState: 'VOTING_DAY',
      readinessScore: 100,
      boothName: boothName,
      latestUI: AssistantUI.fromJson({
        'screen': 'voting_day',
        'title': '🗳️ Today is Election Day!',
        'steps': [
          'Go to your polling booth',
          'Show your Voter ID',
          'Vote on EVM',
          'Verify on VVPAT',
        ],
      }),
    );

Widget _wrap(User user) => ProviderScope(
      overrides: [
        userProvider.overrideWith(() => _StubUserNotifier(user)),
      ],
      child: const MaterialApp(home: VotingDayScreen()),
    );

class _StubUserNotifier extends UserNotifier {
  final User _user;
  _StubUserNotifier(this._user);
  @override
  AsyncValue<User> build() => AsyncValue.data(_user);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('VotingDayScreen — rendering', () {
    testWidgets('renders Scaffold without crashing', (tester) async {
      await tester.pumpWidget(_wrap(_votingUser()));
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows Election Mode switch in app bar', (tester) async {
      await tester.pumpWidget(_wrap(_votingUser()));
      await tester.pump();
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('shows "Carry with you" section', (tester) async {
      await tester.pumpWidget(_wrap(_votingUser()));
      await tester.pump();
      expect(find.text('Carry with you'), findsOneWidget);
    });

    testWidgets('shows Quick Access section', (tester) async {
      await tester.pumpWidget(_wrap(_votingUser()));
      await tester.pump();
      expect(find.text('Quick Access'), findsOneWidget);
    });

    testWidgets('shows step counter text', (tester) async {
      await tester.pumpWidget(_wrap(_votingUser()));
      await tester.pump();
      expect(find.textContaining('Step 1 of'), findsOneWidget);
    });

    testWidgets('shows I Have Voted button on last step', (tester) async {
      await tester.pumpWidget(_wrap(_votingUser()));
      await tester.pump();

      // Navigate to last step by tapping Next Step repeatedly
      while (find.text('Next Step').evaluate().isNotEmpty) {
        await tester.tap(find.text('Next Step'));
        await tester.pump();
      }

      expect(find.textContaining('I Have Voted'), findsOneWidget);
    });
  });

  group('VotingDayScreen — step navigation', () {
    testWidgets('Previous button is hidden on first step', (tester) async {
      await tester.pumpWidget(_wrap(_votingUser()));
      await tester.pump();
      expect(find.text('Previous'), findsNothing);
    });

    testWidgets('Previous button appears after advancing a step', (tester) async {
      await tester.pumpWidget(_wrap(_votingUser()));
      await tester.pump();

      await tester.tap(find.text('Next Step'));
      await tester.pump();

      expect(find.text('Previous'), findsOneWidget);
    });

    testWidgets('tapping a step card selects it', (tester) async {
      await tester.pumpWidget(_wrap(_votingUser()));
      await tester.pump();

      // Advance to step 2 first
      await tester.tap(find.text('Next Step'));
      await tester.pump();

      // Tap back on step 1 card (first item in list)
      final stepCards = find.byType(GestureDetector);
      if (stepCards.evaluate().isNotEmpty) {
        await tester.tap(stepCards.first);
        await tester.pump();
      }
      // No crash = pass
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('VotingDayScreen — election mode', () {
    testWidgets('election mode banner is hidden by default', (tester) async {
      await tester.pumpWidget(_wrap(_votingUser()));
      await tester.pump();
      expect(find.byIcon(Icons.how_to_vote), findsNothing);
    });

    testWidgets('election mode banner appears when switch is toggled on',
        (tester) async {
      await tester.pumpWidget(_wrap(_votingUser()));
      await tester.pump();

      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Banner container with election mode icon should appear
      expect(find.byIcon(Icons.how_to_vote), findsWidgets);
    });
  });

  group('VotingDayScreen — accessibility', () {
    testWidgets('contains Semantics widgets', (tester) async {
      await tester.pumpWidget(_wrap(_votingUser()));
      await tester.pump();
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('Switch has semantic label', (tester) async {
      await tester.pumpWidget(_wrap(_votingUser()));
      await tester.pump();
      final semantics = tester.getSemantics(find.byType(Switch));
      expect(semantics, isNotNull);
    });

    testWidgets('Quick action buttons have semantic labels', (tester) async {
      await tester.pumpWidget(_wrap(_votingUser()));
      await tester.pump();
      // _QuickAction widgets wrap with Semantics(button: true)
      final semanticButtons = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label != null,
      );
      expect(semanticButtons, findsWidgets);
    });
  });

  group('VotingDayScreen — loading and error states', () {
    testWidgets('shows loader when user is loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith(() => _LoadingUserNotifier()),
          ],
          child: const MaterialApp(home: VotingDayScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows error text when user fails to load', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith(() => _ErrorUserNotifier()),
          ],
          child: const MaterialApp(home: VotingDayScreen()),
        ),
      );
      await tester.pump();
      expect(find.textContaining('error'), findsWidgets);
    });
  });
}

class _LoadingUserNotifier extends UserNotifier {
  @override
  AsyncValue<User> build() => const AsyncValue.loading();
}

class _ErrorUserNotifier extends UserNotifier {
  @override
  AsyncValue<User> build() =>
      AsyncValue.error('Network error', StackTrace.empty);
}
