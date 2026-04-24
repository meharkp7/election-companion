/// Utility to determine a state's position in the assistant state machine.
///
/// Used purely for **display logic** (e.g. step trackers and progress cards).
/// No business logic — the backend controls actual state transitions.
abstract class StateOrder {
  static const _order = [
    'START',
    'ELIGIBILITY_CHECK',
    'REGISTRATION',
    'CHECK_STATUS',
    'VERIFICATION',
    'ISSUE_RESOLVER',
    'READY_TO_VOTE',
    'VOTING_DAY',
    'COMPLETED',
    'POST_VOTING_EXPLORE',
  ];

  /// Whether [state] has progressed strictly past [milestone].
  static bool isPast(String state, String milestone) {
    final current = _order.indexOf(state);
    final target = _order.indexOf(milestone);
    if (current == -1 || target == -1) return false;
    return current > target;
  }

  /// Whether [state] is at or past [milestone].
  static bool isAtOrPast(String state, String milestone) {
    final current = _order.indexOf(state);
    final target = _order.indexOf(milestone);
    if (current == -1 || target == -1) return false;
    return current >= target;
  }
}
