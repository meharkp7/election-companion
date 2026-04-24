import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';

/// Government-grade verification options screen
/// Provides multiple verification paths for government app compliance
class VerificationOptionsScreen extends ConsumerWidget {
  const VerificationOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Verify Your Identity'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Choose Verification Method',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select how you want to verify your voter identity. All methods are secure and government-approved.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.ink.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),

              // Recommended: Aadhaar E-KYC
              _VerificationOptionCard(
                icon: Icons.verified_user,
                title: 'Aadhaar e-KYC',
                subtitle: 'Fastest & most secure',
                description:
                    'Verify instantly using your Aadhaar number and OTP. Data directly from UIDAI.',
                badge: 'RECOMMENDED',
                badgeColor: AppColors.green,
                onTap: () => Navigator.pushNamed(context, '/verify-aadhaar'),
              ),
              const SizedBox(height: 16),

              // Voter ID (EPIC)
              _VerificationOptionCard(
                icon: Icons.how_to_vote,
                title: 'Voter ID (EPIC)',
                subtitle: 'Using your voter card',
                description:
                    'Enter your EPIC number and upload your voter ID card for verification.',
                onTap: () => Navigator.pushNamed(context, '/verify-epic'),
              ),
              const SizedBox(height: 16),

              // Document Upload (Basic)
              _VerificationOptionCard(
                icon: Icons.upload_file,
                title: 'Upload Documents',
                subtitle: 'Alternative verification',
                description:
                    'Upload any government ID (Aadhaar, Passport, Driving License, PAN).',
                onTap: () => Navigator.pushNamed(context, '/verify-document'),
              ),
              const SizedBox(height: 32),

              // Security note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: AppColors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your data is encrypted and secure. We only use government-approved verification methods.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _VerificationOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    this.badge,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badge != null
                ? (badgeColor ?? AppColors.orange).withOpacity(0.3)
                : AppColors.border,
            width: badge != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.orangeLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.ink.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? AppColors.orange)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor ?? AppColors.orange,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.ink.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  color: AppColors.orange,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
