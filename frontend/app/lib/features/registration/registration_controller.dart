import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';

class RegistrationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Sends the user's registration status to the backend.
  /// [choice] must be one of: 'registered', 'not_registered', 'not_sure'.
  /// The backend determines the next screen — no local state assignment.
  Future<void> submitChoice(String choice) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(userProvider.notifier).submitRegistration(choice);
    });
  }
}

final registrationControllerProvider =
    AsyncNotifierProvider<RegistrationController, void>(
  RegistrationController.new,
);
