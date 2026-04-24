import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stats_model.dart';
import '../services/api_service.dart';

final statsProvider = FutureProvider<Stats>((ref) async {
  try {
    // Fetch stats from API
    final response = await ApiService.get('/api/stats');

    // Parse response and create Stats object
    final partyVotes = <String, int>{};
    if (response['partyVotes'] is Map) {
      (response['partyVotes'] as Map).forEach((key, value) {
        partyVotes[key.toString()] = value as int;
      });
    }

    final results = <CandidateResult>[];
    if (response['results'] is List) {
      results.addAll((response['results'] as List).map((r) => CandidateResult(
            name: r['name'] ?? '',
            party: r['party'] ?? '',
            votes: r['votes'] ?? 0,
            isWinner: r['isWinner'] ?? false,
            votePercent: (r['votePercent'] as num?)?.toDouble() ?? 0.0,
          )));
    }

    return Stats(
      totalVoters: response['totalVoters'] ?? 1000000,
      votedCount: response['votedCount'] ?? 750000,
      votedPercentage:
          (response['votedPercentage'] as num?)?.toDouble() ?? 75.0,
      partyVotes: partyVotes,
      turnoutPercent: (response['turnoutPercent'] as num?)?.toDouble() ?? 75.0,
      results: results,
    );
  } catch (e) {
    // Fallback to mock data if API fails
    return Stats(
      totalVoters: 1000000,
      votedCount: 750000,
      votedPercentage: 75.0,
      partyVotes: {
        'Party A': 350000,
        'Party B': 250000,
        'Party C': 150000,
      },
      turnoutPercent: 75.0,
      results: [
        const CandidateResult(
          name: 'Candidate A',
          party: 'Party A',
          votes: 350000,
          isWinner: true,
          votePercent: 46.67,
        ),
        const CandidateResult(
          name: 'Candidate B',
          party: 'Party B',
          votes: 250000,
          isWinner: false,
          votePercent: 33.33,
        ),
        const CandidateResult(
          name: 'Candidate C',
          party: 'Party C',
          votes: 150000,
          isWinner: false,
          votePercent: 20.0,
        ),
      ],
    );
  }
});
