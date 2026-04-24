import 'package:go_router/go_router.dart';
import '../../features/assistant_shell.dart';
import '../../features/results/screens/results_screen.dart';
import '../../features/global_insights/screens/global_insights_screen.dart';
import '../../features/issue_resolver/screens/issue_resolver_screen.dart';
import '../../features/polling_day_kit/screens/polling_day_kit_screen.dart';
import '../../features/election_tracker/screens/election_tracker_screen.dart';
import '../../features/voter_rights/screens/voter_rights_screen.dart';
import '../../features/results/screens/election_results_screen.dart';
import '../../features/social/screens/social_features_screen.dart';

/// Simplified router — the main flow is a single [AssistantShell] that
/// dynamically renders the backend-driven screen. Auxiliary routes
/// (results, global insights, issue resolver) are kept for push-navigation
/// from post-voting or help sections.
abstract class AppRoutes {
  static const String home = '/';
  static const String results = '/results';
  static const String globalInsights = '/global-insights';
  static const String issueResolver = '/issue-resolver';
  static const String pollingDayKit = '/polling-day-kit';
  static const String electionTracker = '/election-tracker';
  static const String voterRights = '/voter-rights';
  static const String electionResults = '/election-results';
  static const String socialFeatures = '/social-features';
}

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const AssistantShell(),
    ),
    GoRoute(
      path: AppRoutes.results,
      builder: (context, state) => const ResultsScreen(),
    ),
    GoRoute(
      path: AppRoutes.globalInsights,
      builder: (context, state) => const GlobalInsightsScreen(),
    ),
    GoRoute(
      path: AppRoutes.issueResolver,
      builder: (context, state) => const IssueResolverScreen(),
    ),
    GoRoute(
      path: AppRoutes.pollingDayKit,
      builder: (context, state) => const PollingDayKitScreen(),
    ),
    GoRoute(
      path: AppRoutes.electionTracker,
      builder: (context, state) => const ElectionTrackerScreen(),
    ),
    GoRoute(
      path: AppRoutes.voterRights,
      builder: (context, state) => const VoterRightsScreen(),
    ),
    GoRoute(
      path: AppRoutes.electionResults,
      builder: (context, state) => const ElectionResultsScreen(),
    ),
    GoRoute(
      path: AppRoutes.socialFeatures,
      builder: (context, state) => const SocialFeaturesScreen(),
    ),
  ],
);
