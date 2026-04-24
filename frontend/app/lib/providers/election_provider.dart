import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/election_model.dart';
import '../services/api_service.dart';

final electionProvider =
    NotifierProvider<ElectionNotifier, AsyncValue<Election>>(ElectionNotifier.new);

class ElectionNotifier extends Notifier<AsyncValue<Election>> {
  @override
  AsyncValue<Election> build() {
    _loadElectionData();
    return const AsyncValue.loading();
  }

  void _loadElectionData() {
    _fetchElectionData();
  }

  Future<void> _fetchElectionData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final response = await ApiService.get('/api/election/info');
        // Parse response and create Election object
        // This assumes the backend returns election data in the expected format
        final election = Election(
          id: response['id'] ?? '1',
          title: response['title'] ?? 'General Elections',
          description: response['description'] ?? '',
          electionDate:
              DateTime.parse(response['electionDate'] ?? '2024-05-20'),
          resultDate: DateTime.parse(response['resultDate'] ?? '2024-06-04'),
          phases: (response['phases'] as List?)
                  ?.map((p) => ElectionPhase(
                        id: p['id'] ?? '',
                        name: p['name'] ?? '',
                        date: DateTime.parse(p['date'] ?? '2024-04-19'),
                        states: List<String>.from(p['states'] ?? []),
                      ))
                  .toList() ??
              [],
          isActive: response['isActive'] ?? true,
        );
        return election;
      } catch (e) {
        // Fallback to mock data if API fails
        final election = Election(
          id: '1',
          title: 'General Elections 2024',
          description: 'Lok Sabha General Elections',
          electionDate: DateTime(2024, 5, 20),
          resultDate: DateTime(2024, 6, 4),
          phases: [
            ElectionPhase(
              id: '1',
              name: 'Phase 1',
              date: DateTime(2024, 4, 19),
              states: ['Tamil Nadu', 'Uttar Pradesh', 'West Bengal'],
            ),
            ElectionPhase(
              id: '2',
              name: 'Phase 2',
              date: DateTime(2024, 4, 26),
              states: ['Kerala', 'Karnataka', 'Rajasthan'],
            ),
          ],
          isActive: true,
        );
        return election;
      }
    });
  }

  void updateElection(Election election) {
    state = AsyncValue.data(election);
  }

  void setElectionStatus(bool isActive) {
    state.whenData((election) {
      state = AsyncValue.data(election.copyWith(isActive: isActive));
    });
  }
}
