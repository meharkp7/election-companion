class IVotedRecord {
  final String id;
  final String firebaseUid;
  final String? boothName;
  final String? constituency;
  final String? state;
  final DateTime votedAt;
  final String? verifiedVia;
  final bool badgeGenerated;
  final String? badgeImageUrl;
  final bool sharePublicly;
  final bool shareAnonymously;
  final int sharedCount;
  final int likesCount;

  IVotedRecord({
    required this.id,
    required this.firebaseUid,
    this.boothName,
    this.constituency,
    this.state,
    required this.votedAt,
    this.verifiedVia,
    this.badgeGenerated = false,
    this.badgeImageUrl,
    this.sharePublicly = true,
    this.shareAnonymously = false,
    this.sharedCount = 0,
    this.likesCount = 0,
  });

  factory IVotedRecord.fromJson(Map<String, dynamic> json) {
    return IVotedRecord(
      id: json['id'] ?? '',
      firebaseUid: json['firebaseUid'] ?? '',
      boothName: json['boothName'],
      constituency: json['constituency'],
      state: json['state'],
      votedAt: json['votedAt'] != null ? DateTime.parse(json['votedAt']) : DateTime.now(),
      verifiedVia: json['verifiedVia'],
      badgeGenerated: json['badgeGenerated'] ?? false,
      badgeImageUrl: json['badgeImageUrl'],
      sharePublicly: json['sharePublicly'] ?? true,
      shareAnonymously: json['shareAnonymously'] ?? false,
      sharedCount: json['sharedCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'boothName': boothName,
      'constituency': constituency,
      'state': state,
      'votedAt': votedAt.toIso8601String(),
      'verifiedVia': verifiedVia,
      'badgeGenerated': badgeGenerated,
      'badgeImageUrl': badgeImageUrl,
      'sharePublicly': sharePublicly,
      'shareAnonymously': shareAnonymously,
      'sharedCount': sharedCount,
      'likesCount': likesCount,
    };
  }

  String get badgeType {
    final hour = votedAt.hour;
    if (hour < 9) return 'early_bird';
    if (hour > 15) return 'dedicated';
    return 'voter';
  }

  String get badgeTitle {
    switch (badgeType) {
      case 'early_bird':
        return 'Early Bird Voter';
      case 'dedicated':
        return 'Dedicated Voter';
      default:
        return 'Proud Voter';
    }
  }

  String get formattedVoteTime {
    return '${votedAt.hour}:${votedAt.minute.toString().padLeft(2, '0')}';
  }
}

class IVotedBadge {
  final String type;
  final String title;
  final DateTime votedAt;
  final String? constituency;
  final String message;
  final Map<String, dynamic> colors;

  IVotedBadge({
    required this.type,
    required this.title,
    required this.votedAt,
    this.constituency,
    required this.message,
    required this.colors,
  });

  factory IVotedBadge.fromJson(Map<String, dynamic> json) {
    return IVotedBadge(
      type: json['type'] ?? 'voter',
      title: json['title'] ?? 'Proud Voter',
      votedAt: json['votedAt'] != null ? DateTime.parse(json['votedAt']) : DateTime.now(),
      constituency: json['constituency'],
      message: json['message'] ?? 'I voted!',
      colors: json['colors'] ?? {'bg': '#4ECDC4', 'text': '#FFF'},
    );
  }
}
