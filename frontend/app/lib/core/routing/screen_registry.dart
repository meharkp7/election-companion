import 'package:flutter/material.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/eligibility/screens/eligibility_screen.dart';
import '../../features/registration/screens/registration_screen.dart';
import '../../features/verification/screens/verification_screen.dart';
import '../../features/voting_day/screens/voting_day_screen.dart';
import '../../features/issue_resolver/screens/issue_resolver_screen.dart';
import '../../features/ready_to_vote/screens/ready_to_vote_screen.dart';
import '../../features/completed/screens/completed_screen.dart';
import '../../features/results/screens/results_screen.dart';
import '../../features/global_insights/screens/global_insights_screen.dart';
import '../../features/polling_day_kit/screens/polling_day_kit_screen.dart';
import '../../features/election_tracker/screens/election_tracker_screen.dart';
import '../../features/voter_rights/screens/voter_rights_screen.dart';
import '../../features/results/screens/election_results_screen.dart';
import '../../features/social/screens/social_features_screen.dart';

/// Maps backend `ui.screen` values to Flutter widgets.
///
/// The backend drives which screen to show via `POST /assistant/next-step`.
/// This registry is the single source of truth for screen name → widget mapping.
/// No business logic lives here — only the mapping.
abstract class ScreenRegistry {
  static const _defaultScreen = 'onboarding';

  /// All known screen mappings. The key matches the `ui.screen` value
  /// returned by the backend's `buildUIPayload`.
  static final Map<String, Widget Function()> _screens = {
    'onboarding': () => const OnboardingScreen(),
    'eligibility': () => const EligibilityScreen(),
    'registration': () => const RegistrationScreen(),
    'check_status': () => const VerificationScreen(),
    'verification': () => const VerificationScreen(),
    'issue_resolver': () => const IssueResolverScreen(),
    'ready': () => const ReadyToVoteScreen(),
    'voting_day': () => const VotingDayScreen(),
    'completed': () => const CompletedScreen(),
    'results': () => const ResultsScreen(),
    'global_insights': () => const GlobalInsightsScreen(),
    'polling_day_kit': () => const PollingDayKitScreen(),
    'election_tracker': () => const ElectionTrackerScreen(),
    'voter_rights': () => const VoterRightsScreen(),
    'election_results': () => const ElectionResultsScreen(),
    'social_features': () => const SocialFeaturesScreen(),
  };

  /// Returns the widget for [screenName], falling back to onboarding.
  static Widget resolve(String? screenName) {
    final builder = _screens[screenName ?? _defaultScreen];
    return (builder ?? _screens[_defaultScreen]!)();
  }

  /// Whether [screenName] is a known screen.
  static bool isKnown(String screenName) => _screens.containsKey(screenName);
}
