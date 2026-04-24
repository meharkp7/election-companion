class StateInfo {
  final String name;
  final String code;
  final String capital;
  final int totalConstituencies;
  final DateTime electionDate;
  final String chiefMinister;
  final String governor;
  final int population;
  final String area;
  final double literacyRate;
  final int votingBooths;

  const StateInfo({
    required this.name,
    required this.code,
    required this.capital,
    required this.totalConstituencies,
    required this.electionDate,
    required this.chiefMinister,
    required this.governor,
    required this.population,
    required this.area,
    required this.literacyRate,
    required this.votingBooths,
  });

  StateInfo copyWith({
    String? name,
    String? code,
    String? capital,
    int? totalConstituencies,
    DateTime? electionDate,
    String? chiefMinister,
    String? governor,
    int? population,
    String? area,
    double? literacyRate,
    int? votingBooths,
  }) {
    return StateInfo(
      name: name ?? this.name,
      code: code ?? this.code,
      capital: capital ?? this.capital,
      totalConstituencies: totalConstituencies ?? this.totalConstituencies,
      electionDate: electionDate ?? this.electionDate,
      chiefMinister: chiefMinister ?? this.chiefMinister,
      governor: governor ?? this.governor,
      population: population ?? this.population,
      area: area ?? this.area,
      literacyRate: literacyRate ?? this.literacyRate,
      votingBooths: votingBooths ?? this.votingBooths,
    );
  }
}