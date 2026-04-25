import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum AnalyticsEventType {
  appOpen,
  appClose,
  screenView,
  userAction,
  error,
  performance,
  featureUsage,
  onboardingStep,
  formSubmission,
  apiCall,
}

class AnalyticsEvent {
  final String name;
  final AnalyticsEventType type;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final String? sessionId;
  final String? userId;

  AnalyticsEvent({
    required this.name,
    required this.type,
    this.parameters = const {},
    DateTime? timestamp,
    this.sessionId,
    this.userId,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'userId': userId,
    };
  }

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      name: json['name'],
      type: AnalyticsEventType.values.firstWhere((e) => e.name == json['type']),
      parameters: json['parameters'] ?? {},
      timestamp: DateTime.parse(json['timestamp']),
      sessionId: json['sessionId'],
      userId: json['userId'],
    );
  }
}

class UserProperties {
  final String userId;
  final String? email;
  final String? ageGroup;
  final String? state;
  final bool isFirstTimeVoter;
  final String appVersion;
  final String deviceModel;
  final String operatingSystem;
  final String operatingSystemVersion;
  final DateTime firstLaunchDate;
  final DateTime? lastActiveDate;
  final int totalSessions;
  final int totalScreenViews;

  const UserProperties({
    required this.userId,
    this.email,
    this.ageGroup,
    this.state,
    required this.isFirstTimeVoter,
    required this.appVersion,
    required this.deviceModel,
    required this.operatingSystem,
    required this.operatingSystemVersion,
    required this.firstLaunchDate,
    this.lastActiveDate,
    this.totalSessions = 0,
    this.totalScreenViews = 0,
  });

  UserProperties copyWith({
    String? email,
    String? ageGroup,
    String? state,
    bool? isFirstTimeVoter,
    DateTime? lastActiveDate,
    int? totalSessions,
    int? totalScreenViews,
  }) {
    return UserProperties(
      userId: userId,
      email: email ?? this.email,
      ageGroup: ageGroup ?? this.ageGroup,
      state: state ?? this.state,
      isFirstTimeVoter: isFirstTimeVoter ?? this.isFirstTimeVoter,
      appVersion: appVersion,
      deviceModel: deviceModel,
      operatingSystem: operatingSystem,
      operatingSystemVersion: operatingSystemVersion,
      firstLaunchDate: firstLaunchDate,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      totalSessions: totalSessions ?? this.totalSessions,
      totalScreenViews: totalScreenViews ?? this.totalScreenViews,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'ageGroup': ageGroup,
      'state': state,
      'isFirstTimeVoter': isFirstTimeVoter,
      'appVersion': appVersion,
      'deviceModel': deviceModel,
      'operatingSystem': operatingSystem,
      'operatingSystemVersion': operatingSystemVersion,
      'firstLaunchDate': firstLaunchDate.toIso8601String(),
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'totalSessions': totalSessions,
      'totalScreenViews': totalScreenViews,
    };
  }
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late UserProperties _userProperties;
  late String _sessionId;
  final List<AnalyticsEvent> _eventBuffer = [];
  final List<AnalyticsEvent> _offlineEvents = [];
  bool _isInitialized = false;
  bool _isOnline = true;
  final int _maxBufferSize = 100;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadUserProperties();
      _sessionId = _generateSessionId();
      await _updateSessionInfo();

      // Start periodic flush
      _startPeriodicFlush();

      _isInitialized = true;

      // Track app open
      trackEvent('app_open', AnalyticsEventType.appOpen, parameters: {
        'session_id': _sessionId,
        'is_first_launch': _userProperties.totalSessions == 1,
      });
    } catch (e) {
      if (kDebugMode) print('Failed to initialize analytics: $e');
    }
  }

  Future<void> _loadUserProperties() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('analytics_user_id') ?? _generateUserId();

    // Save user ID if it's new
    if (prefs.getString('analytics_user_id') == null) {
      await prefs.setString('analytics_user_id', userId);
    }

    final firstLaunchDateStr = prefs.getString('first_launch_date');
    final firstLaunchDate = firstLaunchDateStr != null
        ? DateTime.parse(firstLaunchDateStr)
        : DateTime.now();

    if (firstLaunchDateStr == null) {
      await prefs.setString(
          'first_launch_date', firstLaunchDate.toIso8601String());
    }

    _userProperties = UserProperties(
      userId: userId,
      email: prefs.getString('user_email'),
      ageGroup: prefs.getString('user_age_group'),
      state: prefs.getString('user_state'),
      isFirstTimeVoter: prefs.getBool('is_first_time_voter') ?? false,
      appVersion: '1.0.0', // Get from package info
      deviceModel: Platform.isIOS ? 'iOS' : 'Android',
      operatingSystem: Platform.operatingSystem,
      operatingSystemVersion: Platform.operatingSystemVersion,
      firstLaunchDate: firstLaunchDate,
      lastActiveDate: DateTime.now(),
      totalSessions: prefs.getInt('total_sessions') ?? 0,
      totalScreenViews: prefs.getInt('total_screen_views') ?? 0,
    );
  }

  Future<void> _updateSessionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final totalSessions = _userProperties.totalSessions + 1;

    _userProperties = _userProperties.copyWith(
      lastActiveDate: DateTime.now(),
      totalSessions: totalSessions,
    );

    await prefs.setInt('total_sessions', totalSessions);
    await prefs.setString('last_active_date', DateTime.now().toIso8601String());
  }

  void trackEvent(
    String name,
    AnalyticsEventType type, {
    Map<String, dynamic> parameters = const {},
  }) {
    if (!_isInitialized) return;

    final event = AnalyticsEvent(
      name: name,
      type: type,
      parameters: parameters,
      sessionId: _sessionId,
      userId: _userProperties.userId,
    );

    _eventBuffer.add(event);

    // Flush immediately for critical events
    if (_isCriticalEvent(type)) {
      _flushEvents();
    }

    // Flush if buffer is full
    if (_eventBuffer.length >= _maxBufferSize) {
      _flushEvents();
    }
  }

  void trackScreenView(String screenName,
      {Map<String, dynamic> parameters = const {}}) {
    trackEvent(
      'screen_view',
      AnalyticsEventType.screenView,
      parameters: {
        'screen_name': screenName,
        ...parameters,
      },
    );

    _updateScreenViewCount();
  }

  void trackUserAction(String action,
      {Map<String, dynamic> parameters = const {}}) {
    trackEvent(
      'user_action',
      AnalyticsEventType.userAction,
      parameters: {
        'action': action,
        ...parameters,
      },
    );
  }

  void trackError(String error,
      {String? stackTrace, Map<String, dynamic> parameters = const {}}) {
    trackEvent(
      'error',
      AnalyticsEventType.error,
      parameters: {
        'error': error,
        'stack_trace': stackTrace,
        ...parameters,
      },
    );
  }

  void trackPerformance(String operation, Duration duration,
      {Map<String, dynamic> parameters = const {}}) {
    trackEvent(
      'performance',
      AnalyticsEventType.performance,
      parameters: {
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        ...parameters,
      },
    );
  }

  void trackFeatureUsage(String feature,
      {Map<String, dynamic> parameters = const {}}) {
    trackEvent(
      'feature_usage',
      AnalyticsEventType.featureUsage,
      parameters: {
        'feature': feature,
        ...parameters,
      },
    );
  }

  void trackOnboardingStep(String step,
      {Map<String, dynamic> parameters = const {}}) {
    trackEvent(
      'onboarding_step',
      AnalyticsEventType.onboardingStep,
      parameters: {
        'step': step,
        ...parameters,
      },
    );
  }

  void trackFormSubmission(String formName, bool success,
      {Map<String, dynamic> parameters = const {}}) {
    trackEvent(
      'form_submission',
      AnalyticsEventType.formSubmission,
      parameters: {
        'form_name': formName,
        'success': success,
        ...parameters,
      },
    );
  }

  void trackApiCall(String endpoint, int statusCode, Duration duration,
      {Map<String, dynamic> parameters = const {}}) {
    trackEvent(
      'api_call',
      AnalyticsEventType.apiCall,
      parameters: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'duration_ms': duration.inMilliseconds,
        ...parameters,
      },
    );
  }

  void updateUserProperties({
    String? email,
    String? ageGroup,
    String? state,
    bool? isFirstTimeVoter,
  }) async {
    _userProperties = _userProperties.copyWith(
      email: email,
      ageGroup: ageGroup,
      state: state,
      isFirstTimeVoter: isFirstTimeVoter,
    );

    final prefs = await SharedPreferences.getInstance();

    if (email != null) await prefs.setString('user_email', email);
    if (ageGroup != null) await prefs.setString('user_age_group', ageGroup);
    if (state != null) await prefs.setString('user_state', state);
    if (isFirstTimeVoter != null) {
      await prefs.setBool('is_first_time_voter', isFirstTimeVoter);
    }

    // Send user properties update event
    trackEvent('user_properties_updated', AnalyticsEventType.userAction,
        parameters: {
          'email': email,
          'ageGroup': ageGroup,
          'state': state,
          'isFirstTimeVoter': isFirstTimeVoter,
        });
  }

  Future<void> _updateScreenViewCount() async {
    final prefs = await SharedPreferences.getInstance();
    final totalScreenViews = _userProperties.totalScreenViews + 1;

    _userProperties =
        _userProperties.copyWith(totalScreenViews: totalScreenViews);
    await prefs.setInt('total_screen_views', totalScreenViews);
  }

  bool _isCriticalEvent(AnalyticsEventType type) {
    return type == AnalyticsEventType.error ||
        type == AnalyticsEventType.appClose;
  }

  Future<void> _flushEvents() async {
    if (_eventBuffer.isEmpty) return;

    final eventsToSend = List<AnalyticsEvent>.from(_eventBuffer);
    _eventBuffer.clear();

    try {
      await _sendEvents(eventsToSend);
    } catch (e) {
      // Add to offline buffer if sending fails
      _offlineEvents.addAll(eventsToSend);
      if (kDebugMode) print('Failed to send analytics events: $e');
    }
  }

  Future<void> _sendEvents(List<AnalyticsEvent> events) async {
    final fa = FirebaseAnalytics.instance;

    for (final event in events) {
      try {
        switch (event.type) {
          case AnalyticsEventType.screenView:
            await fa.logScreenView(
              screenName: event.parameters['screen_name']?.toString() ?? event.name,
            );
          case AnalyticsEventType.appOpen:
            await fa.logAppOpen();
          case AnalyticsEventType.error:
            // Also forward to Crashlytics as a non-fatal
            FirebaseCrashlytics.instance.recordError(
              event.parameters['error'] ?? event.name,
              null,
              reason: event.name,
              fatal: false,
            );
            await fa.logEvent(name: 'app_error', parameters: {
              'error_message': event.parameters['error']?.toString() ?? '',
            });
          default:
            // Sanitise: Firebase Analytics only allows a-z, 0-9, _ and max 40 chars
            final safeName = event.name
                .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
                .toLowerCase()
                .substring(0, event.name.length.clamp(0, 40));
            final safeParams = <String, Object>{};
            event.parameters.forEach((k, v) {
              if (v != null) safeParams[k] = v.toString();
            });
            await fa.logEvent(name: safeName, parameters: safeParams);
        }
      } catch (e) {
        if (kDebugMode) print('Analytics send error: $e');
      }
    }
  }

  void _startPeriodicFlush() {
    // In a real implementation, use Timer.periodic
    // For now, this is a placeholder
  }

  Future<void> setOnlineStatus(bool isOnline) async {
    _isOnline = isOnline;

    if (isOnline && _offlineEvents.isNotEmpty) {
      await _flushEvents();

      // Try to send offline events
      try {
        await _sendEvents(_offlineEvents);
        _offlineEvents.clear();
      } catch (e) {
        if (kDebugMode) print('Failed to send offline events: $e');
      }
    }
  }

  Future<void> flush() async {
    await _flushEvents();
  }

  Future<void> clearAllData() async {
    _eventBuffer.clear();
    _offlineEvents.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('analytics_user_id');
    await prefs.remove('first_launch_date');
    await prefs.remove('total_sessions');
    await prefs.remove('total_screen_views');
  }

  UserProperties get userProperties => _userProperties;
  String get sessionId => _sessionId;
  int get bufferedEventsCount => _eventBuffer.length;
  int get offlineEventsCount => _offlineEvents.length;

  String _generateUserId() {
    return const Uuid().v4();
  }

  String _generateSessionId() {
    return const Uuid().v4();
  }

  // Analytics insights
  Map<String, dynamic> getUserInsights() {
    return {
      'totalSessions': _userProperties.totalSessions,
      'totalScreenViews': _userProperties.totalScreenViews,
      'averageScreenViewsPerSession': _userProperties.totalSessions > 0
          ? _userProperties.totalScreenViews / _userProperties.totalSessions
          : 0,
      'daysSinceFirstLaunch':
          DateTime.now().difference(_userProperties.firstLaunchDate).inDays,
      'lastActiveDate': _userProperties.lastActiveDate?.toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> getEventStatistics() async {
    // In a real implementation, query analytics backend
    // For now, return basic statistics from current session

    return {
      'eventsInBuffer': _eventBuffer.length,
      'offlineEvents': _offlineEvents.length,
      'sessionId': _sessionId,
      'isOnline': _isOnline,
    };
  }
}

// Analytics provider for Riverpod
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

// Analytics mixin for easy tracking
mixin AnalyticsMixin {
  final AnalyticsService _analyticsService = AnalyticsService();

  void trackScreenView(String screenName,
      {Map<String, dynamic> parameters = const {}}) {
    _analyticsService.trackScreenView(screenName, parameters: parameters);
  }

  void trackUserAction(String action,
      {Map<String, dynamic> parameters = const {}}) {
    _analyticsService.trackUserAction(action, parameters: parameters);
  }

  void trackError(String error,
      {String? stackTrace, Map<String, dynamic> parameters = const {}}) {
    _analyticsService.trackError(error,
        stackTrace: stackTrace, parameters: parameters);
  }

  void trackPerformance(String operation, Duration duration,
      {Map<String, dynamic> parameters = const {}}) {
    _analyticsService.trackPerformance(operation, duration,
        parameters: parameters);
  }

  void trackFeatureUsage(String feature,
      {Map<String, dynamic> parameters = const {}}) {
    _analyticsService.trackFeatureUsage(feature, parameters: parameters);
  }
}

// Analytics-aware widget
class AnalyticsAwareWidget extends StatefulWidget {
  final Widget child;
  final String? screenName;

  const AnalyticsAwareWidget({
    super.key,
    required this.child,
    this.screenName,
  });

  @override
  State<AnalyticsAwareWidget> createState() => _AnalyticsAwareWidgetState();
}

class _AnalyticsAwareWidgetState extends State<AnalyticsAwareWidget>
    with WidgetsBindingObserver, AnalyticsMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.screenName != null) {
      trackScreenView(widget.screenName!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        trackUserAction('app_resumed');
        break;
      case AppLifecycleState.paused:
        trackUserAction('app_paused');
        break;
      case AppLifecycleState.detached:
        trackUserAction('app_closed');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
