import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user_model.dart';
import '../models/assistant_response.dart';
import '../services/api_service.dart';

final userProvider =
    NotifierProvider<UserNotifier, AsyncValue<User>>(UserNotifier.new);

class UserNotifier extends Notifier<AsyncValue<User>> {
  @override
  AsyncValue<User> build() {
    _initializeUser();
    Future.microtask(() => fetchCurrentStep());
    return const AsyncValue.loading();
  }

  /// Resolves the Firebase UID from the currently signed-in user.
  /// Falls back to a placeholder during development.
  String _getFirebaseUid() {
    try {
      final fbUser = fb.FirebaseAuth.instance.currentUser;
      if (fbUser != null) return fbUser.uid;
    } catch (_) {}
    return 'dev_user_placeholder'; // fallback for dev/unauthenticated
  }

  void _initializeUser() {
    try {
      final uid = _getFirebaseUid();
      state = AsyncValue.data(const User(
        age: 0,
        state: '',
        isFirstTimeVoter: false,
        currentState: 'START',
        readinessScore: 0,
      ).copyWith(firebaseUid: uid));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ─── Core API method ─────────────────────────────────────

  /// Sends [input] to `POST /assistant/next-step` and updates the local
  /// user state from the response. This is the **only** method that should
  /// talk to the assistant endpoint.
  ///
  /// **Does not** set global loading state — individual screen controllers
  /// manage their own loading indicators via `AsyncValue.guard()`. This avoids
  /// the [AssistantShell] briefly flashing a full-screen loader on every
  /// interaction.
  ///
  /// Throws on failure so callers (controllers) can catch via
  /// `AsyncValue.guard()`.
  ///
  /// Usage:
  /// ```dart
  /// ref.read(userProvider.notifier).sendStep({
  ///   'age': 21,
  ///   'state': 'Maharashtra',
  ///   'isFirstTimeVoter': true,
  /// });
  /// ```
  Future<AssistantResponse> sendStep(Map<String, dynamic> input) async {
    final currentUser = state.value;
    final uid = currentUser?.firebaseUid ?? _getFirebaseUid();

    // ── Correct request format: { firebaseUid, input } ──
    // The backend expects firebaseUid at the top level with user data
    // wrapped inside the "input" key.
    final response = await ApiService.post(
      '/assistant/next-step',
      {
        'firebaseUid': uid,
        'input': input,
      },
    );

    // ── Parse response safely ──
    final assistantResponse = AssistantResponse.fromJson(response);

    // ── Build updated user from response ──
    final updatedUser = (currentUser ??
            const User(
              age: 0,
              state: '',
              isFirstTimeVoter: false,
              currentState: 'START',
              readinessScore: 0,
            ))
        .copyWith(
      firebaseUid: uid,
      currentState: assistantResponse.currentState,
      message: assistantResponse.message,
      latestUI: assistantResponse.ui,
      readinessScore: assistantResponse.ui.readinessScore ??
          currentUser?.readinessScore ??
          0,
      // Persist onboarding data from input if present
      age: input['age'] as int? ?? currentUser?.age ?? 0,
      state: input['state'] as String? ?? currentUser?.state ?? '',
      isFirstTimeVoter: input['isFirstTimeVoter'] as bool? ??
          currentUser?.isFirstTimeVoter ??
          false,
    );

    state = AsyncValue.data(updatedUser);
    return assistantResponse;
  }

  // ─── Convenience wrappers ────────────────────────────────

  /// Onboarding step: sends age, state, and first-time-voter flag.
  Future<AssistantResponse> onboard({
    required int age,
    required String userState,
    required bool isFirstTimeVoter,
  }) {
    return sendStep({
      'age': age,
      'state': userState,
      'isFirstTimeVoter': isFirstTimeVoter,
    });
  }

  /// Registration step: sends registration status selection.
  Future<AssistantResponse> submitRegistration(String registrationChoice) {
    return sendStep({
      'registrationStatus': registrationChoice,
    });
  }

  /// Verification step: sends verification data.
  Future<AssistantResponse> submitVerification({
    required String verificationStatus,
    bool? boothKnown,
  }) {
    return sendStep({
      'verificationStatus': verificationStatus,
      if (boothKnown != null) 'boothKnown': boothKnown,
    });
  }

  /// Generic step advance (e.g. "continue" with no extra data).
  Future<AssistantResponse> advance() {
    return sendStep({});
  }

  /// Mark that the user has voted.
  Future<AssistantResponse> markVoted() {
    return sendStep({'votingDone': true});
  }

  // ─── Fetch current state from backend ────────────────────

  /// Loads the current assistant state from `GET /assistant/current-step/:uid`.
  /// Useful on app resume / cold start.
  Future<void> fetchCurrentStep() async {
    final uid = state.value?.firebaseUid ?? _getFirebaseUid();
    state = const AsyncValue.loading();

    try {
      final response = await ApiService.get(
        '/assistant/current-step/$uid',
      );

      final currentState = response['currentState'] as String? ?? 'START';
      final readinessScore = response['readinessScore'] as int? ?? 0;
      final ui = AssistantUI.fromJson(
        response['ui'] as Map<String, dynamic>? ?? {},
      );

      final user = (state.value ??
              const User(
                age: 0,
                state: '',
                isFirstTimeVoter: false,
                currentState: 'START',
                readinessScore: 0,
              ))
          .copyWith(
        firebaseUid: uid,
        currentState: currentState,
        readinessScore: readinessScore,
        latestUI: ui,
      );

      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Direct user object update (for local-only changes).
  void updateUser(User user) {
    state = AsyncValue.data(user);
  }
}
