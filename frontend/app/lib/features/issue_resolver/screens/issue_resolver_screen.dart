import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/step_card.dart';

class IssueResolverScreen extends ConsumerWidget {
  const IssueResolverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extra = GoRouterState.of(context).extra as String?;
    final issue = _issueFor(extra);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text(AppStrings.issueTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Issue selector
              const SectionLabel('What is your issue?'),
              for (final i in _Issue.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: StepOptionCard(
                    label: i.label,
                    icon: i == issue
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    accentColor: i == issue ? AppColors.orange : AppColors.ink3,
                    onTap: () =>
                        context.go(AppRoutes.issueResolver, extra: i.key),
                  ),
                ),
              const SizedBox(height: 24),

              // Solution
              if (issue != null) ...[
                const SectionLabel('How to fix it'),
                ...issue.steps.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.orangeLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${e.key + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              e.value,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InfoCard(
                  title: issue.formTitle,
                  subtitle: issue.formDesc,
                  bgColor: AppColors.blueLight,
                  borderColor: AppColors.blue.withOpacity(.15),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      issue.formTag,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],

              const Spacer(),
              PrimaryButton(
                label: 'Back to Registration',
                onPressed: () async {
                  try {
                    // Tell backend to go back to previous state
                    await ref.read(userProvider.notifier).sendStep({'action': 'back'});
                  } catch (e) {
                    // If backend fails, try to reset to START
                    try {
                      await ref.read(userProvider.notifier).sendStep({'action': 'reset'});
                    } catch (_) {
                      // Ignore errors, just navigate
                    }
                  }
                  if (context.mounted) {
                    context.go(AppRoutes.home);
                  }
                },
                icon: Icons.arrow_back,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () async {
                    // Force reset to beginning
                    await ref.read(userProvider.notifier).sendStep({'action': 'restart'});
                    if (context.mounted) {
                      context.go(AppRoutes.home);
                    }
                  },
                  child: const Text(
                    'Start Over',
                    style: TextStyle(color: AppColors.ink3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _Issue? _issueFor(String? key) {
    if (key == null) return null;
    try {
      return _Issue.values.firstWhere((i) => i.key == key);
    } catch (_) {
      return null;
    }
  }
}

enum _Issue {
  nameMissing,
  wrongDetails,
  boothIssue;

  String get key => name;

  String get label => switch (this) {
    _Issue.nameMissing => AppStrings.issueNameMissing,
    _Issue.wrongDetails => AppStrings.issueWrongDetails,
    _Issue.boothIssue => AppStrings.issueBoothProblem,
  };

  String get formTitle => switch (this) {
    _Issue.nameMissing => 'Fill Form 6',
    _Issue.wrongDetails => 'Fill Form 8',
    _Issue.boothIssue => 'Contact BLO',
  };

  String get formTag => switch (this) {
    _Issue.nameMissing => 'Form 6',
    _Issue.wrongDetails => 'Form 8',
    _Issue.boothIssue => 'Helpline',
  };

  String get formDesc => switch (this) {
    _Issue.nameMissing => 'Application for inclusion of name in electoral roll',
    _Issue.wrongDetails =>
      'Application for correction of entries in electoral roll',
    _Issue.boothIssue => 'Contact your Booth Level Officer or call 1950',
  };

  List<String> get steps => switch (this) {
    _Issue.nameMissing => [
      'Visit voters.eci.gov.in and go to "Apply Online" section',
      'Select Form 6 – New Registration',
      'Fill in your personal details and upload Aadhaar + photo',
      'Submit and note your reference number',
      'Visit local BLO office if online submission fails',
    ],
    _Issue.wrongDetails => [
      'Visit voters.eci.gov.in or your local Electoral Registration Office',
      'Fill Form 8 – Correction of Entries',
      'Attach proof document matching the correct detail',
      'Submit online or at BLO office',
      'Corrections are processed within 15 working days',
    ],
    _Issue.boothIssue => [
      'Call the National Voter Helpline: 1950',
      'Contact your state Chief Electoral Officer',
      'Report to the Returning Officer at your booth',
      'If harassed, contact nearest police station',
    ],
  };
}
