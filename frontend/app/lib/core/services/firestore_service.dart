import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firestore service for real-time data that doesn't go through the REST backend:
/// - FCM token sync (so backend can send push notifications)
/// - User preferences (dark mode, language, etc.)
/// - Live booth crowd-source updates
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── FCM token ──────────────────────────────────────────────────────────

  /// Store the FCM token so the backend can send push notifications.
  Future<void> saveFcmToken(String token) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.name,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Firestore saveFcmToken error: $e');
    }
  }

  // ── User preferences ───────────────────────────────────────────────────

  /// Save user preferences to Firestore (synced across devices).
  Future<void> savePreferences(Map<String, dynamic> prefs) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('user_preferences').doc(uid).set(
        {...prefs, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Firestore savePreferences error: $e');
    }
  }

  /// Stream user preferences for real-time updates.
  Stream<Map<String, dynamic>> preferencesStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('user_preferences')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.data() ?? {});
  }

  // ── Booth crowd-source ─────────────────────────────────────────────────

  /// Submit a real-time booth status report.
  Future<void> submitBoothReport({
    required String boothId,
    required Map<String, dynamic> report,
  }) async {
    try {
      await _db.collection('booth_reports').add({
        ...report,
        'boothId': boothId,
        'reportedBy': _uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Firestore submitBoothReport error: $e');
    }
  }

  /// Stream live booth reports for a given booth.
  Stream<List<Map<String, dynamic>>> boothReportsStream(String boothId) {
    return _db
        .collection('booth_reports')
        .where('boothId', isEqualTo: boothId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => d.data()).toList());
  }

  // ── Election live updates ──────────────────────────────────────────────

  /// Stream live election result updates for a constituency.
  Stream<Map<String, dynamic>> electionResultsStream(String constituency) {
    return _db
        .collection('election_results')
        .doc(constituency)
        .snapshots()
        .map((snap) => snap.data() ?? {});
  }
}

// Riverpod provider
final firestoreServiceProvider = Provider<FirestoreService>(
  (_) => FirestoreService.instance,
);
