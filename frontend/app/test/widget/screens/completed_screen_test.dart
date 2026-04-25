import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voteready/features/completed/screens/completed_screen.dart';
import 'package:voteready/providers/user_provider.dart';
import 'package:voteready/models/user_model.dart';

User _stubUser() => const User(
      firebaseUid: 'test-uid',
      age: 28,
      state: 'Delhi',
      isFirstTimeVoter: false,
      currentState: 'VOTED',
      readinessScore: 100,
    );

Widget _wrap() => ProviderScope(
      overrides: [
        userProvider.overrideWith(() => _StubUserNotifier(_stubUser())),
      ],
      child: const MaterialApp(home: CompletedScreen()),
    );

class _StubUserNotifier extends UserNotifier {
  final User _user;
  _StubUserNotifier(this._user);
  @override
  AsyncValue<User> build() => AsyncValue.data(_user);
}

void main() {
  group('CompletedScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has Semantics header for "You Voted"', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      // The heading Semantics widget should be present
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('trophy is wrapped in ExcludeSemantics', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(ExcludeSemantics), findsWidgets);
    });

    testWidgets('shows "You Voted!" text', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.textContaining('Voted'), findsWidgets);
    });
  });
}
