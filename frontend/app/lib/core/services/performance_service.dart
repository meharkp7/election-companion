import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PerformanceMetric {
  appStartupTime,
  screenLoadTime,
  apiResponseTime,
  memoryUsage,
  cpuUsage,
  batteryUsage,
  networkLatency,
  frameRate,
  renderTime,
}

class PerformanceData {
  final PerformanceMetric metric;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const PerformanceData({
    required this.metric,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'metric': metric.name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class PerformanceReport {
  final Map<PerformanceMetric, List<PerformanceData>> metrics;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, dynamic> summary;

  const PerformanceReport({
    required this.metrics,
    required this.startTime,
    required this.endTime,
    required this.summary,
  });

  Duration get duration => endTime.difference(startTime);

  List<PerformanceData> getMetricData(PerformanceMetric metric) {
    return metrics[metric] ?? [];
  }

  double? getAverageMetric(PerformanceMetric metric) {
    final data = getMetricData(metric);
    if (data.isEmpty) return null;

    final total = data.fold<double>(0.0, (sum, d) => sum + d.value);
    return total / data.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'metrics': metrics.map((key, value) =>
          MapEntry(key.name, value.map((v) => v.toJson()).toList())),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'summary': summary,
    };
  }
}

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<PerformanceMetric, List<PerformanceData>> _performanceData = {};
  final List<PerformanceReport> _reports = [];
  final Map<String, DateTime> _startTimes = {};

  DateTime? _appStartTime;
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  static const Duration _monitoringInterval = Duration(seconds: 5);
  static const int _maxDataPoints = 1000;

  Future<void> initialize() async {
    _appStartTime = DateTime.now();
    await _loadSavedData();
    _startMonitoring();

    // Record app startup time
    if (_appStartTime != null) {
      final startupTime =
          DateTime.now().difference(_appStartTime!).inMilliseconds.toDouble();
      recordMetric(PerformanceMetric.appStartupTime, startupTime, 'ms');
    }
  }

  void _startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      _collectSystemMetrics();
    });
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  void recordMetric(
    PerformanceMetric metric,
    double value,
    String unit, {
    Map<String, dynamic>? metadata,
  }) {
    final data = PerformanceData(
      metric: metric,
      value: value,
      unit: unit,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _performanceData.putIfAbsent(metric, () => []).add(data);

    // Limit data points to prevent memory issues
    if (_performanceData[metric]!.length > _maxDataPoints) {
      _performanceData[metric]!.removeAt(0);
    }

    // Log in debug mode
    if (kDebugMode) {
      debugPrint('Performance: ${metric.name} = $value$unit');
    }
  }

  void startTimer(String operation) {
    _startTimes[operation] = DateTime.now();
  }

  double? endTimer(String operation, {String? unit}) {
    final startTime = _startTimes[operation];
    if (startTime == null) return null;

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    _startTimes.remove(operation);

    final value = duration.inMilliseconds.toDouble();
    recordMetric(
      PerformanceMetric.renderTime,
      value,
      unit ?? 'ms',
      metadata: {'operation': operation},
    );

    return value;
  }

  Future<T> measureOperation<T>(
    PerformanceMetric metric,
    Future<T> Function() operation, {
    String? unit,
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();

      recordMetric(
        metric,
        stopwatch.elapsedMilliseconds.toDouble(),
        unit ?? 'ms',
        metadata: metadata,
      );

      return result;
    } catch (error) {
      stopwatch.stop();

      recordMetric(
        metric,
        stopwatch.elapsedMilliseconds.toDouble(),
        unit ?? 'ms',
        metadata: {
          ...?metadata,
          'error': error.toString(),
          'failed': true,
        },
      );

      rethrow;
    }
  }

  void _collectSystemMetrics() {
    if (!_isMonitoring) return;

    // Memory usage (simplified)
    if (kDebugMode) {
      developer.log('Collecting system metrics');
    }

    // In a real implementation, you would use platform-specific APIs
    // to get actual system metrics

    recordMetric(
      PerformanceMetric.memoryUsage,
      _getMemoryUsage(),
      'MB',
    );

    recordMetric(
      PerformanceMetric.frameRate,
      _getFrameRate(),
      'fps',
    );
  }

  double _getMemoryUsage() {
    // Simplified memory usage calculation
    // In a real implementation, you would use platform-specific APIs
    return (DateTime.now().millisecondsSinceEpoch % 100) + 50.0;
  }

  double _getFrameRate() {
    // Simplified frame rate calculation
    // In a real implementation, you would use Flutter's performance overlay
    return 60.0 - (DateTime.now().millisecondsSinceEpoch % 10);
  }

  PerformanceReport generateReport({
    DateTime? startTime,
    DateTime? endTime,
  }) {
    final now = DateTime.now();
    final reportStart = startTime ?? now.subtract(const Duration(hours: 1));
    final reportEnd = endTime ?? now;

    final filteredMetrics = <PerformanceMetric, List<PerformanceData>>{};

    for (final entry in _performanceData.entries) {
      final filteredData = entry.value
          .where((data) =>
              data.timestamp.isAfter(reportStart) &&
              data.timestamp.isBefore(reportEnd))
          .toList();

      if (filteredData.isNotEmpty) {
        filteredMetrics[entry.key] = filteredData;
      }
    }

    final summary = _generateSummary(filteredMetrics);

    final report = PerformanceReport(
      metrics: filteredMetrics,
      startTime: reportStart,
      endTime: reportEnd,
      summary: summary,
    );

    _reports.add(report);
    return report;
  }

  Map<String, dynamic> _generateSummary(
      Map<PerformanceMetric, List<PerformanceData>> metrics) {
    final summary = <String, dynamic>{};

    for (final entry in metrics.entries) {
      final metric = entry.key;
      final data = entry.value;

      if (data.isEmpty) continue;

      final values = data.map((d) => d.value).toList();
      values.sort();

      summary[metric.name] = {
        'count': values.length,
        'average': values.reduce((a, b) => a + b) / values.length,
        'min': values.first,
        'max': values.last,
        'median': values[values.length ~/ 2],
      };
    }

    return summary;
  }

  Future<void> saveReport(PerformanceReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = jsonEncode(report.toJson());
      await prefs.setString(
          'performance_report_${DateTime.now().millisecondsSinceEpoch}',
          reportsJson);
    } catch (e) {
      debugPrint('Failed to save performance report: $e');
    }
  }

  Future<void> _loadSavedData() async {
    try {
      await SharedPreferences.getInstance();
      // Load saved performance data if needed
    } catch (e) {
      debugPrint('Failed to load saved performance data: $e');
    }
  }

  void clearData() {
    _performanceData.clear();
    _reports.clear();
    _startTimes.clear();
  }

  Map<PerformanceMetric, List<PerformanceData>> get allData =>
      Map.from(_performanceData);

  List<PerformanceReport> get reports => List.from(_reports);

  bool get isMonitoring => _isMonitoring;

  // Performance optimization suggestions
  List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];

    final avgMemory = getAverageMetric(PerformanceMetric.memoryUsage);
    if (avgMemory != null && avgMemory > 200) {
      suggestions.add(
          'High memory usage detected. Consider implementing memory optimization strategies.');
    }

    final avgFrameRate = getAverageMetric(PerformanceMetric.frameRate);
    if (avgFrameRate != null && avgFrameRate < 55) {
      suggestions.add(
          'Low frame rate detected. Consider optimizing UI rendering and reducing widget rebuilds.');
    }

    final avgApiTime = getAverageMetric(PerformanceMetric.apiResponseTime);
    if (avgApiTime != null && avgApiTime > 2000) {
      suggestions.add(
          'Slow API response times. Consider implementing caching and request optimization.');
    }

    final avgRenderTime = getAverageMetric(PerformanceMetric.renderTime);
    if (avgRenderTime != null && avgRenderTime > 16) {
      suggestions.add(
          'Slow render times detected. Consider optimizing widget trees and using const constructors.');
    }

    return suggestions;
  }

  double? getAverageMetric(PerformanceMetric metric) {
    final data = _performanceData[metric];
    if (data == null || data.isEmpty) return null;

    final total = data.fold<double>(0.0, (sum, d) => sum + d.value);
    return total / data.length;
  }

  // Performance profiling
  void startProfile(String name) {
    if (kDebugMode) {
      print('Starting profile: $name');
      // Note: Use Flutter DevTools for profiling instead
    }
  }

  void stopProfile(String name) {
    if (kDebugMode) {
      print('Stopping profile: $name');
      // Note: Use Flutter DevTools for profiling instead
    }
  }

  // Memory optimization
  void forceGarbageCollection() {
    // In a real implementation, you would use platform-specific APIs
    if (kDebugMode) {
      debugPrint('Forcing garbage collection');
    }
  }

  // Widget performance monitoring
  Widget monitorWidgetPerformance(
    String widgetName,
    Widget child,
  ) {
    return Builder(
      builder: (context) {
        return PerformanceOverlay.allEnabled();
      },
    );
  }

  // Start performance monitoring
  void startMonitoring() {
    if (kDebugMode) {
      print('Starting performance monitoring');
    }
    _startMonitoring();
  }
}

// Performance monitoring widget
class PerformanceMonitor extends ConsumerStatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  ConsumerState<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends ConsumerState<PerformanceMonitor> {
  late PerformanceService _performanceService;

  @override
  void initState() {
    super.initState();
    _performanceService = PerformanceService();

    if (widget.enabled) {
      _performanceService.startMonitoring();
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      _performanceService.stopMonitoring();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Performance-aware widget base class
abstract class PerformanceAwareWidget extends StatefulWidget {
  const PerformanceAwareWidget({super.key});

  @override
  State<PerformanceAwareWidget> createState();
}

abstract class PerformanceAwareWidgetState<T extends PerformanceAwareWidget>
    extends State<T> {
  final PerformanceService _performanceService = PerformanceService();
  String get widgetName => runtimeType.toString();

  @override
  void initState() {
    super.initState();
    _performanceService.startTimer('${widgetName}_init');
  }

  @override
  void dispose() {
    _performanceService.endTimer('${widgetName}_init');
    super.dispose();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _performanceService.startTimer('${widgetName}_update');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _performanceService.endTimer('${widgetName}_update');
  }

  void recordPerformance(PerformanceMetric metric, double value, String unit) {
    _performanceService.recordMetric(metric, value, unit, metadata: {
      'widget': widgetName,
    });
  }
}

// Extension for easy performance measurement
extension PerformanceExtension on Future {
  Future<T> withPerformanceTracking<T>(
    PerformanceMetric metric,
    String operationName, {
    Map<String, dynamic>? metadata,
  }) async {
    final performanceService = PerformanceService();
    return await performanceService.measureOperation(
      metric,
      () async => await this as T,
      metadata: {
        'operation': operationName,
        ...?metadata,
      },
    );
  }
}

// Performance provider for Riverpod
final performanceServiceProvider = Provider<PerformanceService>((ref) {
  return PerformanceService();
});

// Performance report screen
class PerformanceReportScreen extends ConsumerWidget {
  const PerformanceReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceService = ref.watch(performanceServiceProvider);
    final report = performanceService.generateReport();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Report'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Report Summary',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16.0),
          Text('Duration: ${report.duration.inMinutes} minutes'),
          Text('Metrics Tracked: ${report.metrics.length}'),
          const SizedBox(height: 24.0),
          ...report.metrics.entries.map((entry) {
            final metric = entry.key;
            final data = entry.value;
            final average = report.getAverageMetric(metric);

            return Card(
              child: ListTile(
                title: Text(metric.name),
                subtitle: Text('Data points: ${data.length}'),
                trailing: Text(
                  average != null ? average.toStringAsFixed(2) : 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
          const SizedBox(height: 24.0),
          const Text(
            'Optimization Suggestions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...performanceService.getOptimizationSuggestions().map(
                (suggestion) => ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: Text(suggestion),
                ),
              ),
        ],
      ),
    );
  }
}
