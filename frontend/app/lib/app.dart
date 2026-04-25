import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'VoteReady',

        // ── Accessibility: high-contrast themes ──────────────────────────
        theme: AppTheme.light,
        highContrastTheme: AppTheme.lightHighContrast,
        highContrastDarkTheme: AppTheme.darkHighContrast,

        // ── Accessibility: localisation delegates needed by screen readers
        // (TalkBack / VoiceOver rely on these for date pickers, alerts, etc.)
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'IN'), // primary
          Locale('hi', 'IN'), // Hindi
        ],

        // ── Accessibility: honour OS-level font-size preference ──────────
        // Clamp between 1.0× and 1.4× so large-text users can read
        // everything without the layout completely breaking.
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final clampedScaler = mediaQuery.textScaler.clamp(
            minScaleFactor: 1.0,
            maxScaleFactor: 1.4,
          );
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: clampedScaler),
            child: child!,
          );
        },

        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        showSemanticsDebugger: false, // flip to true during a11y QA
      ),
    );
  }
}
