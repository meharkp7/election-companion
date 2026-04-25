import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../providers/global_insights_provider.dart';
import '../../../shared/components/loaders.dart';
import '../../../shared/components/error_view.dart';

class GlobalInsightsScreen extends ConsumerWidget {
  const GlobalInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(globalInsightsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text(AppStrings.globalTitle)),
      body: SafeArea(
        child: insightsAsync.when(
          loading: () => const AppLoader(message: 'Loading global data...'),
          error: (e, _) => ErrorView(
            message: AppStrings.errorGeneric,
            onRetry: () => ref.invalidate(globalInsightsProvider),
          ),
          data: (insights) {
            // Fallback demo data when API not ready
            final data = insights.isEmpty
                ? _demoInsights
                : insights.items
                    .map((i) =>
                        _Row(i.flag, i.country, i.turnout, i.year.toString()))
                    .toList();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.globalTitle,
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.globalSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: .5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'India avg: ~67%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange,
                          fontFamily: 'Syne',
                        ),
                      ),
                      Text(
                        'Lok Sabha 2024',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: .5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Country Comparison',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),

                for (final row in data) ...[
                  _CountryRow(row: row),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.blue.withValues(alpha: .15),
                      width: 0.5,
                    ),
                  ),
                  child: const Text(
                    'Data sourced from IDEA (International Institute for Democracy and Electoral Assistance) and Election Commission of India.',
                    style: TextStyle(fontSize: 12, color: AppColors.ink3),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static final _demoInsights = [
    const _Row('🇮🇳', 'India', 67.4, '2024'),
    const _Row('🇸🇪', 'Sweden', 84.2, '2022'),
    const _Row('🇩🇪', 'Germany', 76.4, '2021'),
    const _Row('🇬🇧', 'UK', 67.3, '2019'),
    const _Row('🇺🇸', 'USA', 62.8, '2020'),
    const _Row('🇧🇷', 'Brazil', 78.5, '2022'),
    const _Row('🇿🇦', 'South Africa', 58.5, '2024'),
  ];
}

class _Row {
  final String flag;
  final String country;
  final double turnout;
  final String year;
  const _Row(this.flag, this.country, this.turnout, this.year);
}

class _CountryRow extends StatelessWidget {
  final _Row row;
  const _CountryRow({required this.row});

  Color get _barColor {
    if (row.turnout >= 80) return AppColors.green;
    if (row.turnout >= 65) return AppColors.orange;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${row.country}: ${row.turnout.toStringAsFixed(1)}% voter turnout in ${row.year}',
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(row.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.country,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'Last election: ${row.year}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${row.turnout.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _barColor,
                  fontFamily: 'Syne',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: row.turnout / 100,
              minHeight: 4,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation(_barColor),
            ),
          ),
        ],
      ),
    ), // Semantics
    );
  }
}
