import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/router/app_router.dart';

import '../../../providers/user_provider.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/components/loaders.dart';
import '../../../shared/components/secondary_button.dart';

class VotingDayScreen extends ConsumerStatefulWidget {
  const VotingDayScreen({super.key});

  @override
  ConsumerState<VotingDayScreen> createState() => _VotingDayScreenState();
}

class _VotingDayScreenState extends ConsumerState<VotingDayScreen> {
  int _currentStep = 0;
  bool _electionModeOn = false;

  static const _votingSteps = [
    _VotingStep(
      icon: Icons.directions_walk,
      title: 'Go to your polling booth',
      detail:
          'Carry your Voter ID or any valid photo ID. Arrive early to avoid queues.',
    ),
    _VotingStep(
      icon: Icons.badge_outlined,
      title: 'Show your Voter ID / Aadhaar',
      detail: 'The officer will verify your name in the electoral roll.',
    ),
    _VotingStep(
      icon: Icons.front_hand_outlined,
      title: 'Get ink mark on finger',
      detail:
          'Indelible ink is applied to your left index finger. This confirms you have voted.',
    ),
    _VotingStep(
      icon: Icons.touch_app_outlined,
      title: 'Press button on EVM to vote',
      detail:
          'The EVM (Electronic Voting Machine) will show candidate names. Press the button next to your choice.',
    ),
    _VotingStep(
      icon: Icons.receipt_long_outlined,
      title: 'Confirm vote on VVPAT screen',
      detail:
          'A paper slip appears for 7 seconds confirming your vote. Check it before it drops into the sealed box.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: AppLoader()),
      error: (e, _) =>
          const Scaffold(body: Center(child: Text(AppStrings.errorGeneric))),
      data: (user) {
        final ui = user.latestUI;
        final title = ui?.title ?? AppStrings.votingDayTitle;
        // Use backend steps if available
        final defaultIcons = [
          Icons.directions_walk,
          Icons.badge_outlined,
          Icons.touch_app_outlined,
          Icons.receipt_long_outlined,
        ];
        final currentSteps = (ui?.steps != null && ui!.steps.isNotEmpty)
            ? List.generate(
                ui.steps.length,
                (i) => _VotingStep(
                  icon: i < defaultIcons.length
                      ? defaultIcons[i]
                      : Icons.check_circle_outline,
                  title: ui.steps[i],
                  detail: '',
                ),
              )
            : _votingSteps; // Fallback to hardcoded details if needed

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: Text(title),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Semantics(
                  label: 'Election Mode',
                  hint: _electionModeOn
                      ? 'Currently on. Tap to turn off'
                      : 'Currently off. Tap to turn on',
                  toggled: _electionModeOn,
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      Text(
                        'Election Mode',
                        style: TextStyle(
                          fontSize: 12,
                          color: _electionModeOn
                              ? AppColors.orange
                              : AppColors.ink3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Switch(
                        value: _electionModeOn,
                        onChanged: (v) {
                          setState(() => _electionModeOn = v);
                          if (v) {
                            ref
                                .read(userProvider.notifier)
                                .sendStep({'electionMode': true});
                          }
                        },
                        activeThumbColor: AppColors.orange,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Election mode banner — live region announces to screen reader
                  if (_electionModeOn) ...[
                    Semantics(
                      liveRegion: true,
                      label: 'Election Mode is active. ${AppStrings.electionModeOn}',
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.how_to_vote,
                                color: AppColors.orange, size: 20),
                            const SizedBox(width: 10),
                            const Text(
                              AppStrings.electionModeOn,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Required items
                  Semantics(
                    label: 'Items to carry: Voter ID or Aadhaar, Phone for reference, Water bottle',
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.amberLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.amber.withValues(alpha: .2),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Carry with you',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final item in [
                            'Voter ID / Aadhaar',
                            'Phone (for reference)',
                            'Water bottle',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      size: 14, color: AppColors.amber),
                                  const SizedBox(width: 8),
                                  Text(
                                    item,
                                    style: const TextStyle(
                                        fontSize: 13, color: AppColors.ink),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Access',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.checklist,
                                label: 'Kit',
                                color: AppColors.orange,
                                onTap: () =>
                                    context.push(AppRoutes.pollingDayKit),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.gavel,
                                label: 'Rights',
                                color: AppColors.green,
                                onTap: () =>
                                    context.push(AppRoutes.voterRights),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.people,
                                label: 'Social',
                                color: Colors.teal,
                                onTap: () =>
                                    context.push(AppRoutes.socialFeatures),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Step-by-step
                  Semantics(
                    label: 'Step ${_currentStep + 1} of ${currentSteps.length}: ${currentSteps[_currentStep].title}',
                    child: Text(
                      'Step ${_currentStep + 1} of ${currentSteps.length}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: currentSteps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final step = currentSteps[i];
                        final isActive = i == _currentStep;
                        final isDone = i < _currentStep;
                        return Semantics(
                          button: true,
                          selected: isActive,
                          label: [
                            'Step ${i + 1}: ${step.title}',
                            if (isDone) 'Completed',
                            if (isActive) 'Current step. ${step.detail}',
                          ].join('. '),
                          onTap: () => setState(() => _currentStep = i),
                          child: GestureDetector(
                            onTap: () => setState(() => _currentStep = i),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.orangeLight
                                  : isDone
                                      ? AppColors.greenLight
                                      : AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.orange.withValues(alpha: .3)
                                    : isDone
                                        ? AppColors.green.withValues(alpha: .3)
                                        : AppColors.border,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.orange
                                            .withValues(alpha: .15)
                                        : isDone
                                            ? AppColors.green
                                                .withValues(alpha: .15)
                                            : AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isDone ? Icons.check : step.icon,
                                    size: 18,
                                    color: isActive
                                        ? AppColors.orange
                                        : isDone
                                            ? AppColors.green
                                            : AppColors.ink3,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isActive
                                              ? AppColors.orange
                                              : isDone
                                                  ? AppColors.green
                                                  : AppColors.ink,
                                        ),
                                      ),
                                      if (isActive &&
                                          step.detail.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          step.detail,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.ink3,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ), // GestureDetector
                        ); // Semantics
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Navigation buttons
                  Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: 'Go to previous step',
                            child: SecondaryButton(
                              label: 'Previous',
                              onPressed: () =>
                                  setState(() => _currentStep--),
                            ),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _currentStep < currentSteps.length - 1
                            ? Semantics(
                                button: true,
                                label:
                                    'Go to step ${_currentStep + 2}: ${currentSteps[_currentStep + 1].title}',
                                child: PrimaryButton(
                                  label: 'Next Step',
                                  onPressed: () =>
                                      setState(() => _currentStep++),
                                  icon: Icons.arrow_forward,
                                ),
                              )
                            : Semantics(
                                button: true,
                                label: 'Mark yourself as voted and finish',
                                child: PrimaryButton(
                                  label: 'I Have Voted! 🎉',
                                  onPressed: () {
                                    ref
                                        .read(userProvider.notifier)
                                        .markVoted();
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VotingStep {
  final IconData icon;
  final String title;
  final String detail;
  const _VotingStep({
    required this.icon,
    required this.title,
    required this.detail,
  });
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      hint: 'Opens $label section',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          // WCAG minimum 48×48dp touch target
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}