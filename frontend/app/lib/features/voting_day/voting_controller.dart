import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';

class VotingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> markVoted() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      ref.read(userProvider.notifier).markVoted();
    });
  }
}

final votingControllerProvider = AsyncNotifierProvider<VotingController, void>(
  VotingController.new,
);
