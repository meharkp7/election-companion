import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'VoteReady',
        theme: AppTheme.light,
        highContrastTheme: AppTheme.lightHighContrast,
        highContrastDarkTheme: AppTheme.darkHighContrast,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        showSemanticsDebugger: false,
      ),
    );
  }
}
