import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/state_model.dart';

final stateProvider =
    NotifierProvider<StateInfoNotifier, AsyncValue<StateInfo>>(StateInfoNotifier.new);

class StateInfoNotifier extends Notifier<AsyncValue<StateInfo>> {
  @override
  AsyncValue<StateInfo> build() {
    _loadStateData();
    return const AsyncValue.loading();
  }

  void _loadStateData() {
    // Mock state data for now
    final stateInfo = StateInfo(
      name: 'Maharashtra',
      code: 'MH',
      capital: 'Mumbai',
      totalConstituencies: 48,
      electionDate: DateTime(2024, 5, 20),
      chiefMinister: 'Eknath Shinde',
      governor: 'Ramesh Bais',
      population: 112374333,
      area: '307713 km²',
      literacyRate: 82.3,
      votingBooths: 96234,
    );
    state = AsyncValue.data(stateInfo);
  }

  void updateState(StateInfo stateInfo) {
    state = AsyncValue.data(stateInfo);
  }

  void updateElectionDate(DateTime date) {
    state.whenData((stateInfo) {
      state = AsyncValue.data(stateInfo.copyWith(electionDate: date));
    });
  }
}