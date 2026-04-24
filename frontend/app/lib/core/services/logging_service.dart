import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warning(2, 'WARNING'),
  error(3, 'ERROR'),
  critical(4, 'CRITICAL');

  const LogLevel(this.value, this.name);
  final int value;
  final String name;
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;
  final Map<String, dynamic>? metadata;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.metadata,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'tag': tag,
      'metadata': metadata,
      'stackTrace': stackTrace?.toString(),
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      level: LogLevel.values.firstWhere((level) => level.name == json['level']),
      message: json['message'],
      tag: json['tag'],
      metadata: json['metadata'],
      stackTrace: json['stackTrace'] != null
          ? StackTrace.fromString(json['stackTrace'])
          : null,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer
        .write('[${DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(timestamp)}]');
    buffer.write('[${level.name}]');
    if (tag != null) buffer.write('[$tag]');
    buffer.write(' $message');

    if (metadata != null && metadata!.isNotEmpty) {
      buffer.write(' | Metadata: ${json.encode(metadata)}');
    }

    if (stackTrace != null) {
      buffer.write('\nStack Trace:\n$stackTrace');
    }

    return buffer.toString();
  }
}

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  late LogLevel _currentLogLevel;
  late bool _enableConsoleLogging;
  late bool _enableFileLogging;
  late bool _enableRemoteLogging;
  late int _maxFileSize;
  late int _maxFileCount;

  Directory? _logDirectory;
  File? _currentLogFile;
  final List<LogEntry> _memoryBuffer = [];
  final int _maxMemoryBuffer = 1000;

  Future<void> initialize({
    LogLevel logLevel = LogLevel.debug,
    bool enableConsoleLogging = true,
    bool enableFileLogging = true,
    bool enableRemoteLogging = false,
    int maxFileSize = 10 * 1024 * 1024, // 10MB
    int maxFileCount = 5,
  }) async {
    _currentLogLevel = logLevel;
    _enableConsoleLogging = enableConsoleLogging;
    _enableFileLogging = enableFileLogging;
    _enableRemoteLogging = enableRemoteLogging;
    _maxFileSize = maxFileSize;
    _maxFileCount = maxFileCount;

    if (_enableFileLogging) {
      await _initializeFileLogging();
    }
  }

  Future<void> _initializeFileLogging() async {
    final appDir = await getApplicationDocumentsDirectory();
    _logDirectory = Directory('${appDir.path}/logs');

    if (!await _logDirectory!.exists()) {
      await _logDirectory!.create(recursive: true);
    }

    await _rotateLogFiles();
    _currentLogFile = await _getCurrentLogFile();
  }

  void log(
    LogLevel level,
    String message, {
    String? tag,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
  }) {
    if (level.value < _currentLogLevel.value) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
      metadata: metadata,
      stackTrace: stackTrace,
    );

    _memoryBuffer.add(entry);
    if (_memoryBuffer.length > _maxMemoryBuffer) {
      _memoryBuffer.removeAt(0);
    }

    if (_enableConsoleLogging) {
      _logToConsole(entry);
    }

    if (_enableFileLogging) {
      _logToFile(entry);
    }

    if (_enableRemoteLogging) {
      _logToRemote(entry);
    }
  }

  void debug(String message, {String? tag, Map<String, dynamic>? metadata}) {
    log(LogLevel.debug, message, tag: tag, metadata: metadata);
  }

  void info(String message, {String? tag, Map<String, dynamic>? metadata}) {
    log(LogLevel.info, message, tag: tag, metadata: metadata);
  }

  void warning(String message, {String? tag, Map<String, dynamic>? metadata}) {
    log(LogLevel.warning, message, tag: tag, metadata: metadata);
  }

  void error(String message,
      {String? tag, Map<String, dynamic>? metadata, StackTrace? stackTrace}) {
    log(LogLevel.error, message,
        tag: tag, metadata: metadata, stackTrace: stackTrace);
  }

  void critical(String message,
      {String? tag, Map<String, dynamic>? metadata, StackTrace? stackTrace}) {
    log(LogLevel.critical, message,
        tag: tag, metadata: metadata, stackTrace: stackTrace);
  }

  void _logToConsole(LogEntry entry) {
    if (kDebugMode) {
      debugPrint(entry.toString());
    }
  }

  Future<void> _logToFile(LogEntry entry) async {
    try {
      if (_currentLogFile == null) return;

      final logLine = '${entry.toString()}\n';
      await _currentLogFile!.writeAsString(logLine, mode: FileMode.append);

      // Check if file needs rotation
      final fileSize = await _currentLogFile!.length();
      if (fileSize > _maxFileSize) {
        await _rotateLogFiles();
        _currentLogFile = await _getCurrentLogFile();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to write to log file: $e');
    }
  }

  Future<void> _logToRemote(LogEntry entry) async {
    // In a real app, you would send logs to a remote logging service
    // like Firebase Crashlytics, Sentry, or a custom endpoint
    try {
      // Example: Send to remote service
      // await RemoteLoggingService.sendLog(entry);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to send log to remote service: $e');
    }
  }

  Future<File> _getCurrentLogFile() async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return File('${_logDirectory!.path}/app_log_$date.log');
  }

  Future<void> _rotateLogFiles() async {
    if (_logDirectory == null) return;

    final files = await _logDirectory!
        .list()
        .where((entity) => entity is File)
        .cast<File>()
        .toList();
    files
        .sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    // Remove old files if we have too many
    if (files.length > _maxFileCount) {
      for (int i = _maxFileCount; i < files.length; i++) {
        await files[i].delete();
      }
    }
  }

  Future<List<LogEntry>> getLogs({
    LogLevel? minLevel,
    DateTime? startDate,
    DateTime? endDate,
    String? tag,
  }) async {
    List<LogEntry> logs = List.from(_memoryBuffer);

    // Filter by level
    if (minLevel != null) {
      logs = logs.where((log) => log.level.value >= minLevel.value).toList();
    }

    // Filter by date range
    if (startDate != null) {
      logs = logs.where((log) => log.timestamp.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      logs = logs.where((log) => log.timestamp.isBefore(endDate)).toList();
    }

    // Filter by tag
    if (tag != null) {
      logs = logs.where((log) => log.tag == tag).toList();
    }

    return logs;
  }

  Future<List<LogEntry>> getLogsFromFile({
    LogLevel? minLevel,
    DateTime? startDate,
    DateTime? endDate,
    String? tag,
  }) async {
    if (_currentLogFile == null || !await _currentLogFile!.exists()) {
      return [];
    }

    try {
      final content = await _currentLogFile!.readAsString();
      final lines =
          content.split('\n').where((line) => line.isNotEmpty).toList();

      final logs = <LogEntry>[];
      for (final line in lines) {
        try {
          // Parse log line back to LogEntry (simplified parsing)
          final entry = _parseLogLine(line);
          if (entry != null) {
            logs.add(entry);
          }
        } catch (e) {
          // Skip malformed log lines
        }
      }

      // Apply filters
      if (minLevel != null) {
        logs.retainWhere((log) => log.level.value >= minLevel.value);
      }

      if (startDate != null) {
        logs.retainWhere((log) => log.timestamp.isAfter(startDate));
      }

      if (endDate != null) {
        logs.retainWhere((log) => log.timestamp.isBefore(endDate));
      }

      if (tag != null) {
        logs.retainWhere((log) => log.tag == tag);
      }

      return logs;
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to read logs from file: $e');
      return [];
    }
  }

  LogEntry? _parseLogLine(String line) {
    // Simplified log line parsing
    // In a real implementation, you'd want more robust parsing
    try {
      final timestampMatch = RegExp(r'\[([^\]]+)\]').firstMatch(line);
      final levelMatch = RegExp(r'\[([A-Z]+)\]').firstMatch(line);

      if (timestampMatch != null && levelMatch != null) {
        final timestamp = DateTime.parse(timestampMatch.group(1)!);
        final levelName = levelMatch.group(1)!;
        final level = LogLevel.values.firstWhere((l) => l.name == levelName);

        // Extract message (simplified)
        final messageStart = line.indexOf('] ', levelMatch.end) + 2;
        final message = line.substring(messageStart);

        return LogEntry(
          timestamp: timestamp,
          level: level,
          message: message,
        );
      }
    } catch (e) {
      // Parsing failed
    }

    return null;
  }

  Future<void> clearLogs() async {
    _memoryBuffer.clear();

    if (_logDirectory != null) {
      final files = await _logDirectory!
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();
      for (final file in files) {
        await file.delete();
      }
    }
  }

  Future<void> exportLogs() async {
    final logs = await getLogs();
    final exportData = logs.map((log) => log.toJson()).toList();

    final exportDir = await getApplicationDocumentsDirectory();
    final exportFile = File(
        '${exportDir.path}/logs_export_${DateTime.now().millisecondsSinceEpoch}.json');

    await exportFile.writeAsString(json.encode(exportData));
  }

  Future<Map<String, dynamic>> getLogStats() async {
    final logs = await getLogs();

    final levelCounts = <String, int>{};
    for (final level in LogLevel.values) {
      levelCounts[level.name] = 0;
    }

    for (final log in logs) {
      levelCounts[log.level.name] = (levelCounts[log.level.name] ?? 0) + 1;
    }

    return {
      'totalLogs': logs.length,
      'levelCounts': levelCounts,
      'memoryBufferSize': _memoryBuffer.length,
      'currentLogFile': _currentLogFile?.path,
      'logDirectory': _logDirectory?.path,
    };
  }

  // Performance logging
  void logPerformance(
    String operation,
    Duration duration, {
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    final performanceMetadata = <String, dynamic>{
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      ...?metadata,
    };

    info(
      'Performance: $operation completed in ${duration.inMilliseconds}ms',
      tag: tag ?? 'PERFORMANCE',
      metadata: performanceMetadata,
    );
  }

  // User action logging
  void logUserAction(
    String action,
    Map<String, dynamic>? context, {
    String? tag,
  }) {
    final userMetadata = <String, dynamic>{
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      ...?context,
    };

    info(
      'User Action: $action',
      tag: tag ?? 'USER_ACTION',
      metadata: userMetadata,
    );
  }

  // Error logging with context
  void logErrorWithContext(
    String message,
    dynamic error,
    StackTrace? stackTrace, {
    String? tag,
    Map<String, dynamic>? context,
  }) {
    final errorMetadata = <String, dynamic>{
      'error_type': error.runtimeType.toString(),
      'error_message': error.toString(),
      ...?context,
    };

    this.error(
      message,
      tag: tag,
      metadata: errorMetadata,
      stackTrace: stackTrace,
    );
  }
}

// Extension for easy performance measurement
extension PerformanceLogging on Future {
  Future<T> logPerformance<T>(
    String operation, {
    String? tag,
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await this as T;
      stopwatch.stop();

      LoggingService().logPerformance(
        operation,
        stopwatch.elapsed,
        tag: tag,
        metadata: metadata,
      );

      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();

      LoggingService().logErrorWithContext(
        'Performance: $operation failed',
        error,
        stackTrace,
        tag: tag,
        context: {
          'duration_ms': stopwatch.elapsed.inMilliseconds,
          ...?metadata,
        },
      );

      rethrow;
    }
  }
}

// Global logger instance
final logger = LoggingService();
