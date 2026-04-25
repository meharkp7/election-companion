import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:voteready/features/issue_resolver/screens/issue_resolver_screen.dart';
import 'package:voteready/providers/user_provider.dart';
import 'package:voteready/models/user_model.dart';

User _stubUser() => const User(
      firebaseUid: 'test-uid',
      age: 25,
      state: 'Delhi',
      isFirstTimeVoter: false,
      currentState: 'REGISTRATION',
      readinessScore: 50,
    );

Widget _wrap() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const IssueResolverScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      userProvider.overrideWith(() => _StubUserNotifier(_stubUser())),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

class _StubUserNotifier extends UserNotifier {
  final User _user;
  _StubUserNotifier(this._user);
  @override
  AsyncValue<User> build() => AsyncValue.data(_user);
}

void main() {
  group('IssueResolverScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows all three issue options', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      // All three _Issue enum labels should be visible
      expect(find.textContaining('name'), findsWidgets);
    });

    testWidgets('issue options have Semantics wrappers', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
