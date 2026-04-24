class Stats {
  final int totalVoters;
  final int votedCount;
  final double votedPercentage;
  final Map<String, int> partyVotes;
  final String constituencyName;
  final double turnoutPercent;
  final List<CandidateResult> results;

  const Stats({
    required this.totalVoters,
    required this.votedCount,
    required this.votedPercentage,
    required this.partyVotes,
    this.constituencyName = 'Default Constituency',
    this.turnoutPercent = 0.0,
    this.results = const [],
  });
}

class CandidateResult {
  final String name;
  final String party;
  final int votes;
  final bool isWinner;
  final double votePercent;

  const CandidateResult({
    required this.name,
    required this.party,
    required this.votes,
    this.isWinner = false,
    this.votePercent = 0.0,
  });
}

class GlobalInsights {
  final String title;
  final String description;
  final List<InsightData> data;
  final List<GlobalInsightItem> items;

  const GlobalInsights({
    required this.title,
    required this.description,
    required this.data,
    this.items = const [],
  });

  bool get isEmpty => items.isEmpty;
}

class GlobalInsightItem {
  final String flag;
  final String country;
  final double turnout;
  final int year;

  const GlobalInsightItem({
    required this.flag,
    required this.country,
    required this.turnout,
    required this.year,
  });
}

class InsightData {
  final String label;
  final double value;

  const InsightData({
    required this.label,
    required this.value,
  });
}
