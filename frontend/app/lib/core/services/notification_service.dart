import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

enum NotificationType {
  electionReminder,
  votingDayAlert,
  resultUpdate,
  applicationStatus,
  generalInfo,
  emergency,
}

class NotificationData {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final String? actionUrl;

  const NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.data,
    this.imageUrl,
    this.actionUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values.firstWhere((t) => t.name == json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      data: json['data'],
      imageUrl: json['imageUrl'],
      actionUrl: json['actionUrl'],
    );
  }
}

class NotificationPreferences {
  final bool electionReminders;
  final bool votingDayAlerts;
  final bool resultUpdates;
  final bool applicationStatusUpdates;
  final bool generalInfo;
  final bool emergencyAlerts;
  final bool quietHoursEnabled;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;

  const NotificationPreferences({
    this.electionReminders = true,
    this.votingDayAlerts = true,
    this.resultUpdates = true,
    this.applicationStatusUpdates = true,
    this.generalInfo = false,
    this.emergencyAlerts = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = const TimeOfDay(hour: 22, minute: 0),
    this.quietHoursEnd = const TimeOfDay(hour: 8, minute: 0),
  });

  NotificationPreferences copyWith({
    bool? electionReminders,
    bool? votingDayAlerts,
    bool? resultUpdates,
    bool? applicationStatusUpdates,
    bool? generalInfo,
    bool? emergencyAlerts,
    bool? quietHoursEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
  }) {
    return NotificationPreferences(
      electionReminders: electionReminders ?? this.electionReminders,
      votingDayAlerts: votingDayAlerts ?? this.votingDayAlerts,
      resultUpdates: resultUpdates ?? this.resultUpdates,
      applicationStatusUpdates:
          applicationStatusUpdates ?? this.applicationStatusUpdates,
      generalInfo: generalInfo ?? this.generalInfo,
      emergencyAlerts: emergencyAlerts ?? this.emergencyAlerts,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'electionReminders': electionReminders,
      'votingDayAlerts': votingDayAlerts,
      'resultUpdates': resultUpdates,
      'applicationStatusUpdates': applicationStatusUpdates,
      'generalInfo': generalInfo,
      'emergencyAlerts': emergencyAlerts,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': '${quietHoursStart.hour}:${quietHoursStart.minute}',
      'quietHoursEnd': '${quietHoursEnd.hour}:${quietHoursEnd.minute}',
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      electionReminders: json['electionReminders'] ?? true,
      votingDayAlerts: json['votingDayAlerts'] ?? true,
      resultUpdates: json['resultUpdates'] ?? true,
      applicationStatusUpdates: json['applicationStatusUpdates'] ?? true,
      generalInfo: json['generalInfo'] ?? false,
      emergencyAlerts: json['emergencyAlerts'] ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] ?? false,
      quietHoursStart: _parseTimeOfDay(json['quietHoursStart'] ?? '22:00'),
      quietHoursEnd: _parseTimeOfDay(json['quietHoursEnd'] ?? '08:00'),
    );
  }

  static TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  bool shouldShowNotification(NotificationType type) {
    switch (type) {
      case NotificationType.electionReminder:
        return electionReminders;
      case NotificationType.votingDayAlert:
        return votingDayAlerts;
      case NotificationType.resultUpdate:
        return resultUpdates;
      case NotificationType.applicationStatus:
        return applicationStatusUpdates;
      case NotificationType.generalInfo:
        return generalInfo;
      case NotificationType.emergency:
        return emergencyAlerts;
    }
  }

  bool isInQuietHours() {
    if (!quietHoursEnabled) return false;

    final now = TimeOfDay.now();
    final start = quietHoursStart;
    final end = quietHoursEnd;

    // Convert to minutes for comparison
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      // Same day period (e.g., 22:00 to 08:00 next day is handled below)
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // Overnight period (e.g., 22:00 to 08:00)
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  NotificationPreferences _preferences = const NotificationPreferences();
  final List<NotificationData> _notificationHistory = [];
  final StreamController<NotificationData> _notificationStream =
      StreamController.broadcast();

  String? _fcmToken;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      await _initializeLocalNotifications();
      await _initializeFirebaseMessaging();
      await _loadPreferences();
      await _requestPermissions();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize notification service: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Request permission
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        debugPrint('FCM Token refreshed: $token');
      });

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen for background messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString('notification_preferences');

      if (preferencesJson != null) {
        _preferences =
            NotificationPreferences.fromJson(json.decode(preferencesJson));
      }
    } catch (e) {
      debugPrint('Failed to load notification preferences: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notification_preferences',
        json.encode(_preferences.toJson()),
      );
    } catch (e) {
      debugPrint('Failed to save notification preferences: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      try {
        final notificationData =
            NotificationData.fromJson(json.decode(payload));
        _handleNotificationAction(notificationData);
      } catch (e) {
        debugPrint('Failed to parse notification payload: $e');
      }
    }
  }

  void _handleNotificationAction(NotificationData notification) {
    _notificationStream.add(notification);

    // Handle navigation based on notification type
    switch (notification.type) {
      case NotificationType.electionReminder:
        // Navigate to eligibility screen
        break;
      case NotificationType.votingDayAlert:
        // Navigate to voting day screen
        break;
      case NotificationType.resultUpdate:
        // Navigate to results screen
        break;
      case NotificationType.applicationStatus:
        // Navigate to registration status
        break;
      case NotificationType.generalInfo:
        // Navigate to relevant screen based on data
        break;
      case NotificationType.emergency:
        // Show emergency alert
        break;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      final notificationData = NotificationData(
        id: message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        type: _parseNotificationType(message.data['type']),
        timestamp: DateTime.now(),
        data: message.data,
        imageUrl: notification.android?.imageUrl,
        actionUrl: message.data['actionUrl'],
      );

      showLocalNotification(notificationData);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    // Handle background message
    _handleForegroundMessage(message);
  }

  NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'election_reminder':
        return NotificationType.electionReminder;
      case 'voting_day_alert':
        return NotificationType.votingDayAlert;
      case 'result_update':
        return NotificationType.resultUpdate;
      case 'application_status':
        return NotificationType.applicationStatus;
      case 'emergency':
        return NotificationType.emergency;
      default:
        return NotificationType.generalInfo;
    }
  }

  Future<void> showLocalNotification(NotificationData notification) async {
    // Check if notification should be shown based on preferences
    if (!_preferences.shouldShowNotification(notification.type)) {
      return;
    }

    // Check quiet hours (except for emergency notifications)
    if (_preferences.isInQuietHours() &&
        notification.type != NotificationType.emergency) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'vote_ready_channel',
      'VoteReady Notifications',
      channelDescription: 'Notifications from VoteReady app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: notification.imageUrl != null
          ? FilePathAndroidBitmap(notification.imageUrl!)
          : null,
      styleInformation: notification.imageUrl != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(notification.imageUrl!),
              contentTitle: notification.title,
              htmlFormatContentTitle: true,
              summaryText: notification.body,
              htmlFormatSummaryText: true,
            )
          : null,
      actions: notification.actionUrl != null
          ? [
              AndroidNotificationAction(
                'action',
                'View',
                showsUserInterface: true,
              ),
            ]
          : null,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
      attachments: notification.imageUrl != null
          ? [
              DarwinNotificationAttachment(
                notification.imageUrl!,
                hideThumbnail: false,
              ),
            ]
          : null,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: notification.id.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: json.encode(notification.toJson()),
    );

    // Add to history
    _notificationHistory.add(notification);

    // Limit history size
    if (_notificationHistory.length > 100) {
      _notificationHistory.removeAt(0);
    }
  }

  Future<void> scheduleNotification({
    required NotificationData notification,
    required DateTime scheduledTime,
  }) async {
    final androidDetails = const AndroidNotificationDetails(
      'vote_ready_channel',
      'VoteReady Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id: notification.id.hashCode,
      title: notification.title,
      body: notification.body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: details,
      payload: json.encode(notification.toJson()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(String id) async {
    await _localNotifications.cancel(id: id.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    _preferences = preferences;
    await _savePreferences();
  }

  NotificationPreferences get preferences => _preferences;

  List<NotificationData> get notificationHistory =>
      List.from(_notificationHistory);

  Stream<NotificationData> get notificationStream => _notificationStream.stream;

  String? get fcmToken => _fcmToken;

  bool get isInitialized => _isInitialized;

  // Predefined notification methods
  Future<void> sendElectionReminder({
    required String title,
    required String body,
    DateTime? scheduledTime,
  }) async {
    final notification = NotificationData(
      id: 'election_reminder_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: NotificationType.electionReminder,
      timestamp: DateTime.now(),
    );

    if (scheduledTime != null) {
      await scheduleNotification(
          notification: notification, scheduledTime: scheduledTime);
    } else {
      await showLocalNotification(notification);
    }
  }

  Future<void> sendVotingDayAlert({
    required String title,
    required String body,
    String? pollingStation,
  }) async {
    final notification = NotificationData(
      id: 'voting_day_alert_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: NotificationType.votingDayAlert,
      timestamp: DateTime.now(),
      data: {'pollingStation': pollingStation},
    );

    await showLocalNotification(notification);
  }

  Future<void> sendResultUpdate({
    required String title,
    required String body,
    String? constituency,
  }) async {
    final notification = NotificationData(
      id: 'result_update_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: NotificationType.resultUpdate,
      timestamp: DateTime.now(),
      data: {'constituency': constituency},
      actionUrl: '/results',
    );

    await showLocalNotification(notification);
  }

  Future<void> sendApplicationStatusUpdate({
    required String title,
    required String body,
    required String status,
  }) async {
    final notification = NotificationData(
      id: 'application_status_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: NotificationType.applicationStatus,
      timestamp: DateTime.now(),
      data: {'status': status},
      actionUrl: '/registration/status',
    );

    await showLocalNotification(notification);
  }

  Future<void> sendEmergencyAlert({
    required String title,
    required String body,
    String? emergencyType,
  }) async {
    final notification = NotificationData(
      id: 'emergency_alert_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: NotificationType.emergency,
      timestamp: DateTime.now(),
      data: {'emergencyType': emergencyType},
    );

    await showLocalNotification(notification);
  }

  Future<void> sendGeneralInfo({
    required String title,
    required String body,
    String? imageUrl,
    String? actionUrl,
  }) async {
    final notification = NotificationData(
      id: 'general_info_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: NotificationType.generalInfo,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
      actionUrl: actionUrl,
    );

    await showLocalNotification(notification);
  }

  // Notification statistics
  Map<String, dynamic> getNotificationStats() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final last7Days = now.subtract(const Duration(days: 7));

    final last24HourNotifications = _notificationHistory
        .where((n) => n.timestamp.isAfter(last24Hours))
        .length;

    final last7DayNotifications = _notificationHistory
        .where((n) => n.timestamp.isAfter(last7Days))
        .length;

    final typeCounts = <NotificationType, int>{};
    for (final notification in _notificationHistory) {
      typeCounts[notification.type] = (typeCounts[notification.type] ?? 0) + 1;
    }

    return {
      'totalNotifications': _notificationHistory.length,
      'last24Hours': last24HourNotifications,
      'last7Days': last7DayNotifications,
      'typeCounts': typeCounts.map((k, v) => MapEntry(k.name, v)),
      'fcmToken': _fcmToken,
      'preferencesEnabled': _preferences.electionReminders ||
          _preferences.votingDayAlerts ||
          _preferences.resultUpdates ||
          _preferences.applicationStatusUpdates ||
          _preferences.generalInfo ||
          _preferences.emergencyAlerts,
    };
  }

  void clearNotificationHistory() {
    _notificationHistory.clear();
  }
}

// Notification provider for Riverpod
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Notification preferences provider
final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
        NotificationPreferencesNotifier.new);

class NotificationPreferencesNotifier
    extends Notifier<NotificationPreferences> {
  late final NotificationService _notificationService;

  @override
  NotificationPreferences build() {
    _notificationService = ref.read(notificationServiceProvider);
    return _notificationService.preferences;
  }

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    state = preferences;
    await _notificationService.updatePreferences(preferences);
  }
}
