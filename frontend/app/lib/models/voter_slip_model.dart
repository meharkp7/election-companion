class VoterSlip {
  final String id;
  final String? epicNumber;
  final String? voterName;
  final String? boothName;
  final String? boothAddress;
  final String? pollingDate;
  final String? serialNumber;
  final String? partNumber;
  final List<String> photos;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VoterSlip({
    required this.id,
    this.epicNumber,
    this.voterName,
    this.boothName,
    this.boothAddress,
    this.pollingDate,
    this.serialNumber,
    this.partNumber,
    this.photos = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory VoterSlip.fromJson(Map<String, dynamic> json) {
    return VoterSlip(
      id: json['id'] ?? '',
      epicNumber: json['epicNumber'],
      voterName: json['voterName'],
      boothName: json['boothName'],
      boothAddress: json['boothAddress'],
      pollingDate: json['pollingDate'],
      serialNumber: json['serialNumber'],
      partNumber: json['partNumber'],
      photos: List<String>.from(json['photos'] ?? []),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'epicNumber': epicNumber,
      'voterName': voterName,
      'boothName': boothName,
      'boothAddress': boothAddress,
      'pollingDate': pollingDate,
      'serialNumber': serialNumber,
      'partNumber': partNumber,
      'photos': photos,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
