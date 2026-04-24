class PollingChecklist {
  final String id;
  final bool documentsReady;
  final bool voterIdChecked;
  final bool transportPlanned;
  final bool companionAvailable;
  final bool documentsPhotographed;
  final bool offlineModeTested;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PollingChecklist({
    required this.id,
    this.documentsReady = false,
    this.voterIdChecked = false,
    this.transportPlanned = false,
    this.companionAvailable = false,
    this.documentsPhotographed = false,
    this.offlineModeTested = false,
    this.createdAt,
    this.updatedAt,
  });

  factory PollingChecklist.fromJson(Map<String, dynamic> json) {
    return PollingChecklist(
      id: json['id'] ?? '',
      documentsReady: json['documentsReady'] ?? false,
      voterIdChecked: json['voterIdChecked'] ?? false,
      transportPlanned: json['transportPlanned'] ?? false,
      companionAvailable: json['CompanionAvailable'] ?? false,
      documentsPhotographed: json['documentsPhotographed'] ?? false,
      offlineModeTested: json['offlineModeTested'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentsReady': documentsReady,
      'voterIdChecked': voterIdChecked,
      'transportPlanned': transportPlanned,
      'CompanionAvailable': companionAvailable,
      'documentsPhotographed': documentsPhotographed,
      'offlineModeTested': offlineModeTested,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  int get completionPercentage {
    final items = [
      documentsReady,
      voterIdChecked,
      transportPlanned,
      companionAvailable,
      documentsPhotographed,
      offlineModeTested,
    ];
    final completed = items.where((item) => item).length;
    return ((completed / items.length) * 100).round();
  }
}
