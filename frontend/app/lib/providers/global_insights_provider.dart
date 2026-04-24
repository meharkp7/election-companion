import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stats_model.dart';

final globalInsightsProvider = FutureProvider<GlobalInsights>((ref) async {
  // Simulated data fetching
  return GlobalInsights(
    title: 'Global Election Insights',
    description: 'Overview of election participation and trends',
    data: [
      InsightData(label: 'Voter Turnout', value: 75.0),
      InsightData(label: 'Youth Participation', value: 65.0),
      InsightData(label: 'Urban Voters', value: 60.0),
      InsightData(label: 'Rural Voters', value: 80.0),
    ],
    items: [
      const GlobalInsightItem(
        flag: '🇮🇳',
        country: 'India',
        turnout: 67.4,
        year: 2019,
      ),
      const GlobalInsightItem(
        flag: '🇺🇸',
        country: 'United States',
        turnout: 66.8,
        year: 2020,
      ),
      const GlobalInsightItem(
        flag: '🇬🇧',
        country: 'United Kingdom',
        turnout: 67.3,
        year: 2019,
      ),
      const GlobalInsightItem(
        flag: '🇧🇷',
        country: 'Brazil',
        turnout: 79.5,
        year: 2022,
      ),
    ],
  );
});
