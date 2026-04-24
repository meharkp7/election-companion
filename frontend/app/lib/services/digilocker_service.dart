import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

/// DigiLocker Service for secure government document verification
/// Uses OAuth 2.0 with PKCE for secure authentication
class DigiLockerService {
  static const String _baseUrl = ApiService.baseUrl;

  /// Check if DigiLocker is linked for the user
  static Future<Map<String, dynamic>> getStatus(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/digilocker/status/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {'linked': false, 'status': 'not_initiated'};
      }
      return {'linked': false, 'status': 'error'};
    } catch (e) {
      return {'linked': false, 'status': 'error', 'message': e.toString()};
    }
  }

  /// Initiate DigiLocker OAuth flow
  static Future<Map<String, dynamic>> initiateAuth(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/digilocker/auth-url/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'authUrl': data['data']['authUrl'],
            'state': data['data']['state'],
          };
        }
      }
      return {'success': false, 'error': 'Failed to get auth URL'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Launch DigiLocker authentication in browser/app
  static Future<bool> launchDigiLockerAuth(String authUrl) async {
    try {
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Complete DigiLocker OAuth with authorization code
  static Future<Map<String, dynamic>> completeAuth({
    required String userId,
    required String code,
    required String state,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/digilocker/callback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'code': code,
          'state': state,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return {'success': false, 'error': 'Callback failed'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fetch user profile from DigiLocker
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/digilocker/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Fetch documents list from DigiLocker
  static Future<Map<String, dynamic>> getDocuments(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/digilocker/documents/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Fetch eAadhaar from DigiLocker (if available)
  static Future<Map<String, dynamic>> getEAadhaar(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/digilocker/eaadhaar/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {'available': false};
      }
      return {'available': false};
    } catch (e) {
      return {'available': false, 'error': e.toString()};
    }
  }

  /// Unlink DigiLocker from user account
  static Future<Map<String, dynamic>> unlink(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/digilocker/unlink'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return {'success': false, 'error': 'Unlink failed'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Check if eAadhaar is available and fetch it
  static Future<Map<String, dynamic>> verifyWithDigiLocker(String userId) async {
    final status = await getStatus(userId);
    
    if (status['linked'] != true) {
      return {
        'success': false,
        'needsAuth': true,
        'message': 'Please link DigiLocker first',
      };
    }

    final eaadhaar = await getEAadhaar(userId);
    
    if (eaadhaar['available'] == true) {
      return {
        'success': true,
        'verified': true,
        'documentType': 'eAadhaar',
        'data': eaadhaar,
      };
    }

    return {
      'success': false,
      'verified': false,
      'message': 'eAadhaar not found in DigiLocker',
    };
  }
}
