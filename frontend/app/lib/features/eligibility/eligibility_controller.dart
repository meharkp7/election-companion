import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';

class EligibilityController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Advances past eligibility to the next state.
  /// The backend determines the next screen — no local logic.
  Future<void> continueToNext() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(userProvider.notifier).advance();
    });
  }
}

final eligibilityControllerProvider =
    AsyncNotifierProvider<EligibilityController, void>(
  EligibilityController.new,
);
