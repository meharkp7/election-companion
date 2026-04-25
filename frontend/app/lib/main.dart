import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // ── Firebase core ────────────────────────────────────────────────────
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ── Firebase App Check ───────────────────────────────────────────────
    await FirebaseAppCheck.instance.activate(
      webProvider:
          ReCaptchaEnterpriseProvider('YOUR_RECAPTCHA_ENTERPRISE_SITE_KEY'),
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );

    // ── Firebase Analytics ───────────────────────────────────────────────
    final analytics = FirebaseAnalytics.instance;
    await analytics.setAnalyticsCollectionEnabled(!kDebugMode);

    // ── Firebase Crashlytics (not supported on web) ──────────────────────
    if (!kIsWeb) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
    }

    // ── Firebase Performance (not supported on web) ──────────────────────
    if (!kIsWeb) {
      await FirebasePerformance.instance
          .setPerformanceCollectionEnabled(!kDebugMode);
    }

    // ── Firebase Remote Config ───────────────────────────────────────────
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval:
          kDebugMode ? Duration.zero : const Duration(hours: 1),
    ));
    await remoteConfig.setDefaults({
      'election_mode_enabled': false,
      'ai_assistant_enabled': true,
      'booth_intelligence_enabled': true,
      'max_candidates_shown': 10,
      'app_maintenance_mode': false,
      'feature_social_enabled': true,
      'feature_results_enabled': true,
    });
    remoteConfig.fetchAndActivate(); // fire-and-forget

    runApp(const App());
  }, (error, stack) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else {
      // ignore: avoid_print
      print('Error: $error\n$stack');
    }
  });
}
