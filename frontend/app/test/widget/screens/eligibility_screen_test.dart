import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voteready/features/eligibility/screens/eligibility_screen.dart';
import 'package:voteready/providers/user_provider.dart';
import 'package:voteready/models/user_model.dart';

User _stubUser({int age = 25, String userState = 'Delhi'}) => User(
      firebaseUid: 'test-uid',
      age: age,
      state: userState,
      isFirstTimeVoter: false,
      currentState: 'ELIGIBILITY_CHECK',
      readinessScore: 40,
    );

Widget _wrap(Widget child, {User? user}) {
  return ProviderScope(
    overrides: [
      userProvider.overrideWith(() => _StubUserNotifier(user ?? _stubUser())),
    ],
    child: const MaterialApp(home: EligibilityScreen()),
  );
}

class _StubUserNotifier extends UserNotifier {
  final User _user;
  _StubUserNotifier(this._user);
  @override
  AsyncValue<User> build() => AsyncValue.data(_user);
}

void main() {
  group('EligibilityScreen', () {
    testWidgets('renders a Scaffold without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const EligibilityScreen()));
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('contains Semantics widgets for accessibility', (tester) async {
      await tester.pumpWidget(_wrap(const EligibilityScreen()));
      await tester.pump();
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('shows ExcludeSemantics for decorative icon', (tester) async {
      await tester.pumpWidget(_wrap(const EligibilityScreen()));
      await tester.pump();
      expect(find.byType(ExcludeSemantics), findsWidgets);
    });
  });
}
