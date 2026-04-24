import 'assistant_response.dart';

/// User model that reflects the backend state machine.
///
/// [currentState] is a raw string from the backend (e.g. "START",
/// "ELIGIBILITY_CHECK", "REGISTRATION") — no client-side enum mapping.
/// [latestUI] holds the most recent UI payload so screens can render
/// whatever the backend instructs.
class User {
  final String? firebaseUid;
  final int age;
  final String state;
  final bool isFirstTimeVoter;
  final String currentState;
  final int readinessScore;
  final String? message;
  final AssistantUI? latestUI;
  final String? boothName;
  final String? boothAddress;

  const User({
    this.firebaseUid,
    required this.age,
    required this.state,
    required this.isFirstTimeVoter,
    required this.currentState,
    required this.readinessScore,
    this.message,
    this.latestUI,
    this.boothName,
    this.boothAddress,
  });

  User copyWith({
    String? firebaseUid,
    int? age,
    String? state,
    bool? isFirstTimeVoter,
    String? currentState,
    int? readinessScore,
    String? message,
    AssistantUI? latestUI,
    String? boothName,
    String? boothAddress,
  }) {
    return User(
      firebaseUid: firebaseUid ?? this.firebaseUid,
      age: age ?? this.age,
      state: state ?? this.state,
      isFirstTimeVoter: isFirstTimeVoter ?? this.isFirstTimeVoter,
      currentState: currentState ?? this.currentState,
      readinessScore: readinessScore ?? this.readinessScore,
      message: message ?? this.message,
      latestUI: latestUI ?? this.latestUI,
      boothName: boothName ?? this.boothName,
      boothAddress: boothAddress ?? this.boothAddress,
    );
  }

  /// The screen name the backend wants to show (falls back to 'onboarding').
  String get currentScreen => latestUI?.screen ?? 'onboarding';

  /// Booth details map for convenience
  Map<String, dynamic>? get boothDetails => boothName != null ? {
    'boothName': boothName,
    'boothAddress': boothAddress,
  } : null;
}
