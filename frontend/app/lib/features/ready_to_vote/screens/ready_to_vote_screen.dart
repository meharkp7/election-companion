import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/router/app_router.dart';

import '../../../providers/user_provider.dart';
import '../../../shared/widgets/readiness_score_card.dart';
import 'package:go_router/go_router.dart';

class ReadyToVoteScreen extends ConsumerWidget {
  const ReadyToVoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (user) {
            final score = user.readinessScore;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  ReadinessScoreCard(score: score),
                  const SizedBox(height: 32),
                  _buildChecklist(),
                  const SizedBox(height: 32),
                  _buildQuickActions(context),
                  const SizedBox(height: 32),
                  _buildTrustBadge(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          '🎉 You\'re Vote-Ready!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Everything is set. We\'ll remind you on election day.',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildChecklist() {
    final checks = [
      ('✅', 'Age eligibility confirmed'),
      ('✅', 'Voter registration complete'),
      ('✅', 'Name verified on electoral roll'),
      ('✅', 'Polling booth located'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Checklist',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...checks.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(c.$1, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Text(c.$2, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTrustBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_outlined,
              size: 16, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data sourced from Election Commission of India. No political bias.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildQuickActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore Features',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _QuickActionButton(
            icon: Icons.checklist,
            title: 'Polling Day Kit',
            subtitle: 'Checklist, voter slip & emergency help',
            color: AppColors.orange,
            onTap: () => context.push(AppRoutes.pollingDayKit),
          ),
          const SizedBox(height: 10),
          _QuickActionButton(
            icon: Icons.calendar_today,
            title: 'Election Tracker',
            subtitle: 'Dates, phases & live turnout',
            color: AppColors.blue,
            onTap: () => context.push(AppRoutes.electionTracker),
          ),
          const SizedBox(height: 10),
          _QuickActionButton(
            icon: Icons.gavel,
            title: 'Voter Rights & Help',
            subtitle: 'Know your rights & get help',
            color: AppColors.green,
            onTap: () => context.push(AppRoutes.voterRights),
          ),
          const SizedBox(height: 10),
          _QuickActionButton(
            icon: Icons.emoji_events,
            title: 'Election Results',
            subtitle: 'Live results & analysis',
            color: Colors.purple,
            onTap: () => context.push(AppRoutes.electionResults),
          ),
          const SizedBox(height: 10),
          _QuickActionButton(
            icon: Icons.people,
            title: 'Social Features',
            subtitle: 'Carpool & share your vote',
            color: Colors.teal,
            onTap: () => context.push(AppRoutes.socialFeatures),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle. Tap to navigate.',
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ), // InkWell
      ), // Semantics
    );
  }
}
