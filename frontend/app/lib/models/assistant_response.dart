/// Strongly-typed representation of the backend `/assistant/next-step` response.
///
/// Response shape:
/// ```json
/// {
///   "currentState": "START | ELIGIBILITY_CHECK | REGISTRATION | ...",
///   "message": "string",
///   "ui": { "screen": "...", "title": "...", ... }
/// }
/// ```
class AssistantResponse {
  final String currentState;
  final String message;
  final AssistantUI ui;

  const AssistantResponse({
    required this.currentState,
    required this.message,
    required this.ui,
  });

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    return AssistantResponse(
      currentState: json['currentState'] as String? ?? 'START',
      message: json['message'] as String? ?? '',
      ui: AssistantUI.fromJson(
        json['ui'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'currentState': currentState,
        'message': message,
        'ui': ui.toJson(),
      };
}

/// Strongly-typed representation of the `ui` payload from the backend.
///
/// All fields are nullable because the backend only sends fields relevant
/// to the current state.
class AssistantUI {
  final String screen;
  final String? title;
  final String? prompt;
  final List<String> inputs;
  final List<String> options;
  final List<String> steps;
  final int? readinessScore;
  final String? link;
  final String? action;
  final Map<String, dynamic>? boothDetails;

  const AssistantUI({
    required this.screen,
    this.title,
    this.prompt,
    this.inputs = const [],
    this.options = const [],
    this.steps = const [],
    this.readinessScore,
    this.link,
    this.action,
    this.boothDetails,
  });

  factory AssistantUI.fromJson(Map<String, dynamic> json) {
    return AssistantUI(
      screen: json['screen'] as String? ?? 'onboarding',
      title: json['title'] as String?,
      prompt: json['prompt'] as String?,
      inputs: _parseStringList(json['inputs']),
      options: _parseStringList(json['options']),
      steps: _parseStringList(json['steps']),
      readinessScore: json['readinessScore'] as int?,
      link: json['link'] as String?,
      action: json['action'] as String?,
      boothDetails: json['boothDetails'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'screen': screen,
        if (title != null) 'title': title,
        if (prompt != null) 'prompt': prompt,
        if (inputs.isNotEmpty) 'inputs': inputs,
        if (options.isNotEmpty) 'options': options,
        if (steps.isNotEmpty) 'steps': steps,
        if (readinessScore != null) 'readinessScore': readinessScore,
        if (link != null) 'link': link,
        if (action != null) 'action': action,
        if (boothDetails != null) 'boothDetails': boothDetails,
      };

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}
