class ElectionPhase {
  final String id;
  final int electionYear;
  final String electionType;
  final String? state;
  final int phaseNumber;
  final DateTime pollingDate;
  final DateTime countingDate;
  final int totalSeats;
  final String status;
  final DateTime? createdAt;

  ElectionPhase({
    required this.id,
    required this.electionYear,
    required this.electionType,
    this.state,
    required this.phaseNumber,
    required this.pollingDate,
    required this.countingDate,
    required this.totalSeats,
    required this.status,
    this.createdAt,
  });

  factory ElectionPhase.fromJson(Map<String, dynamic> json) {
    return ElectionPhase(
      id: json['id'] ?? '',
      electionYear: json['electionYear'] ?? 0,
      electionType: json['electionType'] ?? '',
      state: json['state'],
      phaseNumber: json['phaseNumber'] ?? 0,
      pollingDate: DateTime.parse(json['pollingDate']),
      countingDate: DateTime.parse(json['countingDate']),
      totalSeats: json['totalSeats'] ?? 0,
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'electionYear': electionYear,
      'electionType': electionType,
      'state': state,
      'phaseNumber': phaseNumber,
      'pollingDate': pollingDate.toIso8601String(),
      'countingDate': countingDate.toIso8601String(),
      'totalSeats': totalSeats,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  String get formattedPollingDate {
    return '${pollingDate.day}/${pollingDate.month}/${pollingDate.year}';
  }

  String get formattedCountingDate {
    return '${countingDate.day}/${countingDate.month}/${countingDate.year}';
  }

  bool get isUpcoming => pollingDate.isAfter(DateTime.now());
  bool get isCompleted => status == 'completed';
  bool get isOngoing => status == 'ongoing';

  int get daysUntilPolling {
    return pollingDate.difference(DateTime.now()).inDays;
  }
}
