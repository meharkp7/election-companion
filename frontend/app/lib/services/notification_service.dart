import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _notificationsKey = 'notifications_enabled';
  static const String _reminderTimeKey = 'reminder_time';
  static const String _electionAlertsKey = 'election_alerts';

  static Future<void> enableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, true);
  }

  static Future<void> disableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, false);
  }

  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true; // Default to enabled
  }

  static Future<void> setReminderTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reminderTimeKey, time);
  }

  static Future<String?> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_reminderTimeKey);
  }

  static Future<void> enableElectionAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_electionAlertsKey, true);
  }

  static Future<void> disableElectionAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_electionAlertsKey, false);
  }

  static Future<bool> areElectionAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_electionAlertsKey) ?? true; // Default to enabled
  }

  static Future<void> scheduleElectionReminder(DateTime electionDate) async {
    // Mock notification scheduling - in real app, this would use flutter_local_notifications
    // For now, we'll just save the reminder info
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_election_reminder', electionDate.toString());
  }

  static Future<void> scheduleVotingDayReminder(DateTime votingDate) async {
    // Mock notification scheduling - in real app, this would use flutter_local_notifications
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_voting_reminder', votingDate.toString());
  }

  static Future<void> sendTestNotification() async {
    // Mock notification - in real app, this would show an actual notification
    debugPrint('Test notification: VoteReady - Your election companion is ready!');
  }

  static Future<void> sendElectionUpdateNotification(String message) async {
    // Mock notification - in real app, this would show an actual notification
    debugPrint('Election Update: $message');
  }

  static Future<void> sendVotingReminderNotification() async {
    // Mock notification - in real app, this would show an actual notification
    debugPrint('Voting Reminder: Don\'t forget to vote today!');
  }

  static Future<void> sendResultNotification(String message) async {
    // Mock notification - in real app, this would show an actual notification
    debugPrint('Election Results: $message');
  }
}