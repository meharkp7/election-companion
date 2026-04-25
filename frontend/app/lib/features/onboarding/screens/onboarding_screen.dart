import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/components/primary_button.dart';
import '../../../providers/user_provider.dart';
import '../onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageCtrl = TextEditingController();
  String? _selectedState;
  bool _isFirstTime = false;

  // Focus nodes — explicit order ensures TalkBack/VoiceOver traverse
  // fields top-to-bottom instead of picking an arbitrary tree order.
  final _ageFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _submitFocus = FocusNode();

  static const _indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  @override
  void dispose() {
    _ageCtrl.dispose();
    _ageFocus.dispose();
    _stateFocus.dispose();
    _submitFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final age = int.parse(_ageCtrl.text.trim());
    await ref.read(onboardingControllerProvider.notifier).submit(
          age: age,
          userState: _selectedState!,
          isFirstTimeVoter: _isFirstTime,
        );
    // No context.go() — AssistantShell reacts to user.currentScreen
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(onboardingControllerProvider);
    final userAsync = ref.watch(userProvider);

    final ui = userAsync.value?.latestUI;
    final title = ui?.title ?? 'VoteReady';
    final prompt = ui?.prompt ?? AppStrings.tagline;
    final inputs = ui?.inputs ?? ['age', 'state', 'isFirstTimeVoter'];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: FocusTraversalGroup(
              // Enforces top-to-bottom tab/swipe order for assistive tech
              policy: OrderedTraversalPolicy(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // ── Logo (screen-reader reads as one label) ────────────
                  Semantics(
                    header: true,
                    label: '$title — election companion app',
                    excludeSemantics: true, // children are decorative
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        children: [
                          TextSpan(
                              text:
                                  '${title.replaceAll('Ready', '').replaceAll('!', '').replaceAll('🗳️', '').trim()} '),
                          TextSpan(
                            text: title.contains('Ready') ? 'Ready' : '',
                            style: const TextStyle(color: AppColors.orange),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Tagline ────────────────────────────────────────────
                  Text(
                    prompt,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),

                  // ── Trust badge ────────────────────────────────────────
                  Semantics(
                    label: 'Trusted — ${AppStrings.trustBadge}',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.green.withValues(alpha: .2),
                          width: 0.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_outlined,
                              size: 14, color: AppColors.green),
                          SizedBox(width: 6),
                          Text(
                            AppStrings.trustBadge,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Age field ──────────────────────────────────────────
                  if (inputs.contains('age')) ...[
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(1),
                      child: Semantics(
                        label: '${AppStrings.ageLabel}, required',
                        hint: 'Enter your age in years',
                        textField: true,
                        child: TextFormField(
                          controller: _ageCtrl,
                          focusNode: _ageFocus,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _stateFocus.requestFocus(),
                          decoration: InputDecoration(
                            labelText: AppStrings.ageLabel,
                            hintText: AppStrings.ageHint,
                          ),
                          validator: AppValidators.validateAge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── State dropdown ─────────────────────────────────────
                  if (inputs.contains('state')) ...[
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(2),
                      child: Semantics(
                        label: '${AppStrings.stateLabel}, required',
                        hint:
                            'Choose the state where you are registered to vote',
                        child: DropdownButtonFormField<String>(
                          focusNode: _stateFocus,
                          initialValue: _selectedState,
                          decoration: InputDecoration(
                            labelText: AppStrings.stateLabel,
                            hintText: AppStrings.stateHint,
                          ),
                          items: _indianStates
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedState = v),
                          validator: AppValidators.validateState,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── First-time voter toggle ────────────────────────────
                  if (inputs.contains('isFirstTimeVoter')) ...[
                    Semantics(
                      label: AppStrings.firstTimeVoter,
                      hint: _isFirstTime
                          ? 'Currently on. Tap to turn off'
                          : 'Currently off. Tap to turn on',
                      toggled: _isFirstTime,
                      excludeSemantics: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppStrings.firstTimeVoter,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            Switch(
                              value: _isFirstTime,
                              onChanged: (v) =>
                                  setState(() => _isFirstTime = v),
                              activeThumbColor: AppColors.orange,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],

                  // ── Submit button ──────────────────────────────────────
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(3),
                    child: Focus(
                      focusNode: _submitFocus,
                      child: Semantics(
                        button: true,
                        enabled: !controllerState.isLoading,
                        label: controllerState.isLoading
                            ? 'Submitting, please wait'
                            : AppStrings.letsStart,
                        child: PrimaryButton(
                          label: AppStrings.letsStart,
                          isLoading: controllerState.isLoading,
                          onPressed: _submit,
                        ),
                      ),
                    ),
                  ),

                  // ── Error — live region so TalkBack announces it ───────
                  if (controllerState.hasError) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      label: 'Error: ${controllerState.error}',
                      child: Center(
                        child: Text(
                          controllerState.error.toString(),
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ── Footer note ────────────────────────────────────────
                  Semantics(
                    label:
                        'No political bias. Data sourced from the Election Commission of India.',
                    child: Center(
                      child: Text(
                        'No political bias · Data from Election Commission',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
