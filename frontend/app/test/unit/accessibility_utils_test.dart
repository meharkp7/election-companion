/// Unit and widget tests for AccessibilityUtils.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voteready/core/accessibility/accessibility_utils.dart';

void main() {
  group('AccessibilityUtils.touchTarget', () {
    testWidgets('enforces minimum 48×48 dp touch target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityUtils.touchTarget(
              child: const SizedBox(width: 20, height: 20),
            ),
          ),
        ),
      );
      final box = tester.renderObject<RenderBox>(find.byType(ConstrainedBox));
      expect(box.size.width, greaterThanOrEqualTo(48));
      expect(box.size.height, greaterThanOrEqualTo(48));
    });
  });

  group('AccessibilityUtils.screenWrapper', () {
    testWidgets('adds scopesRoute Semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityUtils.screenWrapper(
              label: 'Test screen',
              child: const Text('Hello'),
            ),
          ),
        ),
      );
      final semantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.scopesRoute == true,
      );
      expect(semantics, findsOneWidget);
    });
  });

  group('AccessibilityUtils.decorative', () {
    testWidgets('wraps child in ExcludeSemantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityUtils.decorative(
              child: const Icon(Icons.star),
            ),
          ),
        ),
      );
      expect(find.byType(ExcludeSemantics), findsOneWidget);
    });
  });

  group('AccessibilityUtils.liveRegion', () {
    testWidgets('adds liveRegion Semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityUtils.liveRegion(
              label: 'Status update',
              child: const Text('Loading...'),
            ),
          ),
        ),
      );
      final semantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      );
      expect(semantics, findsOneWidget);
    });
  });

  group('AccessibilityUtils.heading', () {
    testWidgets('adds header Semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityUtils.heading(
              child: const Text('Section Title'),
            ),
          ),
        ),
      );
      final semantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.header == true,
      );
      expect(semantics, findsOneWidget);
    });
  });

  group('AccessibilityUtils.button', () {
    testWidgets('adds button Semantics and touch target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityUtils.button(
              label: 'Submit form',
              hint: 'Double tap to submit',
              child: const Icon(Icons.check),
            ),
          ),
        ),
      );
      final semantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Submit form',
      );
      expect(semantics, findsOneWidget);

      // Touch target enforced
      final box = tester.renderObject<RenderBox>(find.byType(ConstrainedBox));
      expect(box.size.width, greaterThanOrEqualTo(48));
      expect(box.size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('disabled button has enabled=false semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityUtils.button(
              label: 'Disabled button',
              enabled: false,
              child: const Icon(Icons.block),
            ),
          ),
        ),
      );
      final semantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.enabled == false,
      );
      expect(semantics, findsOneWidget);
    });
  });

  group('AccessibilityUtils.orderedFocusGroup', () {
    testWidgets('wraps child in FocusTraversalGroup', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityUtils.orderedFocusGroup(
              child: const Text('Form'),
            ),
          ),
        ),
      );
      expect(find.byType(FocusTraversalGroup), findsWidgets);
    });
  });

  group('AccessibilityUtils.image', () {
    testWidgets('adds image Semantics with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityUtils.image(
              label: 'Indian flag',
              child: const Icon(Icons.flag),
            ),
          ),
        ),
      );
      final semantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Indian flag',
      );
      expect(semantics, findsOneWidget);
    });
  });
}
