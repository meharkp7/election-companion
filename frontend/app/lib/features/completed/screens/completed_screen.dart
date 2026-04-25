import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/primary_button.dart';

class CompletedScreen extends ConsumerWidget {
  const CompletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      // Announce screen name to screen readers on navigation
      body: Semantics(
        scopesRoute: true,
        namesRoute: true,
        label: 'Voting completed screen',
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              _buildTrophyAnimation(),
              const SizedBox(height: 32),
              _buildCelebrationText(),
              const SizedBox(height: 32),
              _buildInkMarkCard(),
              const SizedBox(height: 32),
              _buildShareSection(),
              const SizedBox(height: 40),
              Semantics(
                button: true,
                label: 'Explore election results and global insights',
                child: PrimaryButton(
                  label: 'Explore Results & Insights 🌍',
                  onPressed: () => context.push(AppRoutes.globalInsights),
                ),
              ),
            ],
          ),
        ),
      ),
      ), // Semantics scopesRoute
    );
  }

  Widget _buildTrophyAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      // Trophy is decorative — the heading below carries the meaning
      child: ExcludeSemantics(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 3),
          ),
          child: const Center(
            child: Text('🏆', style: TextStyle(fontSize: 56)),
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationText() {
    return Column(
      children: [
        // Announce as heading so screen readers jump here first
        Semantics(
          header: true,
          liveRegion: true,
          label: 'You have successfully voted. Congratulations!',
          child: const Text(
            'You Voted! 🎉',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Thank you for participating in democracy.\nYour vote matters.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInkMarkCard() {
    return Semantics(
      label:
          'Ink Mark of Democracy. That mark on your finger is a badge of honor. Wear it proudly.',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Text('🖊️', style: TextStyle(fontSize: 32)),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ink Mark of Democracy',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'That mark on your finger is a badge of honor. Wear it proudly.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareSection() {
    return Column(
      children: [
        const Text(
          'Share your voting experience',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ShareChip(
                label: '🐦 Twitter',
                semanticLabel: 'Share on Twitter',
                color: const Color(0xFF1DA1F2),
                onTap: () => _share('twitter')),
            const SizedBox(width: 12),
            _ShareChip(
                label: '📸 Instagram',
                semanticLabel: 'Share on Instagram',
                color: const Color(0xFFE1306C),
                onTap: () => _share('instagram')),
            const SizedBox(width: 12),
            _ShareChip(
                label: '📱 WhatsApp',
                semanticLabel: 'Share on WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _share('whatsapp')),
          ],
        ),
      ],
    );
  }

  static Future<void> _share(String platform) async {
    const text =
        'I voted today! 🇮🇳 Exercise your democratic right. Every vote counts! #IVoted #IndiaVotes';
    final encoded = Uri.encodeComponent(text);
    final Uri uri;
    switch (platform) {
      case 'twitter':
        uri = Uri.parse('https://twitter.com/intent/tweet?text=$encoded');
        break;
      case 'whatsapp':
        uri = Uri.parse('https://wa.me/?text=$encoded');
        break;
      case 'instagram':
        // Instagram doesn't support pre-filled text; open the app instead.
        uri = Uri.parse('https://www.instagram.com/');
        break;
      default:
        return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ShareChip extends StatelessWidget {
  final String label;
  final String semanticLabel;
  final Color color;
  final VoidCallback onTap;

  const _ShareChip({
    required this.label,
    required this.semanticLabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        // Min 48dp touch target per WCAG
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}