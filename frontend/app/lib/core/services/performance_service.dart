import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Wraps Firebase Performance to make it easy to trace custom operations
/// and HTTP requests throughout the app.
class PerformanceService {
  PerformanceService._();
  static final PerformanceService instance = PerformanceService._();

  final FirebasePerformance _perf = FirebasePerformance.instance;

  /// Start a custom trace. Call [stop] on the returned trace when done.
  ///
  /// ```dart
  /// final trace = await PerformanceService.instance.startTrace('load_candidates');
  /// // ... do work ...
  /// await trace.stop();
  /// ```
  Future<Trace> startTrace(String name) async {
    final trace = _perf.newTrace(name);
    await trace.start();
    return trace;
  }

  /// Convenience: run [work] inside a named trace and return its result.
  Future<T> trace<T>(String name, Future<T> Function() work) async {
    final t = _perf.newTrace(name);
    await t.start();
    try {
      final result = await work();
      t.putAttribute('success', 'true');
      return result;
    } catch (e) {
      t.putAttribute('success', 'false');
      t.putAttribute('error', e.toString().substring(0, 100.clamp(0, e.toString().length)));
      rethrow;
    } finally {
      await t.stop();
    }
  }

  /// Create an HTTP metric for manual tracking of non-standard HTTP calls.
  HttpMetric newHttpMetric(String url, HttpMethod method) =>
      _perf.newHttpMetric(url, method);

  /// Enable / disable collection at runtime (e.g. based on user consent).
  Future<void> setEnabled(bool enabled) async {
    await _perf.setPerformanceCollectionEnabled(enabled);
    if (kDebugMode) debugPrint('Performance collection: $enabled');
  }
}
