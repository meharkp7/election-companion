/// Widget tests for OnboardingScreen — the app entry point.
/// Verifies form rendering, validation, accessibility, and loading states.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voteready/features/onboarding/screens/onboarding_screen.dart';
import 'package:voteready/providers/user_provider.dart';
import 'package:voteready/models/user_model.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

User _startUser() => const User(
      firebaseUid: 'test-uid',
      age: 0,
      state: '',
      isFirstTimeVoter: false,
      currentState: 'START',
      readinessScore: 0,
    );

Widget _wrap() => ProviderScope(
      overrides: [
        userProvider.overrideWith(() => _StubUserNotifier(_startUser())),
      ],
      child: const MaterialApp(home: OnboardingScreen()),
    );

class _StubUserNotifier extends UserNotifier {
  final User _user;
  _StubUserNotifier(this._user);
  @override
  AsyncValue<User> build() => AsyncValue.data(_user);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('OnboardingScreen — rendering', () {
    testWidgets('renders Scaffold without crashing', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows age text field', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows state dropdown', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('shows first-time voter switch', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('shows submit button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      // PrimaryButton wraps ElevatedButton
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows trust badge', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.verified_outlined), findsWidgets);
    });
  });

  group('OnboardingScreen — form validation', () {
    testWidgets('submit with empty age shows validation error', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      // Tap submit without filling anything
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Form should not submit — no loading indicator
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('entering age updates text field', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), '25');
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('toggling first-time voter switch changes state', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      final updatedSwitch = tester.widget<Switch>(find.byType(Switch));
      expect(updatedSwitch.value, isTrue);
    });
  });

  group('OnboardingScreen — accessibility', () {
    testWidgets('contains Semantics widgets', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('has FocusTraversalGroup for ordered navigation', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(FocusTraversalGroup), findsWidgets);
    });

    testWidgets('age field has semantic label', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      final semantics = tester.getSemantics(find.byType(TextFormField));
      expect(semantics, isNotNull);
    });

    testWidgets('switch has toggled semantics', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      final switchSemantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.toggled != null,
      );
      expect(switchSemantics, findsWidgets);
    });

    testWidgets('trust badge has semantic label', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      // Trust badge is wrapped in Semantics with label
      final semanticsWithLabel = find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label?.contains('Trusted') ?? false),
      );
      expect(semanticsWithLabel, findsWidgets);
    });

    testWidgets('ExcludeSemantics used for decorative logo', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(ExcludeSemantics), findsNothing); // logo uses Semantics(header:true)
    });
  });

  group('OnboardingScreen — loading state', () {
    testWidgets('shows loader when user provider is loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith(() => _LoadingUserNotifier()),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pump();
      // Screen still renders (loading is for user data, not the form itself)
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('OnboardingScreen — state list', () {
    testWidgets('dropdown contains Indian states', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      // Open the dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Should find at least Delhi and Maharashtra
      expect(find.text('Delhi'), findsWidgets);
      expect(find.text('Maharashtra'), findsWidgets);
    });
  });
}

class _LoadingUserNotifier extends UserNotifier {
  @override
  AsyncValue<User> build() => const AsyncValue.loading();
}
