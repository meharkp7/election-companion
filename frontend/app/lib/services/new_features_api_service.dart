import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// API Service for new v2 features (Polling Day Kit, Election Tracker, Voter Rights, Results, Social)
class NewFeaturesApiService {
  static const String baseUrl =
      'https://voter-assistant-backend-260506723580.asia-south1.run.app/api/v2/features';

  // ==========================================
  // POLLING DAY KIT
  // ==========================================

  /// Get voter slip for user
  static Future<Map<String, dynamic>> getVoterSlip(String firebaseUid) async {
    return _get('/polling-kit/voter-slip/$firebaseUid');
  }

  /// Save voter slip
  static Future<Map<String, dynamic>> saveVoterSlip(
    String firebaseUid,
    Map<String, dynamic> slipData,
  ) async {
    return _post('/polling-kit/voter-slip', {
      'firebaseUid': firebaseUid,
      'slipData': slipData,
    });
  }

  /// Validate documents for booth visit
  static Future<Map<String, dynamic>> validateDocuments(
      String firebaseUid) async {
    return _get('/polling-kit/validate-documents/$firebaseUid');
  }

  /// Get polling checklist
  static Future<Map<String, dynamic>> getChecklist(String firebaseUid) async {
    return _get('/polling-kit/checklist/$firebaseUid');
  }

  /// Update checklist item
  static Future<Map<String, dynamic>> updateChecklist(
    String firebaseUid,
    Map<String, dynamic> updates,
  ) async {
    return _patch('/polling-kit/checklist/$firebaseUid', updates);
  }

  /// Trigger panic button
  static Future<Map<String, dynamic>> triggerPanicButton(
    String firebaseUid,
    String reason,
    Map<String, dynamic>? location,
  ) async {
    return _post('/polling-kit/panic-button', {
      'firebaseUid': firebaseUid,
      'reason': reason,
      'location': location,
    });
  }

  /// Resolve panic alert
  static Future<Map<String, dynamic>> resolvePanic(
    String firebaseUid, {
    String? resolutionNotes,
  }) async {
    return _post('/polling-kit/resolve-panic/$firebaseUid', {
      'resolutionNotes': resolutionNotes,
    });
  }

  // ==========================================
  // ELECTION TRACKER
  // ==========================================

  /// Get election phases for user
  static Future<Map<String, dynamic>> getElectionPhases(
      String firebaseUid) async {
    return _get('/election-tracker/phases/$firebaseUid');
  }

  /// Get election phases by state
  static Future<Map<String, dynamic>> getElectionPhasesByState(
      String state) async {
    return _get('/election-tracker/phases-by-state/$state');
  }

  /// Get upcoming elections
  static Future<Map<String, dynamic>> getUpcomingElections() async {
    return _get('/election-tracker/upcoming');
  }

  /// Get user calendar
  static Future<Map<String, dynamic>> getUserCalendar(
      String firebaseUid) async {
    return _get('/election-tracker/calendar/$firebaseUid');
  }

  /// Set reminder preferences
  static Future<Map<String, dynamic>> setReminderPreferences(
    String firebaseUid,
    Map<String, dynamic> preferences,
  ) async {
    return _post(
        '/election-tracker/reminder-preferences/$firebaseUid', preferences);
  }

  /// Get sample ballot
  static Future<Map<String, dynamic>> getSampleBallot(
      String firebaseUid) async {
    return _get('/election-tracker/sample-ballot/$firebaseUid');
  }

  /// Mark sample ballot as viewed
  static Future<Map<String, dynamic>> markBallotViewed(
    String firebaseUid,
    String phaseId,
  ) async {
    return _post('/election-tracker/mark-ballot-viewed/$firebaseUid', {
      'phaseId': phaseId,
    });
  }

  /// Get live turnout for user
  static Future<Map<String, dynamic>> getLiveTurnout(String firebaseUid) async {
    return _get('/election-tracker/live-turnout/$firebaseUid');
  }

  /// Get state turnout
  static Future<Map<String, dynamic>> getStateTurnout(String state) async {
    return _get('/election-tracker/state-turnout/$state');
  }

  // ==========================================
  // VOTER RIGHTS
  // ==========================================

  /// Get all voter rights guides
  static Future<Map<String, dynamic>> getVoterRightsGuides({
    String? category,
    String? language,
  }) async {
    final queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;
    if (language != null) queryParams['language'] = language;
    return _get('/voter-rights/guides', queryParams: queryParams);
  }

  /// Get guide by topic
  static Future<Map<String, dynamic>> getGuideByTopic(
    String topic, {
    String? language,
  }) async {
    final queryParams = language != null ? {'language': language} : null;
    return _get('/voter-rights/guides/$topic', queryParams: queryParams);
  }

  /// Search guides
  static Future<Map<String, dynamic>> searchGuides(
    String query, {
    String? language,
  }) async {
    final queryParams = <String, String>{'q': query};
    if (language != null) queryParams['language'] = language;
    return _get('/voter-rights/search', queryParams: queryParams);
  }

  /// Get helplines for user
  static Future<Map<String, dynamic>> getHelplines(String firebaseUid) async {
    return _get('/voter-rights/helplines/$firebaseUid');
  }

  /// Get helplines by state
  static Future<Map<String, dynamic>> getHelplinesByState(String state) async {
    return _get('/voter-rights/helplines-by-state/$state');
  }

  /// Get emergency contacts
  static Future<Map<String, dynamic>> getEmergencyContacts(
      {String? state}) async {
    final queryParams = state != null ? {'state': state} : null;
    return _get('/voter-rights/emergency-contacts', queryParams: queryParams);
  }

  /// Get accessibility info
  static Future<Map<String, dynamic>> getAccessibilityInfo() async {
    return _get('/voter-rights/accessibility');
  }

  /// Get voter rights
  static Future<Map<String, dynamic>> getVoterRights() async {
    return _get('/voter-rights/rights');
  }

  /// Get emergency scenarios
  static Future<Map<String, dynamic>> getEmergencyScenarios() async {
    return _get('/voter-rights/emergency-scenarios');
  }

  // ==========================================
  // ELECTION RESULTS
  // ==========================================

  /// Get results for user's constituency
  static Future<Map<String, dynamic>> getMyConstituencyResults(
      String firebaseUid) async {
    return _get('/results/my-constituency/$firebaseUid');
  }

  /// Get constituency results
  static Future<Map<String, dynamic>> getConstituencyResults(
    String state,
    String constituency,
  ) async {
    return _get('/results/constituency', queryParams: {
      'state': state,
      'constituency': constituency,
    });
  }

  /// Get state results
  static Future<Map<String, dynamic>> getStateResults(String state) async {
    return _get('/results/state/$state');
  }

  /// Get historical results
  static Future<Map<String, dynamic>> getHistoricalResults(
    String state,
    String constituency,
  ) async {
    return _get('/results/historical', queryParams: {
      'state': state,
      'constituency': constituency,
    });
  }

  /// Compare with previous election
  static Future<Map<String, dynamic>> compareWithPrevious(
    String state,
    String constituency,
  ) async {
    return _get('/results/compare', queryParams: {
      'state': state,
      'constituency': constituency,
    });
  }

  /// Get party performance
  static Future<Map<String, dynamic>> getPartyPerformance(
    String state, {
    int? year,
  }) async {
    final queryParams = year != null ? {'year': year.toString()} : null;
    return _get('/results/party-performance/$state', queryParams: queryParams);
  }

  /// Get closest contests
  static Future<Map<String, dynamic>> getClosestContests(
    String state, {
    int limit = 10,
  }) async {
    return _get('/results/closest-contests/$state', queryParams: {
      'limit': limit.toString(),
    });
  }

  /// Get biggest victories
  static Future<Map<String, dynamic>> getBiggestVictories(
    String state, {
    int limit = 10,
  }) async {
    return _get('/results/biggest-victories/$state', queryParams: {
      'limit': limit.toString(),
    });
  }

  /// Get vote share
  static Future<Map<String, dynamic>> getVoteShare(
    String state,
    String constituency,
  ) async {
    return _get('/results/vote-share', queryParams: {
      'state': state,
      'constituency': constituency,
    });
  }

  /// Get turnout analysis
  static Future<Map<String, dynamic>> getTurnoutAnalysis(String state) async {
    return _get('/results/turnout-analysis/$state');
  }

  // ==========================================
  // SOCIAL FEATURES
  // ==========================================

  /// Create carpool
  static Future<Map<String, dynamic>> createCarpool(
    String firebaseUid,
    Map<String, dynamic> carpoolData,
  ) async {
    return _post('/social/carpool', {
      'firebaseUid': firebaseUid,
      ...carpoolData,
    });
  }

  /// Find carpools
  static Future<Map<String, dynamic>> findCarpools(
    String boothName,
    String constituency,
    String state,
  ) async {
    return _get('/social/carpools', queryParams: {
      'boothName': boothName,
      'constituency': constituency,
      'state': state,
    });
  }

  /// Join carpool
  static Future<Map<String, dynamic>> joinCarpool(
    String carpoolId,
    String firebaseUid,
  ) async {
    return _post('/social/carpool/join', {
      'carpoolId': carpoolId,
      'firebaseUid': firebaseUid,
    });
  }

  /// Get my carpools
  static Future<Map<String, dynamic>> getMyCarpools(String firebaseUid) async {
    return _get('/social/carpools/my/$firebaseUid');
  }

  /// Record "I Voted"
  static Future<Map<String, dynamic>> recordIVoted(
    String firebaseUid,
    Map<String, dynamic> voteData,
  ) async {
    return _post('/social/i-voted', {
      'firebaseUid': firebaseUid,
      ...voteData,
    });
  }

  /// Get I Voted record
  static Future<Map<String, dynamic>> getIVotedRecord(
      String firebaseUid) async {
    return _get('/social/i-voted/$firebaseUid');
  }

  /// Get I Voted feed
  static Future<Map<String, dynamic>> getIVotedFeed({
    String? constituency,
    String? state,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{'limit': limit.toString()};
    if (constituency != null) queryParams['constituency'] = constituency;
    if (state != null) queryParams['state'] = state;
    return _get('/social/i-voted-feed', queryParams: queryParams);
  }

  /// Share I Voted
  static Future<Map<String, dynamic>> shareIVoted(
    String firebaseUid,
    String platform,
  ) async {
    return _post('/social/share-i-voted/$firebaseUid', {
      'platform': platform,
    });
  }

  /// Share booth info
  static Future<Map<String, dynamic>> shareBoothInfo(
    String firebaseUid,
    Map<String, dynamic> shareData,
  ) async {
    return _post('/social/share-booth', {
      'firebaseUid': firebaseUid,
      ...shareData,
    });
  }

  /// Get community stats
  static Future<Map<String, dynamic>> getCommunityStats(
    String constituency,
    String state,
  ) async {
    return _get('/social/community-stats', queryParams: {
      'constituency': constituency,
      'state': state,
    });
  }

  // ==========================================
  // BOOTH CROWDSOURCING
  // ==========================================

  /// Report booth status
  static Future<Map<String, dynamic>> reportBoothStatus(
    String firebaseUid,
    Map<String, dynamic> reportData,
  ) async {
    return _post('/booth-crowdsource/report', {
      'firebaseUid': firebaseUid,
      'reportData': reportData,
    });
  }

  /// Get real-time status for a specific booth
  static Future<Map<String, dynamic>> getBoothStatus(
    String boothName,
    String constituency,
    String state,
  ) async {
    return _get('/booth-crowdsource/status', queryParams: {
      'boothName': boothName,
      'constituency': constituency,
      'state': state,
    });
  }

  // ==========================================
  // AI ASSISTANT FAQ
  // ==========================================

  /// Ask AI Assistant a question
  static Future<Map<String, dynamic>> askAssistant(
    String question,
    Map<String, dynamic> userContext,
  ) async {
    return _post('/assistant/faq', {
      'question': question,
      'userContext': userContext,
    });
  }

  /// Get quick suggested questions
  static Future<Map<String, dynamic>> getQuickQuestions() async {
    return _get('/assistant/quick-questions');
  }

  // ==========================================
  // HTTP HELPERS
  // ==========================================

  static Future<Map<String, dynamic>> _get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      var url = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        url = url.replace(queryParameters: queryParams);
      }

      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('NewFeaturesApi GET error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('NewFeaturesApi POST error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .patch(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('NewFeaturesApi PATCH error: $e');
      rethrow;
    }
  }
}
