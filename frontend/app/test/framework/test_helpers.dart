// test/framework/test_helpers.dart
// Helper utilities for widget and unit tests

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps a widget with the providers and MaterialApp scaffolding needed for tests
Widget buildTestableWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: child,
    ),
  );
}

/// Pumps a widget into the test framework with common wrappers
Future<void> pumpTestWidget(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(buildTestableWidget(widget));
  await tester.pumpAndSettle();
}

/// Returns a matcher that checks text is visible on screen
Finder findText(String text) => find.text(text);

/// Returns a matcher for a widget by key
Finder findByKey(String key) => find.byKey(Key(key));
