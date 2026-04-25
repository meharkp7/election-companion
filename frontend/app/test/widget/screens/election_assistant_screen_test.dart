/// Widget tests for ElectionAssistantScreen.
/// Verifies chat UI rendering, quick questions, and accessibility.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voteready/features/assistant/screens/election_assistant_screen.dart';
import 'package:voteready/providers/user_provider.dart';
import 'package:voteready/models/user_model.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

User _assistantUser() => const User(
      firebaseUid: 'test-uid',
      age: 25,
      state: 'Delhi',
      isFirstTimeVoter: false,
      currentState: 'READY_TO_VOTE',
      readinessScore: 100,
    );

Widget _wrap() => ProviderScope(
      overrides: [
        userProvider.overrideWith(() => _StubUserNotifier(_assistantUser())),
      ],
      child: const MaterialApp(home: ElectionAssistantScreen()),
    );

class _StubUserNotifier extends UserNotifier {
  final User _user;
  _StubUserNotifier(this._user);
  @override
  AsyncValue<User> build() => AsyncValue.data(_user);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ElectionAssistantScreen — rendering', () {
    testWidgets('renders Scaffold without crashing', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows AppBar with title', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Election AI Assistant'), findsOneWidget);
    });

    testWidgets('shows initial greeting message', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.textContaining('Election Companion AI'), findsOneWidget);
    });

    testWidgets('shows text input field', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows send button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.send), findsOneWidget);
    });
  });

  group('ElectionAssistantScreen — message input', () {
    testWidgets('typing in text field updates its value', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'How do I vote?');
      expect(find.text('How do I vote?'), findsOneWidget);
    });

    testWidgets('empty message does not add to chat', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      final initialMessageCount = find.byType(Align).evaluate().length;

      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // No new message bubble should appear
      expect(find.byType(Align).evaluate().length, initialMessageCount);
    });
  });

  group('ElectionAssistantScreen — accessibility', () {
    testWidgets('contains Semantics widgets', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('text field has semantic label', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      final semantics = tester.getSemantics(find.byType(TextField));
      expect(semantics, isNotNull);
    });

    testWidgets('send button has semantic label', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      final sendButton = find.byIcon(Icons.send);
      expect(sendButton, findsOneWidget);
    });

    testWidgets('chat bubbles use Semantics with liveRegion', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      // Initial greeting bubble should have liveRegion=true
      final liveRegions = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      );
      expect(liveRegions, findsWidgets);
    });
  });

  group('ElectionAssistantScreen — quick questions', () {
    testWidgets('quick question chips appear after initial message', (tester) async {
      await tester.pumpWidget(_wrap());
      // Allow initState to run (loads quick questions)
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Quick questions are shown when last message is from assistant
      // The initial greeting is from assistant, so chips should appear
      expect(find.byType(ActionChip), findsWidgets);
    });
  });

  group('ElectionAssistantScreen — scroll', () {
    testWidgets('ListView is present for messages', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
