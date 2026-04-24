class ElectionResult {
  final String id;
  final String state;
  final String constituency;
  final String status;
  final String? winningCandidate;
  final String? winningParty;
  final double? winningMargin;
  final double? winningMarginPercentage;
  final int? registeredVoters;
  final int? votesPolled;
  final double? turnoutPercentage;
  final int? rejectedVotes;
  final DateTime? lastUpdated;
  final List<CandidateResult> candidates;

  ElectionResult({
    required this.id,
    required this.state,
    required this.constituency,
    required this.status,
    this.winningCandidate,
    this.winningParty,
    this.winningMargin,
    this.winningMarginPercentage,
    this.registeredVoters,
    this.votesPolled,
    this.turnoutPercentage,
    this.rejectedVotes,
    this.lastUpdated,
    this.candidates = const [],
  });

  factory ElectionResult.fromJson(Map<String, dynamic> json) {
    return ElectionResult(
      id: json['id'] ?? '',
      state: json['state'] ?? '',
      constituency: json['constituency'] ?? '',
      status: json['status'] ?? '',
      winningCandidate: json['winner']?['name'],
      winningParty: json['winner']?['party'],
      winningMargin: json['winner']?['margin']?.toDouble(),
      winningMarginPercentage: json['winner']?['marginPercentage']?.toDouble(),
      registeredVoters: json['turnout']?['registeredVoters'],
      votesPolled: json['turnout']?['votesPolled'],
      turnoutPercentage: json['turnout']?['percentage']?.toDouble(),
      rejectedVotes: json['turnout']?['rejectedVotes'],
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated']) : null,
      candidates: (json['candidates'] as List<dynamic>? ?? [])
          .map((c) => CandidateResult.fromJson(c))
          .toList(),
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isCounting => status == 'counting';

  String get formattedTurnout {
    if (turnoutPercentage == null) return 'N/A';
    return '${turnoutPercentage!.toStringAsFixed(1)}%';
  }
}

class CandidateResult {
  final String? id;
  final String name;
  final String party;
  final int? votesReceived;
  final double? voteSharePercentage;
  final int position;
  final String? status;

  CandidateResult({
    this.id,
    required this.name,
    required this.party,
    this.votesReceived,
    this.voteSharePercentage,
    required this.position,
    this.status,
  });

  factory CandidateResult.fromJson(Map<String, dynamic> json) {
    return CandidateResult(
      id: json['id'],
      name: json['name'] ?? '',
      party: json['party'] ?? '',
      votesReceived: json['votesReceived'],
      voteSharePercentage: json['voteSharePercentage']?.toDouble(),
      position: json['position'] ?? 0,
      status: json['status'],
    );
  }

  bool get isWinner => status == 'won' || position == 1;
  bool get isLeading => status == 'leading';
}
