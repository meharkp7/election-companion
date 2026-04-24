import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/services/error_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl =
      'https://voter-assistant-backend-260506723580.asia-south1.run.app/api';
  static const Duration timeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    int? maxRetries,
    bool authenticated = true,
  }) async {
    return _makeRequest(
      () async => http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await (authenticated
            ? _buildHeadersWithAuth()
            : Future.value(_buildHeaders(headers))),
      ),
      maxRetries: maxRetries ?? ApiService.maxRetries,
    );
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
    int? maxRetries,
    bool authenticated = true,
  }) async {
    return _makeRequest(
      () async => http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await (authenticated
            ? _buildHeadersWithAuth()
            : Future.value(_buildHeaders(headers))),
        body: json.encode(data),
      ),
      maxRetries: maxRetries ?? ApiService.maxRetries,
    );
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
    int? maxRetries,
    bool authenticated = true,
  }) async {
    return _makeRequest(
      () async => http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await (authenticated
            ? _buildHeadersWithAuth()
            : Future.value(_buildHeaders(headers))),
        body: json.encode(data),
      ),
      maxRetries: maxRetries ?? ApiService.maxRetries,
    );
  }

  static Future<void> delete(
    String endpoint, {
    Map<String, String>? headers,
    int? maxRetries,
    bool authenticated = true,
  }) async {
    await _makeRequest(
      () async => http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await (authenticated
            ? _buildHeadersWithAuth()
            : Future.value(_buildHeaders(headers))),
      ),
      maxRetries: maxRetries ?? ApiService.maxRetries,
    );
  }

  static Future<Map<String, dynamic>> _makeRequest(
    Future<http.Response> Function() requestFunction, {
    required int maxRetries,
  }) async {
    AppError? lastError;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await requestFunction().timeout(timeout);
        return _handleResponse(response);
      } catch (error, stackTrace) {
        lastError = ErrorService().handleError(error, stackTrace);

        if (attempt == maxRetries) {
          break;
        }

        // Exponential backoff
        await Future.delayed(Duration(milliseconds: 1000 * (1 << attempt)));
      }
    }

    throw lastError ??
        const AppError(
          message: 'Unknown error occurred',
          type: AppErrorType.unknown,
        );
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        try {
          return json.decode(response.body);
        } catch (e) {
          throw AppError(
            message: 'Invalid response format',
            type: AppErrorType.server,
            originalError: e,
          );
        }
      case 204:
        return {};
      case 400:
        throw AppError(
          message: 'Bad request',
          type: AppErrorType.validation,
          code: response.statusCode.toString(),
        );
      case 401:
        throw AppError(
          message: 'Unauthorized',
          type: AppErrorType.authentication,
          code: response.statusCode.toString(),
        );
      case 403:
        throw AppError(
          message: 'Forbidden',
          type: AppErrorType.authentication,
          code: response.statusCode.toString(),
        );
      case 404:
        throw AppError(
          message: 'Not found',
          type: AppErrorType.server,
          code: response.statusCode.toString(),
        );
      case 500:
      case 502:
      case 503:
        throw AppError(
          message: 'Server error',
          type: AppErrorType.server,
          code: response.statusCode.toString(),
        );
      default:
        throw AppError(
          message: 'HTTP Error: ${response.statusCode}',
          type: AppErrorType.server,
          code: response.statusCode.toString(),
        );
    }
  }

  static Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  static Future<Map<String, String>> _buildHeadersWithAuth() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final token = await user.getIdToken(true); // 🔥 force refresh
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Utility methods for common API patterns
  static Future<List<T>> getList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, String>? headers,
  }) async {
    final response = await get(endpoint, headers: headers);
    final List<dynamic> data = response['data'] ?? response;
    return data.map((item) => fromJson(item as Map<String, dynamic>)).toList();
  }

  static Future<T> getSingle<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, String>? headers,
  }) async {
    final response = await get(endpoint, headers: headers);
    return fromJson(response['data'] ?? response);
  }
}
