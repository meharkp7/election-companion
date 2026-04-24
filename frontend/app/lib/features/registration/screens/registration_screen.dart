import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/enums.dart';
import '../../../core/utils/state_order.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/step_card.dart';
import '../../../shared/widgets/step_progress_card.dart';
import '../../../shared/widgets/readiness_score_card.dart';
import '../../../shared/components/loaders.dart';
import '../../../shared/components/error_view.dart';
import '../registration_controller.dart';

class RegistrationScreen extends ConsumerWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: AppLoader()),
      error: (e, _) =>
          const Scaffold(body: ErrorView(message: AppStrings.errorGeneric)),
      data: (user) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // App bar
                SliverAppBar(
                  pinned: true,
                  title: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      children: [
                        TextSpan(text: 'Vote'),
                        TextSpan(
                          text: 'Ready',
                          style: TextStyle(color: AppColors.orange),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppColors.border, width: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        AppStrings.trustBadge,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.ink3,
                        ),
                      ),
                    ),
                  ],
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Score
                      ReadinessScoreCard(score: user.readinessScore),
                      const SizedBox(height: 24),

                      // Current step panel — shown when backend state is REGISTRATION
                      if (user.currentState == 'REGISTRATION' ||
                          user.currentState == 'START') ...[
                        const SectionLabel('Current Step'),
                        _RegistrationPanel(user.isFirstTimeVoter, user.latestUI?.options ?? []),
                        const SizedBox(height: 24),
                      ],

                      // Journey
                      const SectionLabel('Your Journey'),
                      StepProgressCard(
                        title: 'Eligibility',
                        subtitle: 'Age ${user.age} · ${user.state} · Citizen',
                        // Always done if user reached this screen
                        status: StepStatus.done,
                      ),
                      const SizedBox(height: 10),
                      StepProgressCard(
                        title: 'Registration',
                        subtitle: 'Form 6 guide available',
                        status: StateOrder.isPast(
                                user.currentState, 'REGISTRATION')
                            ? StepStatus.done
                            : StepStatus.active,
                      ),
                      const SizedBox(height: 10),
                      StepProgressCard(
                        title: 'Verification',
                        subtitle: 'Check electoral roll',
                        status: StateOrder.isPast(
                                user.currentState, 'VERIFICATION')
                            ? StepStatus.done
                            : StateOrder.isAtOrPast(
                                    user.currentState, 'VERIFICATION')
                                ? StepStatus.active
                                : StepStatus.locked,
                      ),
                      const SizedBox(height: 10),
                      StepProgressCard(
                        title: 'Voting Day',
                        subtitle: 'Step-by-step guide',
                        status: StateOrder.isAtOrPast(
                                user.currentState, 'VOTING_DAY')
                            ? StepStatus.active
                            : StepStatus.locked,
                      ),
                      const SizedBox(height: 24),

                      // Document helper
                      const SectionLabel('Document Helper'),
                      _DocumentHelper(isFirstTime: user.isFirstTimeVoter),
                      const SizedBox(height: 24),

                      // Booth card
                      const SectionLabel('Polling Booth'),
                      _BoothCard(
                        name: user.boothName,
                        address: user.boothAddress,
                      ),
                      const SizedBox(height: 24),

                      // Issue resolver — pushes auxiliary route
                      const SectionLabel('Need Help?'),
                      _IssueStrip(
                        icon: Icons.warning_amber_outlined,
                        label: AppStrings.issueNameMissing,
                        onTap: () => context.push(
                          AppRoutes.issueResolver,
                          extra: 'nameMissing',
                        ),
                      ),
                      const SizedBox(height: 8),
                      _IssueStrip(
                        icon: Icons.edit_note,
                        label: AppStrings.issueWrongDetails,
                        onTap: () => context.push(
                          AppRoutes.issueResolver,
                          extra: 'wrongDetails',
                        ),
                      ),
                      const SizedBox(height: 8),
                      _IssueStrip(
                        icon: Icons.location_city_outlined,
                        label: AppStrings.issueBoothProblem,
                        onTap: () => context.push(
                          AppRoutes.issueResolver,
                          extra: 'boothIssue',
                        ),
                      ),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Registration options panel ─────────────────────────
class _RegistrationPanel extends ConsumerWidget {
  final bool isFirstTime;
  final List<String> options;
  const _RegistrationPanel(this.isFirstTime, this.options);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerState = ref.watch(registrationControllerProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orangeLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.orange.withOpacity(.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Registration',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              if (controllerState.isLoading) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          // Options call sendStep via the controller — backend decides which options to show
          ...options.map((option) {
            String label = option;
            String subtitle = '';
            IconData icon = Icons.arrow_forward_ios;
            bool isDashed = false;

            if (option == 'not_registered') {
              label = AppStrings.notRegistered;
              subtitle = 'I need to fill Form 6';
            } else if (option == 'registered') {
              label = AppStrings.alreadyRegistered;
              subtitle = 'Take me to verification';
            } else if (option == 'not_sure') {
              label = AppStrings.notSure;
              isDashed = true;
              icon = Icons.help_outline;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: StepOptionCard(
                label: label,
                subtitle: subtitle,
                icon: icon,
                isDashed: isDashed,
                onTap: controllerState.isLoading
                    ? () {}
                    : () => ref
                        .read(registrationControllerProvider.notifier)
                        .submitChoice(option),
              ),
            );
          }),
          
          if (controllerState.hasError) ...[
            const SizedBox(height: 8),
            Text(
              controllerState.error.toString(),
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Document Helper ────────────────────────────────────
class _DocumentHelper extends StatelessWidget {
  final bool isFirstTime;
  const _DocumentHelper({required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.blue.withOpacity(.15), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Documents for Form 6',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          const _DocItem(
            name: AppStrings.aadhaar,
            confirmed: true,
            altText: 'Primary ID',
          ),
          const _DocItem(
            name: AppStrings.passportPhoto,
            confirmed: false,
            altText: 'Not confirmed',
          ),
          _DocItem(
            name: AppStrings.addressProof,
            confirmed: false,
            altText: 'No utility bill?',
            altColor: AppColors.blue,
            onAltTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.addressAlternative)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocItem extends StatelessWidget {
  final String name;
  final bool confirmed;
  final String altText;
  final Color? altColor;
  final VoidCallback? onAltTap;

  const _DocItem({
    required this.name,
    required this.confirmed,
    required this.altText,
    this.altColor,
    this.onAltTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: confirmed ? AppColors.greenLight : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: confirmed
                    ? AppColors.green.withOpacity(.3)
                    : AppColors.border,
                width: 0.5,
              ),
            ),
            child: confirmed
                ? const Icon(Icons.check, size: 12, color: AppColors.green)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
            ),
          ),
          GestureDetector(
            onTap: onAltTap,
            child: Text(
              altText,
              style: TextStyle(
                fontSize: 11,
                color: altColor ?? AppColors.ink3,
                fontWeight:
                    altColor != null ? FontWeight.w500 : FontWeight.w400,
                decoration: altColor != null ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Booth Card ─────────────────────────────────────────
class _BoothCard extends StatelessWidget {
  final String? name;
  final String? address;
  const _BoothCard({this.name, this.address});

  @override
  Widget build(BuildContext context) {
    final hasData = name != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.green.withOpacity(.15), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.green,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasData ? name! : AppStrings.boothNotSet,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  hasData ? address! : AppStrings.setBoothManually,
                  style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                ),
              ],
            ),
          ),
          if (hasData)
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Maps', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

// ── Issue Strip ────────────────────────────────────────
class _IssueStrip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _IssueStrip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.amberLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: AppColors.amber),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppColors.ink),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.ink3),
          ],
        ),
      ),
    );
  }
}
