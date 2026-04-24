import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;
  final String? etag;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
    this.etag,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl.inMilliseconds,
      'etag': etag,
    };
  }

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      ttl: Duration(milliseconds: json['ttl']),
      etag: json['etag'],
    );
  }
}

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  Directory? _cacheDir;
  final Map<String, CacheEntry> _memoryCache = {};

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _cacheDir = await getApplicationDocumentsDirectory();
  }

  // Memory cache operations
  void setMemoryCache(String key, dynamic data, Duration ttl) {
    _memoryCache[key] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl,
    );
  }

  T? getMemoryCache<T>(String key) {
    final entry = _memoryCache[key];
    if (entry == null || entry.isExpired) {
      _memoryCache.remove(key);
      return null;
    }
    return entry.data as T?;
  }

  void clearMemoryCache() {
    _memoryCache.clear();
  }

  void removeMemoryCache(String key) {
    _memoryCache.remove(key);
  }

  // Persistent cache operations
  Future<void> setCache(String key, dynamic data, Duration ttl, {String? etag}) async {
    if (_prefs == null) await initialize();

    final entry = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl,
      etag: etag,
    );

    await _prefs!.setString('cache_$key', json.encode(entry.toJson()));
  }

  Future<T?> getCache<T>(String key) async {
    if (_prefs == null) await initialize();

    final cached = _prefs!.getString('cache_$key');
    if (cached == null) return null;

    try {
      final entry = CacheEntry.fromJson(json.decode(cached));
      if (entry.isExpired) {
        await removeCache(key);
        return null;
      }
      return entry.data as T?;
    } catch (e) {
      if (kDebugMode) print('Error reading cache: $e');
      await removeCache(key);
      return null;
    }
  }

  Future<void> removeCache(String key) async {
    if (_prefs == null) await initialize();
    await _prefs!.remove('cache_$key');
  }

  Future<void> clearCache() async {
    if (_prefs == null) await initialize();
    final keys = _prefs!.getKeys().where((key) => key.startsWith('cache_'));
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }

  // File cache operations for large data
  Future<void> setFileCache(String key, dynamic data, Duration ttl) async {
    if (_cacheDir == null) await initialize();

    final file = File('${_cacheDir!.path}/cache_$key.json');
    final entry = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl,
    );

    await file.writeAsString(json.encode(entry.toJson()));
  }

  Future<T?> getFileCache<T>(String key) async {
    if (_cacheDir == null) await initialize();

    final file = File('${_cacheDir!.path}/cache_$key.json');
    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      final entry = CacheEntry.fromJson(json.decode(content));
      
      if (entry.isExpired) {
        await file.delete();
        return null;
      }
      
      return entry.data as T?;
    } catch (e) {
      if (kDebugMode) print('Error reading file cache: $e');
      await file.delete();
      return null;
    }
  }

  Future<void> removeFileCache(String key) async {
    if (_cacheDir == null) await initialize();
    
    final file = File('${_cacheDir!.path}/cache_$key.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  // HTTP caching with conditional requests
  Future<http.Response?> getCachedResponse(String url, {Duration? ttl}) async {
    final cacheKey = _generateCacheKey(url);
    final cached = await getCache<Map<String, dynamic>>(cacheKey);
    
    if (cached != null) {
      final headers = <String, String>{};
      if (cached['etag'] != null) {
        headers['If-None-Match'] = cached['etag'];
      }
      if (cached['lastModified'] != null) {
        headers['If-Modified-Since'] = cached['lastModified'];
      }
      
      try {
        final response = await http.get(Uri.parse(url), headers: headers);
        
        if (response.statusCode == 304) {
          // Not modified, return cached response
          return http.Response(
            cached['body'],
            200,
            headers: Map<String, String>.from(cached['headers']),
          );
        } else if (response.statusCode == 200) {
          // Update cache with new response
          await setCache(cacheKey, {
            'body': response.body,
            'headers': response.headers,
            'etag': response.headers['etag'],
            'lastModified': response.headers['last-modified'],
          }, ttl ?? const Duration(hours: 1));
          return response;
        }
      } catch (e) {
        // Network error, return cached response if available
        return http.Response(
          cached['body'],
          200,
          headers: Map<String, String>.from(cached['headers']),
        );
      }
    }
    
    return null;
  }

  Future<http.Response> fetchWithCache(
    String url, {
    Duration? ttl,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedResponse = await getCachedResponse(url, ttl: ttl);
      if (cachedResponse != null) {
        return cachedResponse;
      }
    }

    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final cacheKey = _generateCacheKey(url);
      await setCache(cacheKey, {
        'body': response.body,
        'headers': response.headers,
        'etag': response.headers['etag'],
        'lastModified': response.headers['last-modified'],
      }, ttl ?? const Duration(hours: 1));
    }
    
    return response;
  }

  // Offline support
  Future<bool> isOnline() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> syncOfflineData() async {
    // Implementation for syncing offline data when online
    // This would depend on your specific offline data requirements
  }

  // Cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    if (_prefs == null) await initialize();

    final keys = _prefs!.getKeys().where((key) => key.startsWith('cache_'));
    int totalSize = 0;
    int expiredCount = 0;
    int validCount = 0;

    for (final key in keys) {
      final cached = _prefs!.getString(key);
      if (cached != null) {
        totalSize += cached.length;
        try {
          final entry = CacheEntry.fromJson(json.decode(cached));
          if (entry.isExpired) {
            expiredCount++;
          } else {
            validCount++;
          }
        } catch (e) {
          expiredCount++;
        }
      }
    }

    return {
      'totalEntries': keys.length,
      'validEntries': validCount,
      'expiredEntries': expiredCount,
      'totalSizeBytes': totalSize,
      'memoryCacheSize': _memoryCache.length,
    };
  }

  // Cache cleanup
  Future<void> cleanupExpiredCache() async {
    if (_prefs == null) await initialize();

    final keys = _prefs!.getKeys().where((key) => key.startsWith('cache_'));
    
    for (final key in keys) {
      final cached = _prefs!.getString(key);
      if (cached != null) {
        try {
          final entry = CacheEntry.fromJson(json.decode(cached));
          if (entry.isExpired) {
            await _prefs!.remove(key);
          }
        } catch (e) {
          await _prefs!.remove(key);
        }
      }
    }

    // Clean memory cache
    final expiredKeys = <String>[];
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }
  }

  String _generateCacheKey(String url) {
    return base64.encode(utf8.encode(url)).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  // Cache warming
  Future<void> warmCache(List<String> urls, {Duration? ttl}) async {
    for (final url in urls) {
      try {
        await fetchWithCache(url, ttl: ttl);
      } catch (e) {
        if (kDebugMode) print('Failed to warm cache for $url: $e');
      }
    }
  }

  // Batch operations
  Future<Map<String, T?>> getBatchCache<T>(List<String> keys) async {
    final results = <String, T?>{};
    
    for (final key in keys) {
      results[key] = await getCache<T>(key);
    }
    
    return results;
  }

  Future<void> setBatchCache<T>(Map<String, T> data, Duration ttl) async {
    for (final entry in data.entries) {
      await setCache(entry.key, entry.value, ttl);
    }
  }
}

// Cache configuration
class CacheConfig {
  static const Duration shortTtl = Duration(minutes: 5);
  static const Duration mediumTtl = Duration(hours: 1);
  static const Duration longTtl = Duration(days: 1);
  static const Duration veryLongTtl = Duration(days: 7);

  static const int maxMemoryCacheSize = 100;
  static const int maxFileCacheSize = 1000;
}

// Cache exceptions
class CacheException implements Exception {
  final String message;
  final String? code;
  
  const CacheException(this.message, {this.code});
  
  @override
  String toString() => 'CacheException: $message${code != null ? ' (Code: $code)' : ''}';
}
