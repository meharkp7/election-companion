import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';

class OnboardingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Sends onboarding data to the backend via the user provider.
  ///
  /// No local navigation — the [AssistantShell] will react to the
  /// updated `currentScreen` and render the next screen automatically.
  /// If the backend rejects (e.g. age < 18 → stays at START), we throw
  /// so the screen can display an error.
  Future<void> submit({
    required int age,
    required String userState,
    required bool isFirstTimeVoter,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await ref.read(userProvider.notifier).onboard(
            age: age,
            userState: userState,
            isFirstTimeVoter: isFirstTimeVoter,
          );
      // If the backend kept us at START, it rejected the input
      if (response.currentState == 'START') {
        throw Exception(
          'Unable to proceed. Please ensure you meet all eligibility requirements.',
        );
      }
    });
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, void>(OnboardingController.new);
