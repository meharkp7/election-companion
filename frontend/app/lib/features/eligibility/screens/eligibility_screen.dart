// ignore_for_file: use_super_parameters
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/components/loaders.dart';
import '../eligibility_controller.dart';

class EligibilityScreen extends ConsumerWidget {
  const EligibilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final controllerState = ref.watch(eligibilityControllerProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: AppLoader(message: 'Checking eligibility...')),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (user) {
        // If the user reached this screen, the backend has confirmed eligibility.
        // The latestUI from backend contains the title and prompt.
        final ui = user.latestUI;
        final title = ui?.title ?? AppStrings.eligibilityTitle;
        final prompt = ui?.prompt ?? AppStrings.eligible;

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Result icon — decorative; heading below carries the meaning
                  ExcludeSemantics(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        size: 32,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Live region — announced immediately when screen loads
                  Semantics(
                    liveRegion: true,
                    label: 'Eligibility status: $prompt',
                    child: Text(
                      prompt,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.green,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Criteria cards — all passed since backend confirmed eligibility
                  _CriterionRow(
                    label: 'Age',
                    value: '${user.age} years',
                    passed: true,
                    requirement: AppStrings.ageRequirement,
                  ),
                  const SizedBox(height: 12),
                  const _CriterionRow(
                    label: 'Citizenship',
                    value: 'Indian Citizen',
                    passed: true,
                    requirement: AppStrings.citizenshipRequirement,
                  ),
                  const SizedBox(height: 12),
                  _CriterionRow(
                    label: 'State',
                    value: user.state,
                    passed: true,
                    requirement: 'Registered state',
                  ),

                  const Spacer(),

                  // Continue button
                  Semantics(
                    button: true,
                    enabled: !controllerState.isLoading,
                    label: controllerState.isLoading
                        ? 'Loading, please wait'
                        : 'Continue to Registration',
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: controllerState.isLoading
                            ? null
                            : () => ref
                                .read(eligibilityControllerProvider.notifier)
                                .continueToNext(),
                        icon: controllerState.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.arrow_forward),
                        label: const Text('Continue to Registration'),
                      ),
                    ),
                  ),

                  if (controllerState.hasError) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      label: 'Error: ${controllerState.error}',
                      child: Center(
                        child: Text(
                          controllerState.error.toString(),
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CriterionRow extends StatelessWidget {
  final String label;
  final String value;
  final bool passed;
  final String requirement;

  const _CriterionRow({
    required this.label,
    required this.value,
    required this.passed,
    required this.requirement,
  });

  @override
  Widget build(BuildContext context) {
    // Single merged label — TalkBack reads entire row in one swipe
    final a11yLabel =
        '$label: $value. Requirement: $requirement. ${passed ? "Passed" : "Not met"}.';

    return Semantics(
      label: a11yLabel,
      excludeSemantics: true, // suppress child widget labels (all decorative)
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: passed ? AppColors.greenLight : AppColors.redLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                (passed ? AppColors.green : AppColors.red).withValues(alpha: .2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              passed ? Icons.check_circle : Icons.cancel,
              size: 20,
              color: passed ? AppColors.green : AppColors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    requirement,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.ink3),
                  ),
                ],
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: passed ? AppColors.green : AppColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}