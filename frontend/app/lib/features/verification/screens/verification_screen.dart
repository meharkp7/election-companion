import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/step_card.dart';
import '../../../shared/components/loaders.dart';
import '../../../shared/components/secondary_button.dart';
import '../../../shared/components/not_sure_button.dart';
import '../verification_controller.dart';
import '../widgets/digilocker_verification_widget.dart';

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final controllerState = ref.watch(verificationControllerProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: AppLoader()),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (user) {
        // Use backend-provided UI data for dynamic content
        final ui = user.latestUI;
        final title = ui?.title ?? AppStrings.verificationTitle;
        final prompt = ui?.prompt ?? 'Is your name correctly listed?';

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: Text(title),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Status banner — pending since the user hasn't verified yet
                  // (after verification, backend transitions to next state and
                  //  the shell shows a different screen)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.amberLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: .2),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pending_outlined,
                          color: AppColors.amber,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            prompt,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Steps to verify
                  const SectionLabel('How to verify'),
                  const _VerifyStep(
                    number: '1',
                    title: 'Visit voters.eci.gov.in',
                    subtitle: 'Official Election Commission portal',
                  ),
                  const SizedBox(height: 8),
                  const _VerifyStep(
                    number: '2',
                    title: 'Search by EPIC number or name',
                    subtitle: 'Use your voter ID or enter name + state',
                  ),
                  const SizedBox(height: 8),
                  const _VerifyStep(
                    number: '3',
                    title: 'Confirm your details',
                    subtitle: 'Name, address, booth number',
                  ),
                  const SizedBox(height: 28),

                  // EPIC helper
                  InfoCard(
                    title: 'What is EPIC?',
                    subtitle:
                        'Electors Photo Identity Card number — printed on your Voter ID',
                    bgColor: AppColors.blueLight,
                    borderColor: AppColors.blue.withValues(alpha: .15),
                  ),
                  const SizedBox(height: 28),

                  // DigiLocker verification option
                  DigiLockerVerificationWidget(
                    onVerified: () {
                      // Update verification status through the controller
                      ref.read(verificationControllerProvider.notifier).confirmVerified();
                    },
                  ),
                  const SizedBox(height: 28),

                  const SectionLabel('After checking'),

                  // Name found — tells backend verification succeeded
                  SecondaryButton(
                    label: AppStrings.nameFound,
                    onPressed: controllerState.isLoading
                        ? () {}
                        : () => ref
                            .read(verificationControllerProvider.notifier)
                            .confirmVerified(),
                  ),
                  const SizedBox(height: 12),

                  // Name not found — tells backend to go to issue resolver
                  SecondaryButton(
                    label: AppStrings.nameNotFound,
                    onPressed: controllerState.isLoading
                        ? () {}
                        : () => ref
                            .read(verificationControllerProvider.notifier)
                            .reportIssue(),
                  ),
                  const SizedBox(height: 12),

                  NotSureButton(
                    label: 'Not Sure',
                    onPressed: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Visit voters.eci.gov.in to check your name',
                        ),
                      ),
                    ),
                  ),

                  if (controllerState.isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],

                  if (controllerState.hasError) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        controllerState.error.toString(),
                        style:
                            const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
}

class _VerifyStep extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const _VerifyStep({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $number: $title. $subtitle',
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.orangeLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.orange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
    ), // Semantics
    );
  }
}
