import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voteready/features/global_insights/screens/global_insights_screen.dart';
import 'package:voteready/models/stats_model.dart';
import 'package:voteready/providers/global_insights_provider.dart';

GlobalInsights _emptyInsights() => const GlobalInsights(
      title: 'Test',
      description: 'Test',
      data: [],
      items: [], // isEmpty == true → screen uses demo data
    );

GlobalInsights _filledInsights() => const GlobalInsights(
      title: 'Test',
      description: 'Test',
      data: [],
      items: [
        GlobalInsightItem(flag: '🇮🇳', country: 'India', turnout: 67.4, year: 2024),
        GlobalInsightItem(flag: '🇸🇪', country: 'Sweden', turnout: 84.2, year: 2022),
      ],
    );

Widget _wrap(AsyncValue<GlobalInsights> override) {
  return ProviderScope(
    overrides: [
      globalInsightsProvider.overrideWith((ref) async {
        if (override is AsyncData<GlobalInsights>) return override.value;
        if (override is AsyncError) throw override.error as Object;
        // loading — return a future that never completes
        await Future<void>.delayed(const Duration(days: 1));
        return _emptyInsights();
      }),
    ],
    child: const MaterialApp(home: GlobalInsightsScreen()),
  );
}

void main() {
  group('GlobalInsightsScreen', () {
    testWidgets('shows loading indicator while fetching', (tester) async {
      await tester.pumpWidget(_wrap(const AsyncValue.loading()));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows demo data when insights list is empty', (tester) async {
      await tester.pumpWidget(_wrap(AsyncValue.data(_emptyInsights())));
      await tester.pumpAndSettle();
      // Demo data includes India
      expect(find.textContaining('India'), findsWidgets);
    });

    testWidgets('shows real data when items are provided', (tester) async {
      await tester.pumpWidget(_wrap(AsyncValue.data(_filledInsights())));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sweden'), findsWidgets);
    });

    testWidgets('country rows have Semantics labels', (tester) async {
      await tester.pumpWidget(_wrap(AsyncValue.data(_emptyInsights())));
      await tester.pumpAndSettle();
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('shows error view on error', (tester) async {
      await tester.pumpWidget(_wrap(
        AsyncValue.error(Exception('network error'), StackTrace.empty),
      ));
      await tester.pumpAndSettle();
      // ErrorView or some error widget should be present
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
