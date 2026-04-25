import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Firebase Storage service for secure document uploads.
///
/// Storage structure:
///   users/{uid}/documents/{documentType}/{filename}
///   users/{uid}/profile/{filename}
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  // ── Document upload ────────────────────────────────────────────────────

  /// Upload a government ID document and return its download URL.
  ///
  /// [file]         — local file to upload
  /// [documentType] — 'aadhaar', 'voter_id', 'passport', 'dl'
  /// [onProgress]   — optional callback with upload progress 0.0–1.0
  Future<String> uploadDocument(
    File file,
    String documentType, {
    void Function(double)? onProgress,
  }) async {
    final filename = '${documentType}_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
    final ref = _storage.ref('users/$_uid/documents/$documentType/$filename');

    final task = ref.putFile(
      file,
      SettableMetadata(
        contentType: _contentType(file.path),
        customMetadata: {
          'uploadedBy': _uid,
          'documentType': documentType,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      ),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((snapshot) {
        final progress =
            snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    await task;
    return ref.getDownloadURL();
  }

  /// Upload a profile photo and return its download URL.
  Future<String> uploadProfilePhoto(File file) async {
    final ext = p.extension(file.path);
    final ref = _storage.ref('users/$_uid/profile/avatar$ext');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  // ── Delete ─────────────────────────────────────────────────────────────

  /// Delete a document by its download URL.
  Future<void> deleteByUrl(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      if (kDebugMode) debugPrint('Storage delete error: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String _contentType(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
