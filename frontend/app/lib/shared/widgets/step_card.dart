import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class StepOptionCard extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isDashed;
  final Color? accentColor;

  const StepOptionCard({
    super.key,
    required this.label,
    this.subtitle,
    this.icon,
    this.onTap,
    this.isDashed = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.orange;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDashed ? AppColors.border : color.withValues(alpha: .2),
            width: isDashed ? 0.5 : 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDashed ? AppColors.ink3 : color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDashed ? AppColors.ink3 : AppColors.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (icon != null)
              Icon(icon, size: 18, color: isDashed ? AppColors.ink3 : color),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color bgColor;
  final Color borderColor;
  final Widget? trailing;
  final Widget? child;
  final EdgeInsets? padding;

  const InfoCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.bgColor,
    required this.borderColor,
    this.trailing,
    this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (child != null) ...[const SizedBox(height: 12), child!],
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w500,
          color: AppColors.ink3,
        ),
      ),
    );
  }
}
