import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OnboardingStep {
  welcome,
  features,
  permissions,
  accountSetup,
  tutorial,
  completed,
}

class OnboardingData {
  final bool hasCompletedOnboarding;
  final OnboardingStep? currentStep;
  final DateTime? lastCompletedDate;
  final Map<String, bool> completedFeatures;
  final int tutorialAttempts;

  const OnboardingData({
    required this.hasCompletedOnboarding,
    this.currentStep,
    this.lastCompletedDate,
    this.completedFeatures = const {},
    this.tutorialAttempts = 0,
  });

  OnboardingData copyWith({
    bool? hasCompletedOnboarding,
    OnboardingStep? currentStep,
    DateTime? lastCompletedDate,
    Map<String, bool>? completedFeatures,
    int? tutorialAttempts,
  }) {
    return OnboardingData(
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      currentStep: currentStep ?? this.currentStep,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      completedFeatures: completedFeatures ?? this.completedFeatures,
      tutorialAttempts: tutorialAttempts ?? this.tutorialAttempts,
    );
  }
}

class TutorialStep {
  final String id;
  final String title;
  final String description;
  final Widget? content;
  final String? targetWidgetKey;
  final Duration? duration;
  final bool isRequired;
  final bool canSkip;

  const TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    this.content,
    this.targetWidgetKey,
    this.duration,
    this.isRequired = true,
    this.canSkip = false,
  });
}

class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  OnboardingData _onboardingData = const OnboardingData(hasCompletedOnboarding: false);
  final List<TutorialStep> _tutorialSteps = [];

  Future<void> initialize() async {
    await _loadOnboardingData();
    _setupTutorialSteps();
  }

  Future<void> _loadOnboardingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompleted = prefs.getBool('onboarding_completed') ?? false;
      final currentStepIndex = prefs.getInt('onboarding_current_step') ?? 0;
      final lastCompleted = prefs.getString('onboarding_last_completed');
      final tutorialAttempts = prefs.getInt('tutorial_attempts') ?? 0;

      final completedFeatures = <String, bool>{};
      final featureKeys = prefs.getKeys().where((key) => key.startsWith('feature_'));
      for (final key in featureKeys) {
        final featureName = key.replaceFirst('feature_', '');
        completedFeatures[featureName] = prefs.getBool(key) ?? false;
      }

      _onboardingData = OnboardingData(
        hasCompletedOnboarding: hasCompleted,
        currentStep: OnboardingStep.values[currentStepIndex],
        lastCompletedDate: lastCompleted != null ? DateTime.parse(lastCompleted) : null,
        completedFeatures: completedFeatures,
        tutorialAttempts: tutorialAttempts,
      );
    } catch (e) {
      debugPrint('Failed to load onboarding data: $e');
    }
  }

  void _setupTutorialSteps() {
    _tutorialSteps.addAll([
      const TutorialStep(
        id: 'welcome',
        title: 'Welcome to VoteReady',
        description: 'Your complete election companion app. Let\'s get you started!',
        isRequired: true,
        canSkip: false,
      ),
      const TutorialStep(
        id: 'dashboard',
        title: 'Dashboard Overview',
        description: 'This is your main dashboard where you can see all election information at a glance.',
        targetWidgetKey: 'dashboard_key',
        isRequired: true,
        canSkip: false,
      ),
      const TutorialStep(
        id: 'eligibility',
        title: 'Check Eligibility',
        description: 'Find out if you\'re eligible to vote and what documents you need.',
        targetWidgetKey: 'eligibility_key',
        isRequired: true,
        canSkip: false,
      ),
      const TutorialStep(
        id: 'registration',
        title: 'Voter Registration',
        description: 'Register to vote or check your registration status online.',
        targetWidgetKey: 'registration_key',
        isRequired: true,
        canSkip: false,
      ),
      const TutorialStep(
        id: 'verification',
        title: 'Verify Your Details',
        description: 'Check if your name is on the voter list and verify your details.',
        targetWidgetKey: 'verification_key',
        isRequired: true,
        canSkip: false,
      ),
      const TutorialStep(
        id: 'voting_day',
        title: 'Voting Day Guide',
        description: 'Everything you need to know on voting day - locations, timing, and process.',
        targetWidgetKey: 'voting_day_key',
        isRequired: true,
        canSkip: false,
      ),
      const TutorialStep(
        id: 'results',
        title: 'Election Results',
        description: 'Track real-time election results and statistics.',
        targetWidgetKey: 'results_key',
        isRequired: false,
        canSkip: true,
      ),
      const TutorialStep(
        id: 'settings',
        title: 'Settings & Preferences',
        description: 'Customize your app experience and manage your account.',
        targetWidgetKey: 'settings_key',
        isRequired: false,
        canSkip: true,
      ),
    ]);
  }

  OnboardingData get onboardingData => _onboardingData;

  List<TutorialStep> get tutorialSteps => _tutorialSteps;

  bool shouldShowOnboarding() {
    return !_onboardingData.hasCompletedOnboarding;
  }

  Future<void> setCurrentStep(OnboardingStep step) async {
    _onboardingData = _onboardingData.copyWith(currentStep: step);
    await _saveOnboardingData();
  }

  Future<void> completeOnboarding() async {
    _onboardingData = _onboardingData.copyWith(
      hasCompletedOnboarding: true,
      currentStep: OnboardingStep.completed,
      lastCompletedDate: DateTime.now(),
    );
    await _saveOnboardingData();
  }

  Future<void> markFeatureCompleted(String featureName) async {
    final updatedFeatures = Map<String, bool>.from(_onboardingData.completedFeatures);
    updatedFeatures[featureName] = true;
    
    _onboardingData = _onboardingData.copyWith(completedFeatures: updatedFeatures);
    await _saveOnboardingData();
  }

  Future<void> resetOnboarding() async {
    _onboardingData = const OnboardingData(hasCompletedOnboarding: false);
    await _saveOnboardingData();
  }

  Future<void> _saveOnboardingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('onboarding_completed', _onboardingData.hasCompletedOnboarding);
      await prefs.setInt('onboarding_current_step', _onboardingData.currentStep?.index ?? 0);
      
      if (_onboardingData.lastCompletedDate != null) {
        await prefs.setString('onboarding_last_completed', _onboardingData.lastCompletedDate!.toIso8601String());
      }
      
      await prefs.setInt('tutorial_attempts', _onboardingData.tutorialAttempts);
      
      for (final entry in _onboardingData.completedFeatures.entries) {
        await prefs.setBool('feature_${entry.key}', entry.value);
      }
    } catch (e) {
      debugPrint('Failed to save onboarding data: $e');
    }
  }

  Future<void> incrementTutorialAttempts() async {
    _onboardingData = _onboardingData.copyWith(
      tutorialAttempts: _onboardingData.tutorialAttempts + 1,
    );
    await _saveOnboardingData();
  }

  bool hasCompletedFeature(String featureName) {
    return _onboardingData.completedFeatures[featureName] ?? false;
  }
}

// Tutorial overlay widget
class TutorialOverlay extends StatefulWidget {
  final TutorialStep step;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final VoidCallback? onClose;

  const TutorialOverlay({
    super.key,
    required this.step,
    this.onNext,
    this.onSkip,
    this.onClose,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.all(24.0),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10.0,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.step.content != null) ...[
                        widget.step.content!,
                        const SizedBox(height: 16.0),
                      ],
                      Text(
                        widget.step.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        widget.step.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.step.canSkip)
                            TextButton(
                              onPressed: widget.onSkip,
                              child: const Text('Skip'),
                            ),
                          if (!widget.step.canSkip) const SizedBox(width: 50),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: widget.onNext,
                                child: const Text('Next'),
                              ),
                              if (widget.onClose != null) ...[
                                const SizedBox(width: 12.0),
                                IconButton(
                                  onPressed: widget.onClose,
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Onboarding screen widget
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late OnboardingService _onboardingService;
  late PageController _pageController;
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _onboardingService = OnboardingService();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentStepIndex = index;
            });
          },
          itemCount: _onboardingService.tutorialSteps.length,
          itemBuilder: (context, index) {
            final step = _onboardingService.tutorialSteps[index];
            return _buildOnboardingPage(step, index);
          },
        ),
      ),
      bottomSheet: _buildBottomSheet(),
    );
  }

  Widget _buildOnboardingPage(TutorialStep step, int index) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (step.content != null) ...[
            step.content!,
            const SizedBox(height: 32.0),
          ],
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _onboardingService.tutorialSteps.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                height: 8.0,
                width: i == _currentStepIndex ? 24.0 : 8.0,
                decoration: BoxDecoration(
                  color: i == _currentStepIndex
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    final isLastStep = _currentStepIndex == _onboardingService.tutorialSteps.length - 1;
    final currentStep = _onboardingService.tutorialSteps[_currentStepIndex];

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentStep.canSkip && !isLastStep)
            TextButton(
              onPressed: () {
                if (_currentStepIndex < _onboardingService.tutorialSteps.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: const Text('Skip'),
            ),
          if (!currentStep.canSkip && !isLastStep) const SizedBox(width: 50),
          Row(
            children: [
              if (_currentStepIndex > 0)
                TextButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Previous'),
                ),
              const SizedBox(width: 16.0),
              ElevatedButton(
                onPressed: () async {
                  if (isLastStep) {
                    await _onboardingService.completeOnboarding();
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Text(isLastStep ? 'Get Started' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Onboarding provider for Riverpod
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

final onboardingDataProvider = FutureProvider<OnboardingData>((ref) async {
  final service = ref.watch(onboardingServiceProvider);
  await service.initialize();
  return service.onboardingData;
});
