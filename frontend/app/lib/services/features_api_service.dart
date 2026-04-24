import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// API Service for all new features (Candidates, Document AI, Complaints, Booth Intel)
class FeaturesApiService {
  static const String baseUrl =
      'https://voter-assistant-backend-260506723580.asia-south1.run.app/api/features';

  // ==========================================
  // DOCUMENT AI
  // ==========================================

  static Future<Map<String, dynamic>> analyzeDocument(
    String fileUrl,
    String documentType,
  ) async {
    return _post('/document/analyze', {
      'fileUrl': fileUrl,
      'documentType': documentType,
    });
  }

  static Future<Map<String, dynamic>> validateForBoothVisit(
    String firebaseUid,
    String documentType,
  ) async {
    return _post('/document/validate-for-booth', {
      'firebaseUid': firebaseUid,
      'documentType': documentType,
    });
  }

  static Future<Map<String, dynamic>> validateAllDocuments(
    String firebaseUid,
  ) async {
    return _post('/document/validate-all', {
      'firebaseUid': firebaseUid,
    });
  }

  // ==========================================
  // CANDIDATE INTELLIGENCE
  // ==========================================

  static Future<Map<String, dynamic>> getMyConstituencyCandidates(
    String firebaseUid,
  ) async {
    return _get('/candidates/my-constituency/$firebaseUid');
  }

  static Future<Map<String, dynamic>> getCandidatesByConstituency(
    String state,
    String constituency,
  ) async {
    return _get(
        '/candidates/constituency?state=$state&constituency=$constituency');
  }

  static Future<Map<String, dynamic>> compareCandidates(
    List<String> candidateIds,
  ) async {
    return _post('/candidates/compare', {
      'candidateIds': candidateIds,
    });
  }

  static Future<Map<String, dynamic>> getCandidateDetails(
      String candidateId) async {
    return _get('/candidates/$candidateId');
  }

  static Future<Map<String, dynamic>> getCandidateRecommendations(
    String firebaseUid,
    Map<String, bool> priorities,
  ) async {
    return _post('/candidates/recommendations', {
      'firebaseUid': firebaseUid,
      'priorities': priorities,
    });
  }

  static Future<List<dynamic>> searchCandidates(String query,
      {String? state}) async {
    final queryParams = <String, String>{'q': query};
    if (state != null) queryParams['state'] = state;

    final result = await _get('/candidates/search', queryParams: queryParams);
    return result['candidates'] ?? [];
  }

  // ==========================================
  // COMPLAINTS
  // ==========================================

  static Future<Map<String, dynamic>> fileComplaint(
    String firebaseUid,
    Map<String, dynamic> complaintData,
  ) async {
    return _post('/complaints/file', {
      'firebaseUid': firebaseUid,
      'complaintData': complaintData,
    });
  }

  static Future<List<dynamic>> getMyComplaints(String firebaseUid) async {
    final result = await _get('/complaints/my-complaints/$firebaseUid');
    return result['complaints'] ?? [];
  }

  static Future<Map<String, dynamic>> getComplaintDetails(
    String complaintId,
    String firebaseUid,
  ) async {
    return _get('/complaints/$complaintId?firebaseUid=$firebaseUid');
  }

  static Future<List<dynamic>> getComplaintTemplates(String firebaseUid) async {
    final result = await _get('/complaints/templates/$firebaseUid');
    return result['templates'] ?? [];
  }

  static Future<Map<String, dynamic>> getECIContacts({String? state}) async {
    final queryParams = state != null ? {'state': state} : null;
    return _get('/complaints/eci-contacts', queryParams: queryParams);
  }

  static Future<Map<String, dynamic>> getComplaintStats(
      String firebaseUid) async {
    return _get('/complaints/stats/$firebaseUid');
  }

  // ==========================================
  // BOOTH INTELLIGENCE
  // ==========================================

  static Future<Map<String, dynamic>> reportBoothStatus(
    String firebaseUid,
    Map<String, dynamic> reportData,
  ) async {
    return _post('/booths/report', {
      'firebaseUid': firebaseUid,
      'reportData': reportData,
    });
  }

  static Future<Map<String, dynamic>> getBoothStatus(
    String boothName,
    String constituency,
    String state,
  ) async {
    return _get('/booths/status', queryParams: {
      'boothName': boothName,
      'constituency': constituency,
      'state': state,
    });
  }

  static Future<Map<String, dynamic>> getConstituencyBooths(
    String constituency,
    String state,
  ) async {
    return _get('/booths/constituency', queryParams: {
      'constituency': constituency,
      'state': state,
    });
  }

  static Future<Map<String, dynamic>> getBestTimeToVote(
    String boothName,
    String constituency,
    String state,
  ) async {
    return _get('/booths/best-time', queryParams: {
      'boothName': boothName,
      'constituency': constituency,
      'state': state,
    });
  }

  static Future<Map<String, dynamic>> getAlternativeBooths(
    String currentBooth,
    String constituency,
    String state,
  ) async {
    return _get('/booths/alternatives', queryParams: {
      'currentBooth': currentBooth,
      'constituency': constituency,
      'state': state,
    });
  }

  static Future<void> verifyBoothReport(
      String reportId, String firebaseUid) async {
    await _post('/booths/verify', {
      'reportId': reportId,
      'firebaseUid': firebaseUid,
    });
  }

  static Future<List<dynamic>> getReporterLeaderboard(
    String constituency,
    String state,
  ) async {
    final result = await _get('/booths/leaderboard/$constituency',
        queryParams: {'state': state});
    return result['leaderboard'] ?? [];
  }

  // ==========================================
  // REMINDERS
  // ==========================================

  static Future<Map<String, dynamic>> scheduleReminder(String firebaseUid,
      String reminderType, String title, String message, DateTime scheduledAt,
      {String priority = 'medium'}) async {
    return _post('/reminders/schedule', {
      'firebaseUid': firebaseUid,
      'reminderType': reminderType,
      'title': title,
      'message': message,
      'scheduledAt': scheduledAt.toIso8601String(),
      'priority': priority,
    });
  }

  static Future<List<dynamic>> getMyReminders(String firebaseUid) async {
    final result = await _get('/reminders/my-reminders/$firebaseUid');
    return result['reminders'] ?? [];
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
      debugPrint('FeaturesApi GET error: $e');
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
      debugPrint('FeaturesApi POST error: $e');
      rethrow;
    }
  }
}
