import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/primary_button.dart';

class CompletedScreen extends ConsumerWidget {
  const CompletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
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
              PrimaryButton(
                label: 'Explore Results & Insights 🌍',
                onPressed: () => context.push(AppRoutes.globalInsights),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrophyAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 3),
        ),
        child: const Center(
          child: Text('🏆', style: TextStyle(fontSize: 56)),
        ),
      ),
    );
  }

  Widget _buildCelebrationText() {
    return Column(
      children: const [
        Text(
          'You Voted! 🎉',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
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
    return Container(
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 4),
                Text(
                  'That mark on your finger is a badge of honor. Wear it proudly.',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
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
            _ShareChip(label: '🐦 Twitter', color: const Color(0xFF1DA1F2)),
            const SizedBox(width: 12),
            _ShareChip(label: '📸 Instagram', color: const Color(0xFFE1306C)),
            const SizedBox(width: 12),
            _ShareChip(label: '📱 WhatsApp', color: const Color(0xFF25D366)),
          ],
        ),
      ],
    );
  }
}

class _ShareChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ShareChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12)),
      ),
    );
  }
}
