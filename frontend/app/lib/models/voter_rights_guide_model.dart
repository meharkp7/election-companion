class VoterRightsGuide {
  final String id;
  final String topic;
  final String title;
  final String content;
  final List<String> quickSteps;
  final String category;
  final int priority;
  final String language;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VoterRightsGuide({
    required this.id,
    required this.topic,
    required this.title,
    required this.content,
    this.quickSteps = const [],
    required this.category,
    required this.priority,
    this.language = 'en',
    this.createdAt,
    this.updatedAt,
  });

  factory VoterRightsGuide.fromJson(Map<String, dynamic> json) {
    return VoterRightsGuide(
      id: json['id'] ?? '',
      topic: json['topic'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      quickSteps: List<String>.from(json['quickSteps'] ?? []),
      category: json['category'] ?? '',
      priority: json['priority'] ?? 0,
      language: json['language'] ?? 'en',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic': topic,
      'title': title,
      'content': content,
      'quickSteps': quickSteps,
      'category': category,
      'priority': priority,
      'language': language,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get isEmergency => category == 'emergency';
  bool get isRights => category == 'rights';
  bool get isAccessibility => category == 'accessibility';

  String get iconEmoji {
    switch (category) {
      case 'emergency':
        return '🚨';
      case 'rights':
        return '⚖️';
      case 'accessibility':
        return '♿';
      default:
        return '📋';
    }
  }
}
