import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      // encryptedSharedPreferences is deprecated and will be ignored
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Encryption key generation
  String _generateEncryptionKey(String salt) {
    final bytes = utf8.encode('${salt}voteready_secret_key_2024');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Simple XOR encryption for demonstration
  // In production, use proper encryption libraries
  String _encrypt(String data, String key) {
    final dataBytes = utf8.encode(data);
    final keyBytes = utf8.encode(key);

    final encrypted = List<int>.generate(
      dataBytes.length,
      (i) => dataBytes[i] ^ keyBytes[i % keyBytes.length],
    );

    return base64.encode(encrypted);
  }

  String _decrypt(String encryptedData, String key) {
    final encrypted = base64.decode(encryptedData);
    final keyBytes = utf8.encode(key);

    final decrypted = List<int>.generate(
      encrypted.length,
      (i) => encrypted[i] ^ keyBytes[i % keyBytes.length],
    );

    return utf8.decode(decrypted);
  }

  // Secure storage methods
  Future<void> storeSecureData(String key, String value) async {
    try {
      final salt = _generateSalt();
      final encryptionKey = _generateEncryptionKey(salt);
      final encryptedValue = _encrypt(value, encryptionKey);

      await _secureStorage.write(key: key, value: encryptedValue);
      await _secureStorage.write(key: '${key}_salt', value: salt);
    } catch (e) {
      throw Exception('Failed to store secure data: $e');
    }
  }

  Future<String?> getSecureData(String key) async {
    try {
      final encryptedValue = await _secureStorage.read(key: key);
      final salt = await _secureStorage.read(key: '${key}_salt');

      if (encryptedValue == null || salt == null) return null;

      final encryptionKey = _generateEncryptionKey(salt);
      return _decrypt(encryptedValue, encryptionKey);
    } catch (e) {
      throw Exception('Failed to retrieve secure data: $e');
    }
  }

  Future<void> deleteSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
      await _secureStorage.delete(key: '${key}_salt');
    } catch (e) {
      throw Exception('Failed to delete secure data: $e');
    }
  }

  Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw Exception('Failed to clear secure data: $e');
    }
  }

  // Hashing utilities
  String hashPassword(String password, {String? salt}) {
    salt ??= _generateSalt();
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '$salt:$digest';
  }

  Future<bool> verifyPassword(String password, String hashedPassword) async {
    final parts = hashedPassword.split(':');
    if (parts.length != 2) return false;

    final salt = parts[0];
    final computedHash = hashPassword(password, salt: salt);

    return computedHash == hashedPassword;
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  // Token management
  Future<void> storeAuthToken(String token) async {
    await storeSecureData('auth_token', token);
  }

  Future<String?> getAuthToken() async {
    return await getSecureData('auth_token');
  }

  Future<void> deleteAuthToken() async {
    await deleteSecureData('auth_token');
  }

  // User session management
  Future<void> storeUserSession(Map<String, dynamic> userData) async {
    final userJson = json.encode(userData);
    await storeSecureData('user_session', userJson);
  }

  Future<Map<String, dynamic>?> getUserSession() async {
    final userJson = await getSecureData('user_session');
    if (userJson == null) return null;

    try {
      return json.decode(userJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteUserSession() async {
    await deleteSecureData('user_session');
  }

  // Biometric authentication
  Future<bool> isBiometricAvailable() async {
    // In a real app, you would use local_auth package
    // For now, return false as placeholder
    return false;
  }

  Future<bool> authenticateWithBiometrics() async {
    // In a real app, you would use local_auth package
    // For now, return true as placeholder
    return true;
  }

  // Security utilities
  String generateSecureId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure();
    final randomBytes = List<int>.generate(8, (i) => random.nextInt(256));
    final hash =
        sha256.convert([...utf8.encode(timestamp.toString()), ...randomBytes]);
    return hash.toString().substring(0, 16);
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  bool isValidPhone(String phone) {
    return RegExp(r'^[6-9]\d{9}$')
        .hasMatch(phone.replaceAll(RegExp(r'[^\d]'), ''));
  }

  // Data sanitization
  String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[^\w\s@.-]'),
            ''); // Remove special characters except email chars
  }

  // Rate limiting
  final Map<String, List<DateTime>> _rateLimitCache = {};

  bool isRateLimited(String identifier,
      {int maxAttempts = 5, Duration window = const Duration(minutes: 5)}) {
    final now = DateTime.now();
    final attempts = _rateLimitCache[identifier] ?? [];

    // Remove old attempts outside the window
    attempts.removeWhere((time) => now.difference(time) > window);

    if (attempts.length >= maxAttempts) {
      return true;
    }

    attempts.add(now);
    _rateLimitCache[identifier] = attempts;
    return false;
  }

  void clearRateLimit(String identifier) {
    _rateLimitCache.remove(identifier);
  }

  // Security audit log
  Future<void> logSecurityEvent(
      String event, Map<String, dynamic>? metadata) async {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'event': event,
      'metadata': metadata ?? {},
    };

    // In production, send to secure logging service
    // Use debugPrint instead of print in production code
    debugPrint('SECURITY LOG: ${json.encode(logEntry)}');
  }

  // Device fingerprinting for additional security
  String generateDeviceFingerprint() {
    // In a real app, you would collect device-specific information
    // For now, generate a simple fingerprint
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random();
    final fingerprint = '${timestamp}_${random.nextInt(10000)}';
    return sha256.convert(utf8.encode(fingerprint)).toString();
  }
}

// Security constants
class SecurityConstants {
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration sessionTimeout = Duration(hours: 24);
  static const int passwordMinLength = 8;
  static const int passwordMaxLength = 128;
}

// Security exceptions
class SecurityException implements Exception {
  final String message;
  final String? code;

  const SecurityException(this.message, {this.code});

  @override
  String toString() =>
      'SecurityException: $message${code != null ? ' (Code: $code)' : ''}';
}

class AuthenticationException extends SecurityException {
  const AuthenticationException(super.message, {super.code});
}

class AuthorizationException extends SecurityException {
  const AuthorizationException(super.message, {super.code});
}

class RateLimitException extends SecurityException {
  const RateLimitException(super.message, {super.code});
}
