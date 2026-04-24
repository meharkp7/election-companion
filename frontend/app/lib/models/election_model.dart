class Election {
  final String id;
  final String title;
  final String description;
  final DateTime electionDate;
  final DateTime resultDate;
  final List<ElectionPhase> phases;
  final bool isActive;

  const Election({
    required this.id,
    required this.title,
    required this.description,
    required this.electionDate,
    required this.resultDate,
    required this.phases,
    required this.isActive,
  });

  Election copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? electionDate,
    DateTime? resultDate,
    List<ElectionPhase>? phases,
    bool? isActive,
  }) {
    return Election(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      electionDate: electionDate ?? this.electionDate,
      resultDate: resultDate ?? this.resultDate,
      phases: phases ?? this.phases,
      isActive: isActive ?? this.isActive,
    );
  }
}

class ElectionPhase {
  final String id;
  final String name;
  final DateTime date;
  final List<String> states;

  const ElectionPhase({
    required this.id,
    required this.name,
    required this.date,
    required this.states,
  });

  ElectionPhase copyWith({
    String? id,
    String? name,
    DateTime? date,
    List<String>? states,
  }) {
    return ElectionPhase(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      states: states ?? this.states,
    );
  }
}