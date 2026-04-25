import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../providers/stats_provider.dart';
import '../../../shared/components/loaders.dart';
import '../../../shared/components/error_view.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text(AppStrings.resultsTitle)),
      body: SafeArea(
        child: statsAsync.when(
          loading: () => const AppLoader(message: 'Loading results...'),
          error: (e, _) => ErrorView(
            message: AppStrings.errorGeneric,
            onRetry: () => ref.invalidate(statsProvider),
          ),
          data: (stats) {
            // Show placeholder when stats are null (pre-election or no constituency set)
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Turnout card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.constituencyName,
                        style: const TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.constituencyLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: .5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _StatChip(
                            label: AppStrings.turnoutLabel,
                            value:
                                '${stats.turnoutPercent.toStringAsFixed(1)}%',
                            color: AppColors.orange,
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            label: 'Total voters',
                            value: _fmt(stats.totalVoters),
                            color: AppColors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Candidate results
                const Text(
                  'Results',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                for (final c in stats.results)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            c.isWinner ? AppColors.greenLight : AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: c.isWinner
                              ? AppColors.green.withValues(alpha: .3)
                              : AppColors.border,
                          width: c.isWinner ? 1 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (c.isWinner)
                            const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Icon(
                                Icons.emoji_events_outlined,
                                color: AppColors.green,
                                size: 20,
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  c.party,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.ink3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _fmt(c.votes),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                '${c.votePercent.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.ink3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toString();
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Syne',
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: .8)),
          ),
        ],
      ),
    );
  }
}
