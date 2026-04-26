import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'assistant/screens/election_assistant_screen.dart';

import '../core/theme/colors.dart';
import '../providers/user_provider.dart';
import '../core/routing/screen_registry.dart';
import '../shared/components/loaders.dart';

class AssistantShell extends ConsumerStatefulWidget {
  const AssistantShell({super.key});

  @override
  ConsumerState<AssistantShell> createState() => _AssistantShellState();
}

class _AssistantShellState extends ConsumerState<AssistantShell> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: userAsync.when(
        // Show a brief loader only when we're fetching state for a
        // returning authenticated user. New users never see this because
        // _initializeUser() sets state to START immediately.
        loading: () => const Center(child: AppLoader()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error: $e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(userProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (user) => KeyedSubtree(
          key: ValueKey(user.currentScreen),
          child: ScreenRegistry.resolve(user.currentScreen),
        ),
      ),
      // Only show the AI FAB once the user is past onboarding
      floatingActionButton: _shouldShowFab(userAsync)
          ? Semantics(
              button: true,
              label: 'Open Election AI Assistant chat',
              hint: 'Ask questions about voting, your booth, or your rights',
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ElectionAssistantScreen()),
                  );
                },
                label: const Text('Ask AI Assistant'),
                icon: const Icon(Icons.chat_bubble_outline),
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
              ),
            )
          : null,
    );
  }

  bool _shouldShowFab(AsyncValue userAsync) {
    final screen = userAsync.value?.currentScreen;
    // Don't show FAB on onboarding — it's distracting before the user starts
    return screen != null && screen != 'onboarding';
  }
}
