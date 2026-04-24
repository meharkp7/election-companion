class Carpool {
  final String id;
  final String creatorFirebaseUid;
  final String? creatorPhone;
  final String boothName;
  final String constituency;
  final String state;
  final String? meetingPoint;
  final String rideType;
  final String? vehicleType;
  final int seatsAvailable;
  final DateTime? departureTime;
  final bool returnTrip;
  final DateTime? returnTime;
  final List<String> passengers;
  final int maxPassengers;
  final String status;
  final DateTime? createdAt;

  Carpool({
    required this.id,
    required this.creatorFirebaseUid,
    this.creatorPhone,
    required this.boothName,
    required this.constituency,
    required this.state,
    this.meetingPoint,
    required this.rideType,
    this.vehicleType,
    required this.seatsAvailable,
    this.departureTime,
    required this.returnTrip,
    this.returnTime,
    this.passengers = const [],
    required this.maxPassengers,
    required this.status,
    this.createdAt,
  });

  factory Carpool.fromJson(Map<String, dynamic> json) {
    return Carpool(
      id: json['id'] ?? '',
      creatorFirebaseUid: json['creatorFirebaseUid'] ?? '',
      creatorPhone: json['creatorPhone'],
      boothName: json['boothName'] ?? '',
      constituency: json['constituency'] ?? '',
      state: json['state'] ?? '',
      meetingPoint: json['meetingPoint'],
      rideType: json['rideType'] ?? '',
      vehicleType: json['vehicleType'],
      seatsAvailable: json['seatsAvailable'] ?? 0,
      departureTime: json['departureTime'] != null ? DateTime.parse(json['departureTime']) : null,
      returnTrip: json['returnTrip'] ?? false,
      returnTime: json['returnTime'] != null ? DateTime.parse(json['returnTime']) : null,
      passengers: List<String>.from(json['passengers'] ?? []),
      maxPassengers: json['maxPassengers'] ?? 0,
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creatorFirebaseUid': creatorFirebaseUid,
      'creatorPhone': creatorPhone,
      'boothName': boothName,
      'constituency': constituency,
      'state': state,
      'meetingPoint': meetingPoint,
      'rideType': rideType,
      'vehicleType': vehicleType,
      'seatsAvailable': seatsAvailable,
      'departureTime': departureTime?.toIso8601String(),
      'returnTrip': returnTrip,
      'returnTime': returnTime?.toIso8601String(),
      'passengers': passengers,
      'maxPassengers': maxPassengers,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  bool get isOffer => rideType == 'offer';
  bool get isRequest => rideType == 'request';
  bool get isActive => status == 'active';
  bool get isFull => status == 'full';
  bool get isCompleted => status == 'completed';

  int get availableSeats => maxPassengers - passengers.length;

  String get formattedDepartureTime {
    if (departureTime == null) return 'TBD';
    return '${departureTime!.hour}:${departureTime!.minute.toString().padLeft(2, '0')}';
  }
}
