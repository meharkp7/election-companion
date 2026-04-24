class HelplineContact {
  final String id;
  final String name;
  final String contactType;
  final String? phone;
  final String? email;
  final String? state;
  final String purpose;
  final bool isPrimary;
  final int priority;
  final DateTime? createdAt;

  HelplineContact({
    required this.id,
    required this.name,
    required this.contactType,
    this.phone,
    this.email,
    this.state,
    required this.purpose,
    this.isPrimary = false,
    required this.priority,
    this.createdAt,
  });

  factory HelplineContact.fromJson(Map<String, dynamic> json) {
    return HelplineContact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      contactType: json['contactType'] ?? '',
      phone: json['phone'],
      email: json['email'],
      state: json['state'],
      purpose: json['purpose'] ?? '',
      isPrimary: json['isPrimary'] ?? false,
      priority: json['priority'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contactType': contactType,
      'phone': phone,
      'email': email,
      'state': state,
      'purpose': purpose,
      'isPrimary': isPrimary,
      'priority': priority,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  String get iconEmoji {
    switch (contactType) {
      case 'helpline':
        return '☎️';
      case 'ceo_office':
        return '🏢';
      case 'sms':
        return '💬';
      default:
        return '📞';
    }
  }

  bool get isHelpline => contactType == 'helpline';
  bool get isCEOOffice => contactType == 'ceo_office';
}
