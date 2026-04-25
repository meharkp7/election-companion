import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper around FirebaseRemoteConfig that exposes typed getters
/// for every feature flag used in the app.
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  FirebaseRemoteConfig get _rc => FirebaseRemoteConfig.instance;

  // ── Feature flags ────────────────────────────────────────────────────
  bool get electionModeEnabled => _rc.getBool('election_mode_enabled');
  bool get aiAssistantEnabled => _rc.getBool('ai_assistant_enabled');
  bool get boothIntelligenceEnabled => _rc.getBool('booth_intelligence_enabled');
  bool get socialEnabled => _rc.getBool('feature_social_enabled');
  bool get resultsEnabled => _rc.getBool('feature_results_enabled');
  bool get maintenanceMode => _rc.getBool('app_maintenance_mode');
  int get maxCandidatesShown => _rc.getInt('max_candidates_shown');

  /// Force a fresh fetch (call on app resume or settings screen).
  Future<bool> refresh() async {
    try {
      return await _rc.fetchAndActivate();
    } catch (e) {
      if (kDebugMode) debugPrint('RemoteConfig refresh failed: $e');
      return false;
    }
  }

  /// Stream of config updates (useful for real-time flag changes).
  Stream<RemoteConfigUpdate> get onConfigUpdated => _rc.onConfigUpdated;
}

// Riverpod provider
final remoteConfigProvider = Provider<RemoteConfigService>(
  (_) => RemoteConfigService.instance,
);
